extends RefCounted
## Breadth-first search over every place the player can stop, using the
## same slide rules as the game.

const DIRS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var tower
var states := {}        # key -> {cell, broken}
var edges := {}         # key -> Array of [dir, next_key]
var parents := {}       # key -> [prev_key, dir]
var won_from := {}      # key -> dir that wins from it
var dead_ends: Array = []
var solution: Array = []


func _init(t) -> void:
	tower = t


func _key(cell: Vector2i, broken: Dictionary) -> String:
	var parts: Array = []
	for b in broken.keys():
		parts.append("%d:%d" % [b.x, b.y])
	parts.sort()
	return "%d,%d|%s" % [cell.x, cell.y, ",".join(parts)]


func run() -> void:
	var start_key := _key(tower.start, {})
	states[start_key] = {"cell": tower.start, "broken": {}}
	parents[start_key] = null
	var queue: Array = [start_key]
	var goal_key := ""
	while not queue.is_empty():
		var k: String = queue.pop_front()
		var s: Dictionary = states[k]
		edges[k] = []
		for dir: Vector2i in DIRS:
			var r: Dictionary = tower.simulate_slide(s.cell, dir, s.broken)
			if r.dead:
				continue
			if r.won:
				won_from[k] = dir
				if goal_key == "":
					goal_key = k
				continue
			var broken: Dictionary = s.broken
			if r.broke != null:
				broken = s.broken.duplicate()
				broken[r.broke] = true
			var nk := _key(r.end, broken)
			if nk == k:
				continue
			edges[k].append([dir, nk])
			if not states.has(nk):
				states[nk] = {"cell": r.end, "broken": broken}
				parents[nk] = [k, dir]
				queue.append(nk)

	if goal_key != "":
		solution = [won_from[goal_key]]
		var k := goal_key
		while parents[k] != null:
			solution.push_front(parents[k][1])
			k = parents[k][0]

	# Any reachable state that can no longer reach the exit is a softlock.
	var reverse := {}
	for k in edges:
		for e in edges[k]:
			if not reverse.has(e[1]):
				reverse[e[1]] = []
			reverse[e[1]].append(k)
	var can_win := {}
	var q: Array = won_from.keys()
	for k in q:
		can_win[k] = true
	while not q.is_empty():
		var k: String = q.pop_front()
		for p in reverse.get(k, []):
			if not can_win.has(p):
				can_win[p] = true
				q.append(p)
	for k in states:
		if not can_win.has(k):
			dead_ends.append(states[k].cell)


func rooms_reached() -> Dictionary:
	var reached := {}
	for k in states:
		reached[tower.room_of(states[k].cell.y)] = true
	return reached
