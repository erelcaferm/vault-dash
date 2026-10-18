extends SceneTree
## Plays the real game scene along the solver's route up a fixed 32-floor
## tower (so it crosses trap floor 30) and checks it reaches the top. Then it
## stands still and checks the lava wins.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_playthrough.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://tests/solver.gd")

var game
var route: Array = []
var phase := "escape"
var frames := 0

const SEED := 42
const HEIGHT := 32


func _initialize() -> void:
	var tower = TowerScript.new()
	tower.build(Rooms.START, Rooms.LAYOUTS, SEED)
	tower.room_limit = HEIGHT
	var solver = Solver.new(tower)
	solver.upward_only = true
	solver.run()
	route = solver.solution.duplicate()
	game = load("res://scenes/main.tscn").instantiate()
	game.test_seed = SEED
	game.test_room_limit = HEIGHT
	root.add_child(game)


func _process(_delta: float) -> bool:
	frames += 1
	if phase == "escape":
		if game.state == game.State.WON:
			print("PASS: climbed %d floors in %.1f s of game time with %d coins" % [HEIGHT, game.elapsed, game.run_coins])
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
		elif frames > 60 * 120:
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
