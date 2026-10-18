extends RefCounted
## Moving blocks and spike traps on the endless tower.
##
## Moving blocks wander their room one tile at a time, in any of the four
## directions, and kill you if you touch them. Walls and cracked walls stop
## them. They never move onto the tile you're standing on, so you're always
## safe while standing still: the danger is only in sliding through their
## path, and you can wait for a gap.
##
## Spike traps sit on open tiles you can only slide through, never stop on
## (no wall next to them), so they can't catch you standing. They cycle
## down, warning, up; sliding over one while it's up kills you.
##
## Both are rolled per floor from their own seed, so a run's hazards don't
## change the rest of the tower. None appear in levels or the Daily Climb.

const TowerScript := preload("res://scripts/tower.gd")

const MOVER_FROM_FLOOR := 8
const MOVER_CHANCE := 0.15          # at MOVER_FROM_FLOOR
const MOVER_MAX_CHANCE := 0.5       # from MOVER_RAMP_FLOOR up
const MOVER_RAMP_FLOOR := 150
const MOVER_TWO_FROM := 60          # floors from here can have two
const MOVER_TWO_CHANCE := 0.4
const MOVER_SPEED := 2.6            # tiles per second
const MOVER_TURN_CHANCE := 0.25     # chance to turn at an open side tile
const MOVER_SAFE_DIST := 4          # tiles from where you land in the room
const HIT_SIZE := 0.72              # how close (in tiles) counts as a touch
## A block's area (the open tiles it can reach) must be at least this big,
## and no single row or column may hold more than MOVER_MAX_LINE of it, so
## it spends plenty of time off any line you need to slide along.
const MOVER_MIN_AREA := 10
const MOVER_MAX_LINE := 0.5

const TRAP_FROM_FLOOR := 12
const TRAP_CHANCE := 0.2
const TRAP_MAX_CHANCE := 0.45
const TRAP_MIN := 2
const TRAP_MAX := 4
const TRAP_CYCLE := 3.0             # seconds for down, warning and up
const TRAP_WARN_AT := 1.7           # spikes start to poke out
const TRAP_UP_AT := 2.2             # and are deadly until the cycle ends

const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var tower
var enabled := true
var movers: Array = []              # {room, cell, next, pos (tiles), dir}
var traps := {}                     # cell -> phase offset (seconds), shared per room
var time := 0.0
var rolled := 0                     # floors below this have had their roll
var rng := RandomNumberGenerator.new()
var has_chest: Callable             # room -> whether a chest sits there this run
var blocked_cells: Callable         # -> cells to keep traps off (power-ups, food)
var _paths := {}                    # room -> {cell: true} where its blocks may go


func setup(t, seed_value: int, on: bool) -> void:
	tower = t
	enabled = on
	rng.seed = seed_value
	movers.clear()
	traps.clear()
	_paths.clear()
	time = 0.0
	rolled = 0


## Rolls hazards for every floor below `count` that hasn't had its roll.
func roll(count: int) -> void:
	while rolled < count:
		var k := rolled
		rolled += 1
		if not enabled:
			continue
		var f := k + 1
		var chest: bool = has_chest.is_valid() and has_chest.call(k)
		if f >= MOVER_FROM_FLOOR and not chest and rng.randf() < chance(f, MOVER_FROM_FLOOR, MOVER_CHANCE, MOVER_MAX_CHANCE):
			var n := 2 if f >= MOVER_TWO_FROM and rng.randf() < MOVER_TWO_CHANCE else 1
			for i in n:
				_spawn_mover(k)
		if f >= TRAP_FROM_FLOOR and not chest and rng.randf() < chance(f, TRAP_FROM_FLOOR, TRAP_CHANCE, TRAP_MAX_CHANCE):
			_place_traps(k)


static func chance(f: int, from: int, low: float, high: float) -> float:
	return lerpf(low, high, clampf(float(f - from) / (MOVER_RAMP_FLOOR - from), 0.0, 1.0))


func _room_cells(k: int) -> Array:
	var cells: Array = []
	for y in range(-(k + 1) * TowerScript.ROOM_H, -k * TowerScript.ROOM_H):
		for x in tower.width:
			cells.append(Vector2i(x, y))
	return cells


