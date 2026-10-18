extends SceneTree
## Checks the tower can always be climbed, with no spots where you get stuck.
##   1. Every layout, stacked on itself, on both normal and trap floors.
##   2. Several random towers, cut off past the second trap floor, can be
##      climbed (upward-only search, which is fast enough for tall towers).
## Run: godot --headless --path . --script res://tests/test_rooms.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://tests/solver.gd")

const SEEDS := [1, 2, 3, 4, 5, 6]
const HEIGHT := 62

var failures := 0


func _init() -> void:
	for i in Rooms.LAYOUTS.size():
		var tower = TowerScript.new()
		tower.build(Rooms.START, [Rooms.LAYOUTS[i]], i)
		tower.room_limit = 4
		tower.trap_every = 2    # floors 2 and 4 are trap floors, 3 is normal
		_check(tower, "layout %d" % i, 4)
	print("checked %d layouts" % Rooms.LAYOUTS.size())

	for seed_value in SEEDS:
		var tower = TowerScript.new()
		tower.build(Rooms.START, Rooms.LAYOUTS, seed_value)
		tower.room_limit = HEIGHT
		var swipes := _check(tower, "seed %d" % seed_value, HEIGHT, true)
		print("seed %d: %d swipes to floor %d" % [seed_value, swipes, HEIGHT])

	if failures == 0:
		print("PASS: every layout and %d towers of %d floors are climbable" % [SEEDS.size(), HEIGHT])
	quit(1 if failures > 0 else 0)


func _check(tower, label: String, height: int, upward_only := false) -> int:
	var solver = Solver.new(tower)
	solver.upward_only = upward_only
	solver.run()
	if solver.solution.is_empty():
		printerr("FAIL: %s: the top cannot be reached" % label)
		failures += 1
	var reached: Dictionary = solver.rooms_reached()
	for k in height:
		if not reached.has(k):
			printerr("FAIL: %s: floor %d (layout %d) is never reached" % [label, k + 1, tower.def_of(k)])
			failures += 1
	if upward_only:
		return solver.solution.size()
	var reported := {}
	for cell: Vector2i in solver.dead_ends:
		var k: int = tower.room_of(cell.y)
		if not reported.has(k):
			reported[k] = true
			printerr("FAIL: %s: stuck spot on floor %d (layout %d) at column %d" % [
				label, k + 1, tower.def_of(k), cell.x])
			failures += 1
	return solver.solution.size()
