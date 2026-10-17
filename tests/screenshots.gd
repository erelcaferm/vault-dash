extends SceneTree
## Saves a few screenshots of the game for review (needs a display, e.g. xvfb-run).
## Run: godot --path . --script res://tests/screenshots.gd -- <output dir>

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://tests/solver.gd")

var game
var route: Array = []
var frames := 0
var out_dir := "user://"
var shots := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	var tower = TowerScript.new()
	tower.build(Rooms.ROOMS, 7)
	tower.room_limit = 20
	var solver = Solver.new(tower)
	solver.run()
	route = solver.solution.duplicate()
	game = load("res://scenes/main.tscn").instantiate()
	game.test_seed = 7
	game.test_room_limit = 20
	root.add_child(game)


func _shot(name: String) -> void:
	if shots.has(name):
		return
	shots[name] = true
	root.get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 20:
		_shot("1_title")
	elif frames > 20 and game.state != game.State.DEAD:
		if game.run_floor >= 8 and not shots.has("2_cracked_walls"):
			if game.is_idle():
				_shot("2_cracked_walls")
			return false
		if game.run_floor >= 13 and game.is_idle() and not shots.has("3_jungle"):
			_shot("3_jungle")
			# Stand still so the lava catches up.
			route.clear()
		if game.is_idle() and not route.is_empty() and frames % 6 == 0:
			game._on_swipe(route.pop_front())
	elif game.state == game.State.DEAD:
		if game.state_time > 0.5:
			_shot("4_death")
			return true
	return frames > 60 * 120
