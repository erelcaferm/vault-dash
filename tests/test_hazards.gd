extends SceneTree
## Checks moving blocks and spike traps: where they appear, that blocks stay
## in their room and off walls, never step onto a player standing still,
## keep moving, and that traps are only on tiles you slide through.
## Run: godot --headless --path . --script res://tests/test_hazards.gd

const TowerScript := preload("res://scripts/tower.gd")
const Hazards := preload("res://scripts/hazards.gd")
const SAVE := "user://test_hazards_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_seed = 11
	root.add_child(game)
	await process_frame

	var hz = game.hazards
	hz.roll(150)
	var mover_floors := {}
	for m in hz.movers:
		mover_floors[m.room] = true
		_expect(m.room + 1 >= Hazards.MOVER_FROM_FLOOR, "no blocks on the first floors")
		_expect(not game.has_chest(m.room), "no blocks on chest floors")
	_expect(mover_floors.size() > 20 and mover_floors.size() < 75, "blocks on a fair share of floors (got %d of 142)" % mover_floors.size())
	var trap_floors := {}
	for c: Vector2i in hz.traps:
		trap_floors[game.tower.room_of(c.y)] = true
		_expect(game.tower.room_of(c.y) + 1 >= Hazards.TRAP_FROM_FLOOR, "no traps on the first floors")
		_expect(hz._pass_through(c), "traps only where you can't stop")
	_expect(trap_floors.size() > 15, "traps on some floors (got %d)" % trap_floors.size())

	# Blocks wander for a while: they stay in their room, off walls, and move.
	var visited := {}
	for i in 2000:
		hz.update(0.05, Vector2i(-1, -1), 0)
		for j in hz.movers.size():
			var m: Dictionary = hz.movers[j]
			var at := Vector2i(roundi(m.pos.x), roundi(m.pos.y))
			_expect_quiet(game.tower.room_of(at.y) == m.room, "a block left its room")
			var t: String = game.tower.get_tile(at)
			_expect_quiet(t != TowerScript.WALL and t != TowerScript.CRACKED, "a block went into a wall")
			if not visited.has(j):
				visited[j] = {}
			visited[j][m.cell] = true
	var stuck := 0
	for m in visited:
		if visited[m].size() < 3:
			stuck += 1
	_expect(stuck == 0, "every block keeps moving (%d stuck)" % stuck)

	# Standing still is always safe: blocks never step onto your tile.
	var hits := 0
	for m in hz.movers.slice(0, 15):
		var rest: Vector2i = m.next + m.dir
		if not hz._path(m.room).has(rest) or not hz._path(m.room).has(m.next):
			continue
		for i in 600:
			hz.update(0.05, rest, 0)
			if hz.mover_hits(Vector2(rest)) and m.pos.distance_to(Vector2(rest)) < 0.3:
				hits += 1
				break
	_expect(hits == 0, "blocks never walk onto a player standing still (%d did)" % hits)

	# A trap kills only while it's up.
	var trap: Vector2i = hz.traps.keys()[0]
	hz.time = 0.0
	var states := {}
	for i in 60:
		hz.time += Hazards.TRAP_CYCLE / 60.0
		states[hz.trap_state(trap)] = true
	_expect(states.size() == 3, "traps go down, warn and up")

	# A block touching you ends the run (in the real game loop).
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.move_dir = Vector2i.ZERO
	game.queued_dir = Vector2i.ZERO
	game.hazards.movers.append({"room": 0, "cell": game.cell, "next": game.cell, "pos": Vector2(game.cell), "dir": Vector2i.LEFT})
	await process_frame
	await process_frame
	_expect(game.state == game.State.DEAD and game.stat("deaths_mover") == 1, "touching a block kills you")

	# None in the Daily Climb or levels.
	game.daily_mode = true
	game.reset()
	game.hazards.roll(150)
	_expect(game.hazards.movers.is_empty() and game.hazards.traps.is_empty(), "no hazards in the Daily Climb")
	game.daily_mode = false

	# Levels can have their own blocks (M) and traps (T).
	var Levels = load("res://scripts/levels.gd")
	var LevelCode = load("res://scripts/level_code.gd")
	game.start_campaign_level(26)
	_expect(game.hazards.movers.size() == 2 and game.hazards.traps.size() == 2, "Rush Hour has 2 blocks and 2 traps")
	_expect(game.tower.get_tile(game.tower.movers_at[0]) == TowerScript.EMPTY, "a block's start is floor underneath")
	var code: String = LevelCode.encode(Levels.level(26))
	_expect(LevelCode.decode(code).rows == Levels.level(26).rows, "share codes keep blocks and traps")
	var bad: Dictionary = LevelCode.blank("t")
	bad.rows[1] = bad.rows[1].substr(0, 1) + "T" + bad.rows[1].substr(2)
	_expect(LevelCode.problem(bad) == "Spike traps need open floor all round", "a trap beside a wall is refused")
	game.level = {}

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures == 0:
		print("PASS: moving blocks and spike traps are fair")
	quit(1 if failures > 0 else 0)


var _quiet := {}

func _expect_quiet(ok: bool, what: String) -> void:
	if not ok and not _quiet.has(what):
		_quiet[what] = true
		_expect(false, what)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
