extends RefCounted
## Levels as share codes, so players can swap levels by copy and paste
## until there's an online level browser.
##
## A level is {name, time, rows}: `time` is the limit in seconds and `rows`
## are equal-length strings of tiles, top row first, using the tower's letters:
##   #  wall    .  floor    c  coin    ^  spikes    x  cracked wall
##   f  fake floor (always gives way)   S  start (one)   G  exit (one or more)
##   M  moving block (starts here)   T  spike trap (on open floor, no wall beside it)
##
## Levels can be MIN_W to MAX_W tiles wide and MIN_H to MAX_H tall. The
## limits keep the editor's cells big enough to tap and the solver quick.
##
## A code is "VD2" + URL-safe base64 of: time (2 bytes), width, height, name
## length and UTF-8 name, the tiles (deflated), and a checksum byte, so a
## code that got cut short or mistyped is rejected instead of loading
## garbage. "VD1" codes, from before sizes could change, are always 13 x 18.

const WIDTH := 13                # the size of a new level
const HEIGHT := 18
const MIN_W := 7
const MAX_W := 16
const MIN_H := 8
const MAX_H := 24
const TILES := "#.c^xfSGMT"         # new letters go on the end, so old codes still read
const MIN_TIME := 10
const MAX_TIME := 300
const TIME_STEP := 5
const DEFAULT_TIME := 60
const MAX_NAME := 24
const PREFIX := "VD2"
const OLD_PREFIX := "VD1"


## An empty level: walls round the edge, a start near the bottom and an
## exit at the top.
static func blank(name := "", w := WIDTH, h := HEIGHT) -> Dictionary:
	var rows: Array = []
	for y in h:
		var row := ""
		for x in w:
			var edge := x == 0 or x == w - 1 or y == 0 or y == h - 1
			row += "#" if edge else "."
		rows.append(row)
	rows[h - 2] = _put(rows[h - 2], w / 2, "S")
	rows[1] = _put(rows[1], w / 2, "G")
	return {"name": name, "time": DEFAULT_TIME, "rows": rows}


static func width_of(level: Dictionary) -> int:
	var rows: Array = level.get("rows", [])
	return 0 if rows.is_empty() else (rows[0] as String).length()


## `level` at a new size. The right column and the top and bottom rows stay
## on the edges, so a walled border stays walled; new space is floor, added
## on the right and at the top (the start is usually near the bottom).
static func resized(level: Dictionary, w: int, h: int) -> Dictionary:
	var rows: Array = level.rows
	var old_w := width_of(level)
	var old_h := rows.size()
	var out: Array = []
	for y in h:
		var oy := 0 if y == 0 else y - (h - old_h)
		if y == h - 1:
			oy = old_h - 1
		elif y > 0 and (oy < 1 or oy >= old_h - 1):
			oy = -1
		var row := ""
		for x in w:
			var ox := x if x < old_w - 1 and x < w - 1 else -1
			if x == w - 1:
				ox = old_w - 1
			# New cells are floor, except on the outer ring, where they copy
			# the ring next to them so a walled border stays closed.
			var sx := ox
			var sy := oy
			if sx < 0 and (y == 0 or y == h - 1):
				sx = old_w - 2
			if sy < 0 and (x == 0 or x == w - 1):
				sy = 1
			row += "." if sx < 0 or sy < 0 else (rows[sy] as String)[sx]
		out.append(row)
	var copy := level.duplicate(true)
	copy.rows = out
	return copy


static func _put(row: String, x: int, t: String) -> String:
	return row.substr(0, x) + t + row.substr(x + 1)


## Why a level can't be played or shared yet, or "" if it's fine.
static func problem(level: Dictionary) -> String:
	var rows: Array = level.get("rows", [])
	var w := width_of(level)
	if rows.size() < MIN_H or rows.size() > MAX_H or w < MIN_W or w > MAX_W:
		return "Broken level"
	var starts := 0
	var exits := 0
	for row: String in rows:
		if row.length() != w:
			return "Broken level"
		for t in row:
			if not t in TILES:
				return "Broken level"
		starts += row.count("S")
		exits += row.count("G")
	if starts != 1:
		return "Place one start"
	if exits == 0:
		return "Place an exit"
	# Traps must be where you can only slide over them, never stand.
	var solid := func(x: int, y: int) -> bool:
		return x < 0 or y < 0 or x >= w or y >= rows.size() or (rows[y] as String)[x] in "#x"
	for y in rows.size():
		for x in w:
			var t: String = (rows[y] as String)[x]
			if t == "T" and (solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1)):
				return "Spike traps need open floor all round"
			if t == "M" and [solid.call(x - 1, y), solid.call(x + 1, y), solid.call(x, y - 1), solid.call(x, y + 1)].count(false) < 2:
				return "Moving blocks need room to move"
	return ""


static func encode(level: Dictionary) -> String:
	var bytes := PackedByteArray()
	var time := clampi(int(level.time), MIN_TIME, MAX_TIME)
	bytes.append(time & 0xff)
	bytes.append(time >> 8)
	bytes.append(width_of(level))
	bytes.append(level.rows.size())
	var name := clean_name(level.get("name", "")).to_utf8_buffer()
	bytes.append(name.size())
	bytes.append_array(name)
	var tiles := PackedByteArray()
	for row: String in level.rows:
		for t in row:
			tiles.append(TILES.find(t))
	bytes.append_array(tiles.compress(FileAccess.COMPRESSION_DEFLATE))
	bytes.append(_checksum(bytes))
	return PREFIX + Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")


## The level in `code`, or {} if it isn't a valid code. Spaces and line
## breaks picked up while copying are ignored.
static func decode(code: String) -> Dictionary:
	code = code.strip_edges().replace(" ", "").replace("\n", "").replace("\r", "")
	var sized := code.begins_with(PREFIX)
	if not sized and not code.begins_with(OLD_PREFIX):
		return {}
	var b64 := code.substr(PREFIX.length()).replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.size() < 7 or _checksum(bytes.slice(0, bytes.size() - 1)) != bytes[bytes.size() - 1]:
		return {}
	var time := bytes[0] | (bytes[1] << 8)
	var at := 2
	var w := WIDTH
	var h := HEIGHT
	if sized:
		w = bytes[2]
		h = bytes[3]
		at = 4
		if w < MIN_W or w > MAX_W or h < MIN_H or h > MAX_H:
			return {}
	var name_len := bytes[at]
	if at + 1 + name_len >= bytes.size() - 1:
		return {}
	var name := bytes.slice(at + 1, at + 1 + name_len).get_string_from_utf8()
	var tiles := bytes.slice(at + 1 + name_len, bytes.size() - 1).decompress(w * h, FileAccess.COMPRESSION_DEFLATE)
	if tiles.size() != w * h:
		return {}
	var rows: Array = []
	for y in h:
		var row := ""
		for x in w:
			var i := tiles[y * w + x]
			if i >= TILES.length():
				return {}
			row += TILES[i]
		rows.append(row)
	var level := {"name": clean_name(name), "time": clampi(time, MIN_TIME, MAX_TIME), "rows": rows}
	return level if problem(level) == "" else {}


static func clean_name(name: String) -> String:
	return name.strip_edges().replace("\n", " ").left(MAX_NAME)


static func _checksum(bytes: PackedByteArray) -> int:
	var sum := 7
	for b in bytes:
		sum = (sum * 31 + b) & 0xff
	return sum
