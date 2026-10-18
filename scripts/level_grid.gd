extends "res://scripts/tower.gd"
## A single handmade or player-made level, played instead of the endless
## tower. Same tiles and slide rules, but there is no lava: you reach an
## exit (G) before the timer runs out. Fake floor always gives way here.
##
## The level's bottom row sits at y = -1, like the tower's first room, and
## everything outside the grid is wall.

var height := 0
var _grid: Array = []
var movers_at: Array = []        # where moving blocks start (M), now floor
var traps_at: Array = []         # spike traps (T), now floor


## `rows` are equal-length strings, top row first.
func load_rows(rows: Array) -> void:
	width = (rows[0] as String).length()
	height = rows.size()
	_grid = _parse(rows, false)
	start = Vector2i.ZERO
	movers_at.clear()
	traps_at.clear()
	for y in height:
		for x in width:
			var t: String = _grid[y][x]
			if t == START:
				start = Vector2i(x, y - height)
			elif t == "M":
				movers_at.append(Vector2i(x, y - height))
			elif t == "T":
				traps_at.append(Vector2i(x, y - height))
			else:
				continue
			_grid[y][x] = EMPTY


func get_tile(c: Vector2i, broken: Dictionary = {}) -> String:
	if c.x < 0 or c.x >= width or c.y < -height or c.y >= 0:
		return WALL
	var t: String = _grid[c.y + height][c.x]
	if t == CRACKED and broken.has(c):
		return EMPTY
	return t


func set_tile(c: Vector2i, t: String) -> void:
	if c.x < 0 or c.x >= width or c.y < -height or c.y >= 0:
		return
	_grid[c.y + height][c.x] = t


func room_of(_y: int) -> int:
	return 0


func is_trap(_k: int) -> bool:
	return true


func is_chest_floor(_k: int) -> bool:
	return false


func loaded_count() -> int:
	return 1


## How many coins are left in the level.
func coins_left() -> int:
	var n := 0
	for row in _grid:
		n += row.count(COIN)
	return n
