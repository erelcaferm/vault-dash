extends RefCounted
## Missions: three goals on the menu at a time, each paying coins. A finished
## mission is swapped for a new one straight away, and they get bigger (and
## pay more) the more you finish.
##
## A mission either counts up across runs from an achievement stat ("stat"),
## or needs a value reached within one run ("run"): run_coins, run_floor or
## daily_floor, which main.gd reports as they change.

const ACTIVE := 3
## Every this-many missions finished, new ones go up a tier.
const MISSIONS_PER_TIER := 3
const MAX_TIER := 10
## Coins to swap a mission you don't want for a different one.
const SWAP_COST := 25

const TEMPLATES := [
	{"id": "coins_run", "text": "Collect %d coins in one run", "run": "run_coins", "base": 15, "step": 8},
	{"id": "floor_run", "text": "Reach floor %d", "run": "run_floor", "base": 10, "step": 6},
	{"id": "daily_floor", "text": "Reach floor %d in the Daily Climb", "run": "daily_floor", "base": 8, "step": 4},
	{"id": "walls", "text": "Break %d cracked walls", "stat": "walls_broken", "base": 10, "step": 8},
	{"id": "traps", "text": "Pass %d trap floors", "stat": "trap_floors", "base": 2, "step": 2},
	{"id": "chests", "text": "Open %d chests", "one": "Open a chest", "stat": "chests_opened", "base": 1, "step": 0.5},
	{"id": "powerups", "text": "Grab %d power-ups", "one": "Grab a power-up", "stat": "powerups", "base": 2, "step": 1},
	{"id": "coins_total", "text": "Collect %d coins", "stat": "coins_collected", "base": 50, "step": 40},
]


static func find(id: String) -> Dictionary:
	for t in TEMPLATES:
		if t.id == id:
			return t
	return {}


static func tier(missions_done: int) -> int:
	return mini(missions_done / MISSIONS_PER_TIER, MAX_TIER)


## A new mission from a template not in `exclude` (ids already active).
## Returns {id, goal, reward, progress, start}; `start` is the stat's value
## when the mission began, so only progress made after that counts.
static func make(rng: RandomNumberGenerator, missions_done: int, exclude: Array, stat_value: Callable) -> Dictionary:
	var choices := TEMPLATES.filter(func(t): return not exclude.has(t.id))
	var t: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
	var level := tier(missions_done)
	var goal := maxi(1, int(t.base + t.step * level))
	var start := 0
	if t.has("stat"):
		start = stat_value.call(t.stat)
	return {"id": t.id, "goal": goal, "reward": snappedi(50 + 15 * level, 5), "progress": 0, "start": start}


static func describe(m: Dictionary) -> String:
	var t := find(m.id)
	if m.goal == 1 and t.has("one"):
		return t.one
	return t.text % m.goal
