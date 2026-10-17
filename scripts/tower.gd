extends RefCounted
## The tower grid and its movement rules, with no drawing or input.
## Shared by the game (scripts/main.gd) and the solver test.

const ROOM_W := 11
const ROOM_H := 10

const WALL := "#"
const EMPTY := "."
const COIN := "c"
const SPIKES := "^"
const CRACKED := "x"
const START := "S"
const GOAL := "G"

var rows: Array = []
var width := ROOM_W
var height := 0
var room_count := 0
var start := Vector2i.ZERO


func build(room_defs: Array) -> void:
	rows.clear()
	room_count = room_defs.size()
	# Rooms are listed bottom to top, but row 0 is the top of the tower.
	for i in range(room_count - 1, -1, -1):
		var room: Array = room_defs[i]
		assert(room.size() == ROOM_H, "room %d has %d rows" % [i, room.size()])
		for line: String in room:
			assert(line.length() == ROOM_W, "room %d has a row of width %d" % [i, line.length()])
			var row: Array = []
			for ch in line:
				row.append(ch)
			rows.append(row)
	height = rows.size()
	for y in height:
		for x in width:
			if rows[y][x] == START:
				start = Vector2i(x, y)
				rows[y][x] = EMPTY


func get_tile(c: Vector2i, broken: Dictionary = {}) -> String:
	if c.x < 0 or c.x >= width or c.y < 0 or c.y >= height:
		return WALL
	var t: String = rows[c.y][c.x]
	if t == CRACKED and broken.has(c):
		return EMPTY
	return t


func set_tile(c: Vector2i, t: String) -> void:
	rows[c.y][c.x] = t


## Which room (0 = bottom) a grid row belongs to.
func room_of(y: int) -> int:
	return room_count - 1 - floori(float(y) / ROOM_H)


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