## The tiles blocks in room `k` may use: open tiles in the room, minus dead
## ends, peeled away until every tile left has two ways out. So a block can
## never get cornered in a doorway or a dead end by you standing in its
## only exit: one way out is always free.
func _path(k: int) -> Dictionary:
	if _paths.has(k):
		return _paths[k]
	var cells := {}
	for c: Vector2i in _room_cells(k):
		if _open(c, k):
			cells[c] = true
	var peeled := true
	while peeled:
		peeled = false
		for c: Vector2i in cells.keys():
			var ways := 0
			for d: Vector2i in DIRS:
				if cells.has(c + d):
					ways += 1
			if ways < 2:
				cells.erase(c)
				peeled = true
	_paths[k] = cells
	return cells


## Whether a block can move onto `c` (it stays inside room `k`).
func _open(c: Vector2i, k: int) -> bool:
	if tower.room_of(c.y) != k:
		return false
	var t: String = tower.get_tile(c)
	return t != TowerScript.WALL and t != TowerScript.CRACKED and t != TowerScript.GOAL


func _spawn_mover(k: int) -> void:
	var landing: Vector2i = tower.chest_cell(k)
	var door_x := floori(tower.width / 2.0)
	var spots: Array = []
	var path := _path(k)
	for c: Vector2i in path:
		if _mover_at(c):
			continue
		if absi(c.x - landing.x) + absi(c.y - landing.y) < MOVER_SAFE_DIST:
			continue
		# Keep the bottom door clear, where you come in.
		if absi(c.x - door_x) <= 1 and c.y >= -k * TowerScript.ROOM_H - 3:
			continue
		# It has to have room to move.
		spots.append(c)
	spots = spots.filter(func(c): return _roomy(c, k))
	if spots.is_empty():
		return
	var c: Vector2i = spots[rng.randi_range(0, spots.size() - 1)]
	var dirs: Array = DIRS.filter(func(d): return path.has(c + d))
	movers.append({"room": k, "cell": c, "next": c, "pos": Vector2(c), "dir": dirs[rng.randi_range(0, dirs.size() - 1)]})


## Whether a block starting at `c` has enough room to wander, off any one line.
func _roomy(c: Vector2i, k: int) -> bool:
	var area := {c: true}
	var todo: Array = [c]
	while not todo.is_empty():
		var at: Vector2i = todo.pop_back()
		for d: Vector2i in DIRS:
			var n: Vector2i = at + d
			if not area.has(n) and _path(k).has(n):
				area[n] = true
				todo.append(n)
	if area.size() < MOVER_MIN_AREA:
		return false
	var rows := {}
	var cols := {}
	for a: Vector2i in area:
		rows[a.y] = rows.get(a.y, 0) + 1
		cols[a.x] = cols.get(a.x, 0) + 1
	var most: int = maxi(rows.values().max(), cols.values().max())
	return most <= area.size() * MOVER_MAX_LINE


func _mover_at(c: Vector2i) -> bool:
	for m in movers:
		if m.cell == c or m.next == c:
			return true
	return false


## Open tiles you can only slide over, never stop on: nothing solid on any side.
func _pass_through(c: Vector2i) -> bool:
	if tower.get_tile(c) != TowerScript.EMPTY:
		return false
	for d: Vector2i in DIRS:
		var t: String = tower.get_tile(c + d)
		if t == TowerScript.WALL or t == TowerScript.CRACKED:
			return false
	return true


func _place_traps(k: int) -> void:
	var avoid: Array = blocked_cells.call() if blocked_cells.is_valid() else []
	var spots: Array = _room_cells(k).filter(func(c): return _pass_through(c) and not avoid.has(c) and not traps.has(c))
	if spots.size() < TRAP_MIN:
		return
	var phase := rng.randf_range(0.0, TRAP_CYCLE)
	for i in mini(rng.randi_range(TRAP_MIN, TRAP_MAX), spots.size()):
		var j := rng.randi_range(0, spots.size() - 1)
		traps[spots[j]] = phase
		spots.remove_at(j)


## Moves the blocks. `rest` is the tile you're standing on, or (-1, -1)
## while sliding; blocks never step onto it.
func update(delta: float, rest: Vector2i, lowest_room: int) -> void:
	time += delta
	movers = movers.filter(func(m): return m.room >= lowest_room)
	for m in movers:
		var step := MOVER_SPEED * delta
		while step > 0.0:
			var to := Vector2(m.next)
			var gap: float = m.pos.distance_to(to)
			if gap > step:
				m.pos = m.pos.move_toward(to, step)
				break
			m.pos = to
			step -= gap
			m.cell = m.next
			if not _choose(m, rest):
				break


