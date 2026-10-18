extends SceneTree
## Checks the tower can always be climbed, with no spots where you get stuck.
##   1. Every layout, stacked on itself, on both normal and trap floors.
##   2. Several random towers, cut off past the second trap floor, can be
##      climbed (upward-only search, which is fast enough for tall towers).
##   3. Trap floors follow their rules and are only decided as floors load.
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
		tower.force_trap_every = 2    # floors 2 and 4 are trap floors, 3 is normal
		_check(tower, "layout %d" % i, 4)
	print("checked %d layouts" % Rooms.LAYOUTS.size())

	for seed_value in SEEDS:
		var tower = TowerScript.new()
		tower.build(Rooms.START, Rooms.LAYOUTS, seed_value)
		tower.room_limit = HEIGHT
		var swipes := _check(tower, "seed %d" % seed_value, HEIGHT, true)
		print("seed %d: %d swipes to floor %d" % [seed_value, swipes, HEIGHT])

	_check_traps()

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


func _check_traps() -> void:
	var tower = TowerScript.new()
	tower.build(Rooms.START, Rooms.LAYOUTS, 1)
	if tower.loaded_count() != 1:
		printerr("FAIL: a new tower should load only its first floor, loaded %d" % tower.loaded_count())
		failures += 1
	tower.is_trap(9)
	if tower.loaded_count() != 10:
		printerr("FAIL: checking floor 10 should load exactly 10 floors, loaded %d" % tower.loaded_count())
		failures += 1

	var floors := 0
	var traps := 0
	var after_trap := 0
	var back_to_back := 0
	for seed_value in 300:
		tower = TowerScript.new()
		tower.build(Rooms.START, Rooms.LAYOUTS, seed_value)
		for k in 300:
			var f := k + 1
			var trap: bool = tower.is_trap(k)
			if f <= TowerScript.SAFE_FLOORS and trap:
				printerr("FAIL: seed %d: floor %d is a trap floor" % [seed_value, f])
				failures += 1
			if f % TowerScript.TRAP_EVERY == 0 and not trap:
				printerr("FAIL: seed %d: floor %d should always be a trap floor" % [seed_value, f])
				failures += 1
			if f <= TowerScript.SAFE_FLOORS or f % TowerScript.TRAP_EVERY == 0:
				continue
			if tower.is_trap(k - 1):
				after_trap += 1
				if trap:
					back_to_back += 1
			else:
				floors += 1
				if trap:
					traps += 1
	var rate := traps * 100.0 / floors
	var again := back_to_back * 100.0 / maxi(after_trap, 1)
	print("random trap floors: %.1f%% normally, %.1f%% right after a trap floor" % [rate, again])
	if absf(rate - TowerScript.TRAP_CHANCE * 100) > 1.0:
		printerr("FAIL: trap chance is %.1f%%, want %.1f%%" % [rate, TowerScript.TRAP_CHANCE * 100])
		failures += 1
	if again > TowerScript.TRAP_AGAIN_CHANCE * 100 + 1.0:
		printerr("FAIL: back-to-back trap chance is %.1f%%, want about %.1f%%" % [again, TowerScript.TRAP_AGAIN_CHANCE * 100])
		failures += 1
