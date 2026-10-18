extends RefCounted
## The endless tower grid and its movement rules, with no drawing or input.
## Shared by the game (scripts/main.gd) and the solver tests.
##
## Room 0 sits at the bottom and rooms stack upwards forever, so grid rows
## are negative: room 0 covers rows -12..-1, room 1 rows -24..-13, and so on.
## Rooms are generated the first time anything looks at them, from a seeded
## random generator, so the same seed always builds the same tower.

const ROOM_W := 13
const ROOM_H := 12

const WALL := "#"
const EMPTY := "."
const COIN := "c"
const SPIKES := "^"
const CRACKED := "x"
const START := "S"
const GOAL := "G"
## Fake floor as stored in a layout, plain and with a coin on top. On normal
## floors these read as EMPTY and COIN; on trap floors they stay as they are
## and drop you out of the tower.
const FAKE := "f"
const FAKE_COIN := "F"

## Every this-many floors is a trap floor, where fake floor gives way.
const TRAP_EVERY := 30
## Every this-many floors has a treasure chest.
const CHEST_EVERY := 30
## Layouts unlocked at the start, and how many more unlock per floor climbed.
const FIRST_UNLOCKED := 10
const UNLOCKS_PER_FLOOR := 3
## How many of the hardest unlocked layouts are in the mix at once.
const POOL_SIZE := 40
## A layout won't come back until this many other floors have passed.
const NO_REPEAT := 12

var width := ROOM_W
var start := Vector2i.ZERO
## For tests: when 0 or more, every tile from this room up is the exit.
var room_limit := -1
var trap_every := TRAP_EVERY
var chest_every := CHEST_EVERY

var _defs: Array = []
var _rooms: Array = []           # generated rooms, each an Array of rows of chars
var _picks: Array = []           # which room definition each room was built from
var _start_def: Array = []
var _rng := RandomNumberGenerator.new()


## `start_room` is always floor 1; every floor above is picked from `layouts`.
func build(start_room: Array, layouts: Array, seed_value: int) -> void:
	_start_def = start_room
	_defs = layouts
	_rng.seed = seed_value
	_rooms.clear()
	_picks.clear()
	_rooms.append(_parse(_start_def, false))
	_picks.append(-1)
	for y in ROOM_H:
		for x in ROOM_W:
			if _rooms[0][y][x] == START:
				_rooms[0][y][x] = EMPTY
				start = Vector2i(x, y - ROOM_H)


## Whether room `k` (0 = bottom) is a trap floor.
func is_trap(k: int) -> bool:
	return (k + 1) % trap_every == 0


func is_chest_floor(k: int) -> bool:
	return (k + 1) % chest_every == 0


## Where the chest sits in room `k`: the spot you land on when you slide in
## through the bottom door, so you can't miss it.
func chest_cell(k: int) -> Vector2i:
	var door := Vector2i(floori(width / 2.0), -k * ROOM_H - 1)
	return simulate_slide(door, Vector2i.UP).end


## Which room (0 = bottom) a grid row belongs to. Negative means below the tower.
func room_of(y: int) -> int:
	return floori(float(-1 - y) / ROOM_H)


## Index into the layout list that room `k` was built from (-1 for the start).
func def_of(k: int) -> int:
	_ensure(k)
	return _picks[k]


func get_tile(c: Vector2i, broken: Dictionary = {}) -> String:
	if c.x < 0 or c.x >= width:
		return WALL
	var k := room_of(c.y)
	if k < 0:
		return WALL
	if room_limit >= 0 and k >= room_limit:
		return GOAL
	_ensure(k)
	var t: String = _rooms[k][c.y + (k + 1) * ROOM_H][c.x]
	if t == CRACKED and broken.has(c):
		return EMPTY
	if t == FAKE and not is_trap(k):
		return EMPTY
	if t == FAKE_COIN and not is_trap(k):
		return COIN
	return t


func set_tile(c: Vector2i, t: String) -> void:
	var k := room_of(c.y)
	_ensure(k)
	_rooms[k][c.y + (k + 1) * ROOM_H][c.x] = t


## Slides from `cell` in `dir` until something stops it, without changing
## the grid. Cracked walls listed in `broken` count as open.
## Returns {end, dead, won, broke}, where `broke` is the cracked wall that
## stopped the slide (it crumbles), or null.
func simulate_slide(cell: Vector2i, dir: Vector2i, broken: Dictionary = {}) -> Dictionary:
	var c := cell
	while true:
		var t := get_tile(c + dir, broken)
		if t == WALL:
			return {"end": c, "dead": false, "won": false, "broke": null}
		if t == CRACKED:
			return {"end": c, "dead": false, "won": false, "broke": c + dir}
		c += dir
		if t == SPIKES or t == FAKE or t == FAKE_COIN:
			return {"end": c, "dead": true, "won": false, "broke": null}
		if t == GOAL:
			return {"end": c, "dead": false, "won": true, "broke": null}
	return {}


func _ensure(k: int) -> void:
	while _rooms.size() <= k:
		var pick := _pick_layout(_rooms.size())
		_picks.append(pick)
		_rooms.append(_parse(_defs[pick], _rng.randf() < 0.5))


## Picks a layout for room `k`: harder layouts unlock as you climb, the
## easiest drop out of the mix, and recent layouts are skipped.
func _pick_layout(k: int) -> int:
	var hardest := mini(FIRST_UNLOCKED - 1 + (k - 1) * UNLOCKS_PER_FLOOR, _defs.size() - 1)
	var easiest := maxi(0, hardest - POOL_SIZE + 1)
	var recent := _picks.slice(maxi(0, _picks.size() - NO_REPEAT))
	var pick := _rng.randi_range(easiest, hardest)
	for attempt in 30:
		if not recent.has(pick):
			break
		pick = _rng.randi_range(easiest, hardest)
	return pick


func _parse(lines: Array, mirror: bool) -> Array:
	var room: Array = []
	for line: String in lines:
		var row: Array = []
		for ch in line:
			row.append(ch)
		if mirror:
			row.reverse()
		room.append(row)
	return room
