extends RefCounted
## The endless tower grid and its movement rules, with no drawing or input.
## Shared by the game (scripts/main.gd) and the solver tests.
##
## Room 0 sits at the bottom and rooms stack upwards forever, so grid rows
## are negative: room 0 covers rows -10..-1, room 1 rows -20..-11, and so on.
## Rooms are generated the first time anything looks at them, from a seeded
## random generator, so the same seed always builds the same tower.

const ROOM_W := 11
const ROOM_H := 10

const WALL := "#"
const EMPTY := "."
const COIN := "c"
const SPIKES := "^"
const CRACKED := "x"
const START := "S"
const GOAL := "G"

## How many rooms you must climb before the next harder room is unlocked,
## and how many of the hardest unlocked rooms are in the mix at once.
const ROOMS_PER_UNLOCK := 2
const POOL_SIZE := 6

var width := ROOM_W
var start := Vector2i.ZERO
## For tests: when 0 or more, every tile from this room up is the exit.
var room_limit := -1

var _defs: Array = []
var _rooms: Array = []           # generated rooms, each an Array of rows of chars
var _picks: Array = []           # which room definition each room was built from
var _rng := RandomNumberGenerator.new()
var _last_pick := -1


func build(room_defs: Array, seed_value: int) -> void:
	_defs = room_defs
	_rng.seed = seed_value
	_rooms.clear()
	_picks.clear()
	_last_pick = -1
	_rooms.append(_parse(_defs[0], false))
	_picks.append(0)
	for y in ROOM_H:
		for x in ROOM_W:
			if _rooms[0][y][x] == START:
				_rooms[0][y][x] = EMPTY
				start = Vector2i(x, y - ROOM_H)


## Which room (0 = bottom) a grid row belongs to. Negative means below the tower.
func room_of(y: int) -> int:
	return floori(float(-1 - y) / ROOM_H)


## Index into the room list that room `k` was built from.
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
		if t == SPIKES:
			return {"end": c, "dead": true, "won": false, "broke": null}
		if t == GOAL:
			return {"end": c, "dead": false, "won": true, "broke": null}
	return {}


func _ensure(k: int) -> void:
	while _rooms.size() <= k:
		_rooms.append(_generate(_rooms.size()))
		_picks.append(_last_pick)


## Picks a room for height `k`: harder rooms unlock as you climb, the
## easiest ones drop out of the mix, and the same room never comes twice
## in a row. Each room may also be mirrored left to right.
func _generate(k: int) -> Array:
	var hardest := mini(1 + floori(float(k - 1) / ROOMS_PER_UNLOCK), _defs.size() - 1)
	var easiest := maxi(1, hardest - POOL_SIZE + 1)
	var pick := _rng.randi_range(easiest, hardest)
	if pick == _last_pick and hardest > easiest:
		pick = easiest + (pick - easiest + 1 + _rng.randi_range(0, hardest - easiest - 1)) % (hardest - easiest + 1)
	_last_pick = pick
	return _parse(_defs[pick], _rng.randf() < 0.5)


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
