extends SceneTree
## Checks the handmade levels, level codes, timed play, rewards and the editor.
## Run: godot --headless --path . --script res://tests/test_levels.gd

const Levels := preload("res://scripts/levels.gd")
const LevelCode := preload("res://scripts/level_code.gd")
const LevelGrid := preload("res://scripts/level_grid.gd")
const Solver := preload("res://scripts/solver.gd")
const SAVE := "user://test_levels_save.cfg"

var failures := 0


func _initialize() -> void:
	# Every handmade level is valid, solvable in its listed number of moves,
	# and leaves at least 2.5 seconds per move.
	for i in Levels.LEVELS.size():
		var l: Dictionary = Levels.LEVELS[i]
		_expect(LevelCode.problem(Levels.level(i)) == "", "level %d is valid" % (i + 1))
		var grid := LevelGrid.new()
		grid.load_rows(l.rows)
		var solver := Solver.new(grid)
		solver.run()
		_expect(solver.solution.size() == l.moves, "level %d takes %d moves (found %d)" % [i + 1, l.moves, solver.solution.size()])
		_expect(l.time >= l.moves * 2.5, "level %d gives enough time" % (i + 1))

	# Codes survive a round trip, and broken codes are refused.
	var lv := Levels.level(4)
	lv.name = "Mi nivel 🔥"
	var code := LevelCode.encode(lv)
	var back := LevelCode.decode(code)
	_expect(back.rows == lv.rows and back.time == lv.time and back.name == lv.name, "a code loads back the same level")
	_expect(LevelCode.decode(" " + code.insert(20, "\n") + " ") == back, "spaces and line breaks in a code are ignored")
	_expect(LevelCode.decode(code.left(code.length() - 3)).is_empty(), "a cut-off code is refused")
	var typo := code.substr(0, 10) + ("A" if code[10] != "A" else "B") + code.substr(11)
	_expect(LevelCode.decode(typo).is_empty(), "a mistyped code is refused")
	_expect(LevelCode.decode("hello").is_empty(), "text that isn't a code is refused")
	print("code length: %d" % code.length())

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame

	# Only level 1 is open at first.
	_expect(game.campaign_unlocked(0) and not game.campaign_unlocked(1), "only level 1 starts unlocked")
	# Playing level 1 along the solver's route clears it and pays once.
	var coins: int = game.total_coins
	await _play_campaign(game, 0)
	_expect(game.state == game.State.WON, "following the route clears level 1")
	_expect(game.levels_cleared.has(0) and game.campaign_unlocked(1), "clearing level 1 unlocks level 2")
	_expect(game.total_coins == coins + Levels.LEVELS[0].reward.coins, "level 1 pays its reward")
	_expect(game.level_times.get(0, 0.0) > 0.0, "the best time is kept")
	await _play_campaign(game, 0)
	_expect(game.total_coins == coins + Levels.LEVELS[0].reward.coins, "the reward is paid only once")
	# Level 3 gives a skin.
	game.levels_cleared.append(1)
	await _play_campaign(game, 2)
	_expect(game.owned.has("pathfinder") and game.equipped_hero == "pathfinder", "level 3 gives the Pathfinder hero")

	# No lava in levels, only the clock.
	game.start_campaign_level(1)
	game._on_swipe(Vector2i.DOWN)
	for i in 20:
		await process_frame
	_expect(game.state == game.State.PLAYING, "standing still in a level is safe while there's time")
	game.time_left = 0.05
	game._process(0.1)
	_expect(game.state == game.State.DEAD, "running out of time loses the level")
	game.state_time = 1.0
	game._on_tap()
	_expect(game.state == game.State.READY and game.time_left == Levels.LEVELS[1].time, "a retry restarts the clock")

	# Coins in levels don't go in the wallet.
	var before: int = game.total_coins
	game.level = {}
	var made := LevelCode.blank("Coins")
	made.rows[15] = "#.cccccS....#"
	made.rows[16] = "#...........#"
	game.start_level(made, "custom")
	game._on_swipe(Vector2i.LEFT)
	for i in 30:
		game._process(0.05)
	_expect(game.run_coins == 5 and game.total_coins == before, "level coins are for score only")

	# The editor: paint, test, then share.
	game._leave_level()
	game.levels_screen.visible = false
	var editor = game.level_editor
	editor.open(LevelCode.blank("Mine"), -1)
	_expect(editor.solve() > 0, "a blank level can be solved")
	editor._pick_tool("#")
	for x in range(1, 12):
		editor.paint(Vector2i(x, 8))
	_expect(editor.solve() == 0, "a level walled off from its exit can't be tested")
	editor._test()
	_expect(not game.is_level(), "an impossible level doesn't start")
	editor._pick_tool(".")
	editor.paint(Vector2i(6, 8))
	editor._pick_tool("S")
	editor.paint(Vector2i(6, 15))
	_expect(LevelCode.problem(editor.level) == "" and editor.level.rows[16].count("S") == 0, "placing the start moves it")
	editor._share()
	_expect(not game.levels_screen.visible, "an untested level can't be shared")
	editor._test()
	_expect(game.is_level() and game.level_source == "test", "TEST plays the level")
	game.cell = Vector2i(6, -17 + 1)
	game._win()
	_expect(editor.tested and game.custom_levels.size() == 1, "beating it marks it tested and saves it")
	game._leave_level()
	_expect(editor.visible, "EDIT goes back to the editor")
	editor._share()
	_expect(game.levels_screen._code_panel.visible and game.levels_screen._code_edit.text == game.custom_levels[0], "SHARE shows the code")
	_expect(LevelCode.decode(game.custom_levels[0]).name == "Mine", "the shared code is the level")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("PASS: levels, codes, timer, rewards and editor" if failures == 0 else "FAIL: %d level checks" % failures)
	quit(1 if failures else 0)


func _play_campaign(game, i: int) -> void:
	game.start_campaign_level(i)
	var grid := LevelGrid.new()
	grid.load_rows(Levels.LEVELS[i].rows)
	var solver := Solver.new(grid)
	solver.run()
	var route: Array = solver.solution.duplicate()
	for step in 600:
		if game.state == game.State.WON or game.state == game.State.DEAD:
			break
		if game.is_idle() and not route.is_empty():
			game._on_swipe(route.pop_front())
		await process_frame


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