## Picks where block `m` goes next. Returns false if it has to wait.
func _choose(m: Dictionary, rest: Vector2i) -> bool:
	var k: int = m.room
	var free := func(d: Vector2i) -> bool:
		var c: Vector2i = m.cell + d
		return _path(k).has(c) and c != rest and not _taken(c, m)
	var ahead: bool = free.call(m.dir)
	var sides: Array = [Vector2i(m.dir.y, m.dir.x), Vector2i(-m.dir.y, -m.dir.x)].filter(func(d): return free.call(d))
	if not sides.is_empty() and (not ahead or rng.randf() < MOVER_TURN_CHANCE):
		m.dir = sides[rng.randi_range(0, sides.size() - 1)]
	elif not ahead:
		if free.call(-m.dir):
			m.dir = -m.dir
		else:
			return false
	m.next = m.cell + m.dir
	return true


func _taken(c: Vector2i, me: Dictionary) -> bool:
	for m in movers:
		if m != me and (m.cell == c or m.next == c):
			return true
	return false


## Whether a block touches the player at `p` (in tiles, the tile's top-left).
func mover_hits(p: Vector2) -> bool:
	for m in movers:
		var d: Vector2 = (m.pos - p).abs()
		if d.x < HIT_SIZE and d.y < HIT_SIZE:
			return true
	return false


## 0 down, 1 warning, 2 up.
func trap_state(c: Vector2i) -> int:
	if not traps.has(c):
		return 0
	var t := fposmod(time + traps[c], TRAP_CYCLE)
	return 2 if t >= TRAP_UP_AT else (1 if t >= TRAP_WARN_AT else 0)


func has_hazards(k: int) -> bool:
	for m in movers:
		if m.room == k:
			return true
	for c: Vector2i in traps:
		if tower.room_of(c.y) == k:
			return true
	return false


# --- Drawing ---------------------------------------------------------------

## `theme(row)` gives the background pattern at a row (BIOMES[].deco in
## main.gd), so blocks match the place they're in: a stone block in the
## Crypt, an ice cube in the Ice Caves, a pufferfish in the Deep Sea...
func draw(canvas: CanvasItem, tile: float, y0: int, y1: int, anim: float, theme: Callable = Callable()) -> void:
	for c: Vector2i in traps:
		if c.y >= y0 and c.y <= y1:
			_draw_trap(canvas, Rect2(Vector2(c) * tile, Vector2(tile, tile)), trap_state(c), anim)
	for m in movers:
		var mid: Vector2 = (m.pos + Vector2(0.5, 0.5)) * tile
		if mid.y >= (y0 - 1) * tile and mid.y <= (y1 + 1) * tile:
			var look: String = theme.call(m.cell.y) if theme.is_valid() else ""
			_draw_mover(canvas, mid, tile, m.dir, anim, look)


func _draw_trap(canvas: CanvasItem, r: Rect2, state: int, anim: float) -> void:
	var red := Color("e84855")
	# A dark plate with a red rim and spike tips just showing, so you can
	# see it's a trap even while it's safe.
	var plate := r.grow(-3)
	canvas.draw_rect(plate, Color(0.16, 0.16, 0.2, 0.9))
	canvas.draw_rect(plate, Color(red, 0.75), false, 1.5)
	var w := (r.size.x - 6) / 3.0
	for i in 3:
		var bx := plate.position.x + w * (i + 0.5)
		# Down: little tips. Warning: half out and flashing. Up: full spikes.
		var height: float = r.size.y * [0.16, 0.3, 0.62][state]
		var color: Color = [Color(red, 0.5), Color(red, 0.55 + 0.45 * sin(anim * 30.0)), red][state]
		var base_y := plate.end.y - 2
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(bx - w * 0.4, base_y), Vector2(bx, base_y - height), Vector2(bx + w * 0.4, base_y),
		]), color)


const MOVER_LOOKS := {
	"bricks": Color("6b6f80"), "icicles": Color("9fd8f2"), "vines": Color("4f6b3a"),
	"crystals": Color("9b6ad8"), "bubbles": Color("f2b134"), "embers": Color("3a1a12"),
	"clouds": Color("4a4f63"),
}


