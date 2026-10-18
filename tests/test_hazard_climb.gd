extends SceneTree
## Shows moving blocks and spike traps never make a floor unbeatable: a
## patient player follows the solver's route up 80 floors with hazards on,
## and before each slide waits until the slide is clear. The lava is kept
## away so only the hazards are being tested. Fails if the player dies or
## has to wait too long for any slide. Then it does the same on every
## campaign level that has blocks or traps, within the level's time.
## Run: godot --headless --fixed-fps 60 --path . --script res://tests/test_hazard_climb.gd

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Solver := preload("res://scripts/solver.gd")
const Levels := preload("res://scripts/levels.gd")
const LevelGrid := preload("res://scripts/level_grid.gd")

const SEED := 9
const HEIGHT := 80
const MAX_WAIT := 15.0           # seconds a slide may have to wait

var game
var route: Array = []
var waited := 0.0
var longest := 0.0
var total_wait := 0.0
var frames := 0
var done := false
var levels: Array = []           # campaign levels with hazards, still to play
var level_now := -1


func _initialize() -> void:
	var tower = TowerScript.new()
	tower.build(Rooms.START, Rooms.LAYOUTS, SEED)
	tower.room_limit = HEIGHT
	var solver = Solver.new(tower)
	solver.upward_only = true
	solver.run()
	route = solver.solution.duplicate()
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://test_hazard_climb_save.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.test_seed = SEED
	game.test_room_limit = HEIGHT
	root.add_child(game)


func _process(delta: float) -> bool:
	if done:
		return true
	frames += 1
	if game.state == game.State.PLAYING and level_now < 0:
		game.lava_y = game._player_center().y + 20 * game.TILE
	if game.state == game.State.WON and level_now < 0:
		print("PASS: climbed %d floors past hazards, waiting %.1f s in all (longest wait %.1f s)" % [HEIGHT, total_wait, longest])
		for i in Levels.LEVELS.size():
			if "M" in "".join(Levels.LEVELS[i].rows) or "T" in "".join(Levels.LEVELS[i].rows):
				levels.append(i)
		_next_level()
		return false
	if game.state == game.State.WON:
		print("PASS: level %d (%s) cleared in %.1f s of %d" % [level_now + 1, Levels.LEVELS[level_now].name, game.elapsed, Levels.LEVELS[level_now].time])
		if levels.is_empty():
			return _finish(0)
		_next_level()
		return false
	if game.state == game.State.DEAD:
		printerr("FAIL: died on floor %d (%s) while waiting for gaps" % [game.run_floor, game.end_message.split("\n")[0]])
		return _finish(1)
	if frames > 60 * 900:
		printerr("FAIL: did not reach the top in time")
		return _finish(1)
	if game.state == game.State.READY:
		game._on_swipe(route[0])
		route.pop_front()
		return false
	if not game.is_idle() or route.is_empty():
		return false
	if _safe(route[0], delta):
		longest = maxf(longest, waited)
		waited = 0.0
		game._on_swipe(route.pop_front())
	else:
		waited += delta
		total_wait += delta
		if waited > MAX_WAIT:
			printerr("FAIL: stuck for %.0f s on floor %d waiting for a clear slide" % [waited, game.run_floor])
			var k: int = game.tower.room_of(game.cell.y)
			printerr("  lasers: %s" % [game.hazards.lasers.filter(func(l): return absi(game.tower.room_of(l.y) - k) <= 1)])
			printerr("  at %s sliding %s; blocks: %s" % [game.cell, route[0], game.hazards.movers.filter(func(m): return absi(m.room - k) <= 1).map(func(m): return [m.room, m.cell, m.dir])])
			for y in range(-(k + 2) * 12, -(k - 1) * 12):
				var row := ""
				for x in 13:
					var c := Vector2i(x, y)
					var ch: String = game.tower.get_tile(c)
					if c == game.cell: ch = "P"
					elif game.hazards.traps.has(c): ch = "T"
					for m in game.hazards.movers:
						if m.cell == c: ch = "M"
					row += ch
				printerr("  %4d %s" % [y, row])
			return _finish(1)
	return false


func _next_level() -> void:
	level_now = levels.pop_front()
	var grid = LevelGrid.new()
	grid.load_rows(Levels.LEVELS[level_now].rows)
	var solver = Solver.new(grid)
	solver.run()
	route = solver.solution.duplicate()
	waited = 0.0
	game.start_campaign_level(level_now)


func _finish(code: int) -> bool:
	done = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	quit(code)
	return true


## Plays the slide forward on a copy of the hazards and checks nothing hits.
func _safe(dir: Vector2i, dt: float) -> bool:
	var hz = game.hazards
	if hz.movers.is_empty() and hz.traps.is_empty() and hz.lasers.is_empty():
		return true
	var start: Vector2i = game.cell
	var t: String = game.tower.get_tile(start + dir)
	if t == TowerScript.CRACKED or t == TowerScript.WALL:
		return true
	var end: Vector2i = game.tower.simulate_slide(start, dir).end
	var length := float((end - start).length())
	var saved: Array = hz.movers.duplicate(true)
	var saved_lasers: Array = hz.lasers.duplicate(true)
	var saved_time: float = hz.time
	var saved_rng: int = hz.rng.state
	var ok := true
	var progress := 0.0
	var entered := 0
	# A little extra on each side, so frame timing can't catch us out.
	for i in 400:
		progress = minf(progress + game.SLIDE_SPEED * dt, length)
		var resting := progress >= length
		# Same order as the game: the slide moves (and checks each tile it
		# enters), then the hazards update and blocks are checked.
		while entered < floori(progress):
			entered += 1
			var c: Vector2i = start + dir * entered
			if hz.trap_state(c) != 0 or _trap_soon(hz, c, dt) or _laser_soon(hz, c, dt):
				ok = false
		hz.update(dt, end if resting else Vector2i(-1, -1), 0)
		var p := Vector2(start) + Vector2(dir) * progress
		for m in hz.movers:
			var d: Vector2 = (m.pos - p).abs()
			if d.x < hz.HIT_SIZE + 0.15 and d.y < hz.HIT_SIZE + 0.15:
				ok = false
		if not ok or (resting and i > 0 and progress >= length and entered >= floori(length)):
			break
	hz.movers = saved
	hz.lasers = saved_lasers
	hz.time = saved_time
	hz.rng.state = saved_rng
	return ok


func _trap_soon(hz, c: Vector2i, dt: float) -> bool:
	var now: float = hz.time
	var up := false
	for k in [-2, -1, 1, 2]:
		hz.time = now + dt * k
		up = up or hz.trap_state(c) != 0
	hz.time = now
	return up


func _laser_soon(hz, c: Vector2i, dt: float) -> bool:
	for l in hz.lasers:
		if not hz._in_beam(l, c):
			continue
		var now: float = l.t
		for k in [-2, -1, 0, 1, 2]:
			l.t = fposmod(now + dt * k, hz.LASER_CYCLE)
			if hz.laser_state(l) == 2:
				l.t = now
				return true
		l.t = now
	return false
