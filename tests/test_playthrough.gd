extends SceneTree
## Plays the real game scene along the solver's route up a fixed 102-floor
## tower and checks it reaches the top. On the way it crosses three trap
## floors and must pick up every chest it passes, which open one by one
## once the run is over. Then it stands still and
## checks the lava wins.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_playthrough.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://scripts/solver.gd")

var game
var route: Array = []
var phase := "escape"
var frames := 0
var chests := 0

const SEED := 42
const HEIGHT := 102


func _initialize() -> void:
	var tower = TowerScript.new()
	tower.build(Rooms.START, Rooms.LAYOUTS, SEED)
	tower.room_limit = HEIGHT
	var solver = Solver.new(tower)
	solver.upward_only = true
	solver.run()
	route = solver.solution.duplicate()
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://test_save.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.test_seed = SEED
	# The route is followed blindly, so no moving blocks or spike traps (test_hazards.gd covers them).
	game.hazards_on = false
	game.test_room_limit = HEIGHT
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if game.state == game.State.CHEST:
		if phase != "chests":
			printerr("FAIL: a chest opened mid-run instead of waiting for the end")
			quit(1)
			return false
		if game.chest_screen.visible and frames % 30 == 0:
			var tap := InputEventMouseButton.new()
			tap.pressed = true
			tap.button_index = MOUSE_BUTTON_LEFT
			game.chest_screen._gui_input(tap)   # first tap skips the spin
			game.chest_screen._gui_input(tap)   # second tap collects
			chests += 1
		return false
	if phase == "escape":
		if game.state == game.State.WON:
			# Every chest on the way, regular or bonus, must have been picked up
			# and saved for the end of the run.
			for k in HEIGHT:
				if game.has_chest(k) and not game.chests_taken.has(k):
					printerr("FAIL: the chest on floor %d was never picked up" % (k + 1))
					quit(1)
					return false
			if game.pending_chests != game.chests_taken.size() or game.pending_chests < floori(float(HEIGHT) / TowerScript.CHEST_EVERY):
				printerr("FAIL: saved %d chests, expected %d" % [game.pending_chests, game.chests_taken.size()])
				quit(1)
				return false
			print("PASS: climbed %d floors in %.1f s of game time with %d coins, saving %d chests" % [
				HEIGHT, game.elapsed, game.run_coins, game.pending_chests])
			phase = "chests"
			frames = 0
		elif game.state == game.State.DEAD:
			printerr("FAIL: died on floor %d following the solver's route" % game.run_floor)
			quit(1)
		elif game.is_idle() and not route.is_empty():
			game._on_swipe(route.pop_front())
		elif frames > 60 * 400:
			printerr("FAIL: did not reach the top in time")
			quit(1)
	elif phase == "chests":
		if game.state == game.State.WON and game.pending_chests == 0 and not game.chest_screen.visible:
			if chests != game.chests_taken.size() or not game.message_label.visible:
				printerr("FAIL: opened %d chests one by one, expected %d, then the win message" % [chests, game.chests_taken.size()])
				quit(1)
				return false
			print("PASS: opened the %d saved chests one after another at the end" % chests)
			game.state_time = 1.0
			game.test_room_limit = -1
			game._on_tap()
			game._on_swipe(Vector2i.LEFT)
			phase = "lava"
			frames = 0
		elif frames > 60 * 60:
			printerr("FAIL: the saved chests never finished opening")
			quit(1)
	elif phase == "lava":
		if game.state == game.State.DEAD:
			print("PASS: lava caught an idle player after %.1f s" % game.elapsed)
			quit(0)
		elif frames > 60 * 60:
			printerr("FAIL: lava never reached the idle player")
			quit(1)
	return false
