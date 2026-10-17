extends SceneTree
## Builds endless towers from several seeds, cut off at a fixed height, and
## checks each one can be climbed with no spots where you get stuck.
## Run: godot --headless --path . --script res://tests/test_rooms.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://tests/solver.gd")

const SEEDS := [1, 2, 3, 4, 5, 6, 7, 8]
const HEIGHT := 40


func _init() -> void:
	var failures := 0
	var used := {}
	for seed_value in SEEDS:
		var tower = TowerScript.new()
		tower.build(Rooms.ROOMS, seed_value)
		tower.room_limit = HEIGHT
		var solver = Solver.new(tower)
		solver.run()
		for k in HEIGHT:
			used[tower.def_of(k)] = true

		if solver.solution.is_empty():
			printerr("FAIL: seed %d: floor %d cannot be reached" % [seed_value, HEIGHT])
			failures += 1
		var reached: Dictionary = solver.rooms_reached()
		for k in HEIGHT:
			if not reached.has(k):
				printerr("FAIL: seed %d: floor %d (room %d) is never reached" % [seed_value, k + 1, tower.def_of(k)])
				failures += 1
		var reported := {}
		for cell: Vector2i in solver.dead_ends:
			var k: int = tower.room_of(cell.y)
			if reported.has(k):
				continue
			reported[k] = true
			printerr("FAIL: seed %d: stuck spot on floor %d (room %d) at column %d" % [
				seed_value, k + 1, tower.def_of(k), cell.x])
			failures += 1
		print("seed %d: %d swipes to floor %d, %d stop positions" % [
			seed_value, solver.solution.size(), HEIGHT, solver.states.size()])

	for i in Rooms.ROOMS.size():
		if not used.has(i):
			printerr("FAIL: room %d never came up, so it is untested" % i)
			failures += 1
	if failures == 0:
		print("PASS: %d towers of %d floors are all climbable" % [SEEDS.size(), HEIGHT])
	quit(1 if failures > 0 else 0)