func _draw_mover(canvas: CanvasItem, mid: Vector2, tile: float, dir: Vector2i, anim: float, theme := "") -> void:
	var s := tile * 0.8
	var red := Color("e84855")
	var glow := 0.5 + 0.5 * sin(anim * 6.0)
	var ball := theme == "bubbles" or theme == "clouds"
	var body := Rect2(mid - Vector2(s, s) * 0.5, Vector2(s, s))
	var fill: Color = MOVER_LOOKS.get(theme, Color("2b2d36"))
	# A red glow and spikes on every side say "don't touch", whatever it looks like.
	if ball:
		canvas.draw_circle(mid, s * 0.5 + 3, Color(red, 0.25 + 0.2 * glow))
		for i in 8:
			var out := Vector2.from_angle(TAU * i / 8.0 + anim * 0.8)
			var side := Vector2(-out.y, out.x)
			var base := mid + out * s * 0.45
			canvas.draw_colored_polygon(PackedVector2Array([base + side * s * 0.1, base + out * s * 0.22, base - side * s * 0.1]), Color("c0c4cc"))
	else:
		canvas.draw_rect(body.grow(3), Color(red, 0.25 + 0.2 * glow))
		for d: Vector2i in DIRS:
			var out := Vector2(d)
			var side := Vector2(-out.y, out.x)
			for i in [-1, 1]:
				var base: Vector2 = mid + out * s * 0.5 + side * s * 0.22 * i
				canvas.draw_colored_polygon(PackedVector2Array([
					base + side * s * 0.12, base + out * s * 0.2, base - side * s * 0.12,
				]), Color("c0c4cc"))
	match theme:
		"bubbles":
			canvas.draw_circle(mid, s * 0.48, fill)
			canvas.draw_arc(mid, s * 0.48, 0, TAU, 24, red, 2.0)
			canvas.draw_circle(mid + Vector2(0, s * 0.2), s * 0.22, fill.lightened(0.45))
			# Little fins flap.
			var flap := sin(anim * 12.0) * s * 0.08
			for i in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([mid + Vector2(s * 0.45 * i, 0), mid + Vector2(s * 0.62 * i, -s * 0.1 - flap), mid + Vector2(s * 0.62 * i, s * 0.1 + flap)]), fill.darkened(0.2))
		"clouds":
			for p in [Vector2(-0.2, 0.05), Vector2(0.2, 0.05), Vector2(0, -0.12)]:
				canvas.draw_circle(mid + p * s, s * 0.3, fill)
			canvas.draw_arc(mid, s * 0.48, 0, TAU, 24, red, 2.0)
			if fposmod(anim, 1.6) < 0.15:
				canvas.draw_polyline(PackedVector2Array([mid + Vector2(0, s * 0.25), mid + Vector2(-s * 0.08, s * 0.42), mid + Vector2(s * 0.05, s * 0.42), mid + Vector2(-s * 0.04, s * 0.6)]), Color("ffe066"), 2.0)
		_:
			canvas.draw_rect(body, fill)
			match theme:
				"bricks":
					canvas.draw_line(body.position + Vector2(0, s * 0.62), body.position + Vector2(s, s * 0.62), fill.darkened(0.35), 1.5)
					canvas.draw_line(body.position + Vector2(s * 0.5, s * 0.62), body.position + Vector2(s * 0.5, s), fill.darkened(0.35), 1.5)
				"icicles":
					canvas.draw_rect(body, Color(1, 1, 1, 0.15))
					canvas.draw_line(body.position + Vector2(s * 0.15, s * 0.55), body.position + Vector2(s * 0.55, s * 0.15), Color(1, 1, 1, 0.7), 2.0)
				"vines":
					canvas.draw_circle(body.position + Vector2(s * 0.75, s * 0.1), s * 0.14, Color("8fc275"))
					canvas.draw_line(body.position + Vector2(s * 0.1, s * 0.75), body.position + Vector2(s * 0.4, s), Color("8fc275"), 2.0)
				"crystals":
					canvas.draw_line(body.position, mid + Vector2(0, s * 0.3), fill.lightened(0.35), 1.5)
					canvas.draw_line(body.position + Vector2(s, 0), mid + Vector2(0, s * 0.3), fill.lightened(0.35), 1.5)
				"embers":
					var hot := Color("ff9a4d", 0.6 + 0.4 * sin(anim * 5.0))
					canvas.draw_polyline(PackedVector2Array([body.position + Vector2(s * 0.1, s * 0.85), mid + Vector2(-s * 0.05, s * 0.25), body.position + Vector2(s * 0.9, s * 0.7)]), hot, 2.0)
			canvas.draw_rect(body, red, false, 2.0)
	# Angry eyes look the way it's going.
	var look := Vector2(dir) * s * 0.08
	for i in [-1, 1]:
		var eye: Vector2 = mid + Vector2(s * 0.18 * i, -s * 0.02) + look
		canvas.draw_circle(eye, s * 0.11, Color.WHITE)
		canvas.draw_circle(eye + look * 0.6, s * 0.055, Color.BLACK)
		canvas.draw_line(eye + Vector2(s * 0.12 * i, -s * 0.2), eye + Vector2(-s * 0.08 * i, -s * 0.1), red, 2.0)
