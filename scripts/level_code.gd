extends RefCounted
## Levels as share codes, so players can swap levels by copy and paste
## until there's an online level browser.
##
## A level is {name, time, rows}: `time` is the limit in seconds and `rows`
## are HEIGHT strings of WIDTH tiles, using the tower's letters:
##   #  wall    .  floor    c  coin    ^  spikes    x  cracked wall
##   f  fake floor (always gives way)   S  start (one)   G  exit (one or more)
##
## A code is "VD" + version + URL-safe base64 of: time (2 bytes), name length
## and UTF-8 name, the tiles (deflated), and a checksum byte, so a code
## that got cut short or mistyped is rejected instead of loading garbage.

const WIDTH := 13
const HEIGHT := 18
const TILES := "#.c^xfSG"
const MIN_TIME := 10
const MAX_TIME := 300
const TIME_STEP := 5
const DEFAULT_TIME := 60
const MAX_NAME := 24
const PREFIX := "VD1"


## An empty level: walls round the edge, a start near the bottom and an
## exit at the top.
static func blank(name := "") -> Dictionary:
	var rows: Array = []
	for y in HEIGHT:
		var row := ""
		for x in WIDTH:
			var edge := x == 0 or x == WIDTH - 1 or y == 0 or y == HEIGHT - 1
			row += "#" if edge else "."
		rows.append(row)
	rows[HEIGHT - 2] = _put(rows[HEIGHT - 2], WIDTH / 2, "S")
	rows[1] = _put(rows[1], WIDTH / 2, "G")
	return {"name": name, "time": DEFAULT_TIME, "rows": rows}


static func _put(row: String, x: int, t: String) -> String:
	return row.substr(0, x) + t + row.substr(x + 1)


## Why a level can't be played or shared yet, or "" if it's fine.
static func problem(level: Dictionary) -> String:
	var rows: Array = level.get("rows", [])
	if rows.size() != HEIGHT:
		return "Broken level"
	var starts := 0
	var exits := 0
	for row: String in rows:
		if row.length() != WIDTH:
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
	return ""


static func encode(level: Dictionary) -> String:
	var bytes := PackedByteArray()
	var time := clampi(int(level.time), MIN_TIME, MAX_TIME)
	bytes.append(time & 0xff)
	bytes.append(time >> 8)
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
	if not code.begins_with(PREFIX):
		return {}
	var b64 := code.substr(PREFIX.length()).replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.size() < 5 or _checksum(bytes.slice(0, bytes.size() - 1)) != bytes[bytes.size() - 1]:
		return {}
	var time := bytes[0] | (bytes[1] << 8)
	var name_len := bytes[2]
	if 3 + name_len >= bytes.size() - 1:
		return {}
	var name := bytes.slice(3, 3 + name_len).get_string_from_utf8()
	var tiles := bytes.slice(3 + name_len, bytes.size() - 1).decompress(WIDTH * HEIGHT, FileAccess.COMPRESSION_DEFLATE)
	if tiles.size() != WIDTH * HEIGHT:
		return {}
	var rows: Array = []
	for y in HEIGHT:
		var row := ""
		for x in WIDTH:
			var i := tiles[y * WIDTH + x]
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
