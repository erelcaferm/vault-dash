extends SceneTree
## Plays the real game scene along the solver's route up a fixed 102-floor
## tower and checks it reaches the top. On the way it crosses three trap
## floors and must open every chest it passes. Then it stands still and
## checks the lava wins.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_playthrough.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://tests/solver.gd")

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
	game.test_room_limit = HEIGHT
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if phase == "escape":
		if game.state == game.State.CHEST:
			if game.chest_screen.visible and frames % 30 == 0:
				var tap := InputEventMouseButton.new()
				tap.pressed = true
				tap.button_index = MOUSE_BUTTON_LEFT
				game.chest_screen._gui_input(tap)   # first tap skips the spin
				game.chest_screen._gui_input(tap)   # second tap collects
				chests += 1
		elif game.state == game.State.WON:
			# Every chest on the way, regular or bonus, must have been opened.
			for k in HEIGHT:
				if game.has_chest(k) and not game.chests_taken.has(k):
					printerr("FAIL: the chest on floor %d was never opened" % (k + 1))
					quit(1)
					return false
			if chests != game.chests_taken.size() or chests < floori(float(HEIGHT) / TowerScript.CHEST_EVERY):
				printerr("FAIL: opened %d chests, expected %d" % [chests, game.chests_taken.size()])
				quit(1)
				return false
			print("PASS: climbed %d floors in %.1f s of game time with %d coins, opening %d chests" % [
				HEIGHT, game.elapsed, game.run_coins, chests])
			game.state_time = 1.0
			game.test_room_limit = -1
			game._on_tap()
			game._on_swipe(Vector2i.LEFT)
			phase = "lava"
			frames = 0
		elif game.state == game.State.DEAD:
			printerr("FAIL: died on floor %d following the solver's route" % game.run_floor)
			quit(1)
		elif game.is_idle() and not route.is_empty():
			game._on_swipe(route.pop_front())
		elif frames > 60 * 400:
			printerr("FAIL: did not reach the top in time")
			quit(1)
	elif phase == "lava":
		if game.state == game.State.DEAD:
			print("PASS: lava caught an idle player after %.1f s" % game.elapsed)
			quit(0)
		elif frames > 60 * 60:
			printerr("FAIL: lava never reached the idle player")
			quit(1)
	return false
