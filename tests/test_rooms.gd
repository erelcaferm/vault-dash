extends SceneTree
## Checks the tower is escapable and has no spots where you get stuck.
## Run: godot --headless --path . --script res://tests/test_rooms.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://tests/solver.gd")


func _init() -> void:
	var tower = TowerScript.new()
	tower.build(Rooms.ROOMS)
	var solver = Solver.new(tower)
	solver.run()

	var failures := 0
	if solver.solution.is_empty():
		printerr("FAIL: the exit cannot be reached")
		failures += 1
	else:
		print("Shortest escape: %d swipes" % solver.solution.size())

	var reached: Dictionary = solver.rooms_reached()
	for i in tower.room_count:
		if not reached.has(i):
			printerr("FAIL: room %d is never reached" % i)
			failures += 1

	for cell: Vector2i in solver.dead_ends:
		printerr("FAIL: stuck spot in room %d at column %d, row %d" % [
			tower.room_of(cell.y), cell.x, cell.y % tower.ROOM_H])
		failures += 1

	print("%d stop positions explored" % solver.states.size())
	if failures == 0:
		print("PASS: all %d rooms are solvable" % tower.room_count)
	quit(1 if failures > 0 else 0)
