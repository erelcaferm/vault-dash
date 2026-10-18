extends SceneTree
## Plays several days of the Daily Climb as simulated players of different
## skill, to check the climb is fair and the medal times fit real players.
## Each player follows the best route; skill is how long they stop to think
## before each swipe, plus the odd longer pause. Slower players found two
## problems this test now guards: the lava caught anyone slower than an
## expert, and routes that drop down a room slid into lava that sat close
## behind (hence the daily's gentler DAILY_LAVA_* settings).
## Run: godot --headless --path . --script res://tests/test_daily_skill.gd

const Solver := preload("res://scripts/solver.gd")
const SAVE := "user://test_daily_skill_save.cfg"
const DATES := ["2026-10-18", "2026-10-19", "2026-11-02", "2027-03-14"]
## [name, seconds of thought before each swipe, chance of a hesitation, its length]
const SKILLS := [
	["expert", 0.25, 0.0, 0.0],
	["good", 0.5, 0.1, 1.0],
	["casual", 0.85, 0.15, 1.5],
	["beginner", 1.3, 0.25, 2.0],
]
const DT := 1.0 / 30.0

var failures := 0
var verbose := false



func _initialize() -> void:
	verbose = OS.get_cmdline_user_args().has("verbose")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame
	var medal_counts := {}
	for date in DATES:
		game.test_today = date
		game.daily_mode = true
		game.reset()
		var solver = Solver.new(game.tower)
		solver.upward_only = true
		solver.run()
		_expect(not solver.solution.is_empty(), "%s: the daily can be finished" % date)
		var route: Array = solver.solution.duplicate()
		var line := "%s  %d moves  medals %s" % [date, route.size(), str(game.medal_times())]
		for skill in SKILLS:
			var result := _play(game, route, skill)
			var medal: String = game.medal_for(result.time) if result.won else "-"
			medal_counts[skill[0] + ":" + medal] = medal_counts.get(skill[0] + ":" + medal, 0) + 1
			line += "  |  %s %s %s" % [skill[0], ("%.1fs" % result.time) if result.won else "died on %d" % result.floor, medal]
			if skill[0] == "expert":
				_expect(result.won and medal == "gold", "%s: an expert gets gold" % date)
			if skill[0] == "good":
				_expect(result.won and medal in ["gold", "silver"], "%s: a good player gets silver or better" % date)
			if skill[0] == "casual":
				_expect(result.won and medal != "gold", "%s: a casual player finishes without gold" % date)
			if skill[0] == "beginner":
				_expect(result.won and medal == "bronze", "%s: a beginner can still finish for bronze" % date)
		if verbose:
			print(line)
	if verbose:
		print(medal_counts)
	game.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures == 0:
		print("PASS: the daily is finishable at every skill, and medals spread by skill")
	quit(1 if failures > 0 else 0)


func _play(game, route: Array, skill: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	game.reset()
	game.daily_time = 0.0
	game.daily_medal = 0
	var moves := route.duplicate()
	var wait: float = skill[1]
	var t := 0.0
	game._on_swipe(moves.pop_front())
	while t < 600.0:
		t += DT
		game._process(DT)
		if game.state == game.State.WON:
			return {"won": true, "time": game.elapsed, "floor": game.run_floor}
		if game.state == game.State.DEAD:
			if verbose:
				print("  died: ", game.message_label.text.split("\n")[0], " at ", game.cell, " moves left ", moves.size())
			return {"won": false, "time": game.elapsed, "floor": game.run_floor}
		if game.is_idle() and not moves.is_empty():
			wait -= DT
			if wait <= 0.0:
				game._on_swipe(moves.pop_front())
				wait = skill[1]
				if rng.randf() < skill[2]:
					wait += skill[3]
	return {"won": false, "time": t, "floor": game.run_floor}


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
