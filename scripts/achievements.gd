extends RefCounted
## Achievements: what counts, the goal, and the reward.
##
## Each achievement watches one stat (see main.gd `stat()`), and unlocks when
## that stat reaches `goal`. A reward is either coins or a skin that can only
## be earned this way (those skins are listed in skins.gd with "achievement").

const LIST := [
	# Climbing
	{"id": "first_steps", "name": "First Steps", "desc": "Reach floor 5", "stat": "best_floor", "goal": 5, "coins": 25},
	{"id": "climber", "name": "Climber", "desc": "Reach floor 25", "stat": "best_floor", "goal": 25, "coins": 100},
	{"id": "sky_high", "name": "Sky High", "desc": "Reach floor 50", "stat": "best_floor", "goal": 50, "item": ["hero", "cloud"]},
	{"id": "centurion", "name": "Centurion", "desc": "Reach floor 100", "stat": "best_floor", "goal": 100, "item": ["hero", "royal"]},
	{"id": "tower_legend", "name": "Tower Legend", "desc": "Reach floor 200", "stat": "best_floor", "goal": 200, "item": ["walls", "marble"]},
	{"id": "speedrunner", "name": "Speedrunner", "desc": "Reach floor 20 within 60 seconds", "stat": "fast_20", "goal": 1, "item": ["hero", "speedster"]},
	# Coins
	{"id": "pocket_change", "name": "Pocket Change", "desc": "Collect 10 coins", "stat": "coins_collected", "goal": 10, "coins": 10},
	{"id": "coin_collector", "name": "Coin Collector", "desc": "Collect 250 coins", "stat": "coins_collected", "goal": 250, "coins": 50},
	{"id": "treasure_hunter", "name": "Treasure Hunter", "desc": "Collect 1,000 coins", "stat": "coins_collected", "goal": 1000, "item": ["walls", "treasure"]},
	# Deaths
	{"id": "oops", "name": "Oops", "desc": "Die for the first time", "stat": "deaths", "goal": 1, "coins": 10},
	{"id": "persistent", "name": "Persistent", "desc": "Die 5 times", "stat": "deaths", "goal": 5, "coins": 25},
	{"id": "never_give_up", "name": "Never Give Up", "desc": "Die 50 times", "stat": "deaths", "goal": 50, "item": ["hero", "ghost"]},
	{"id": "hot_feet", "name": "Hot Feet", "desc": "Get caught by the lava 10 times", "stat": "deaths_lava", "goal": 10, "coins": 50},
	{"id": "pincushion", "name": "Pincushion", "desc": "Land on spikes 10 times", "stat": "deaths_spikes", "goal": 10, "coins": 50},
	{"id": "gravity", "name": "Gravity Wins", "desc": "Fall through a fake floor 5 times", "stat": "deaths_fake", "goal": 5, "coins": 50},
	# Chests
	{"id": "lucky", "name": "Lucky", "desc": "Open your first chest", "stat": "chests_opened", "goal": 1, "coins": 25},
	{"id": "hoarder", "name": "Hoarder", "desc": "Open 5 chests", "stat": "chests_opened", "goal": 5, "coins": 100},
	{"id": "jackpot", "name": "Jackpot", "desc": "Get a Legendary from a chest", "stat": "legendaries", "goal": 1, "coins": 200},
	{"id": "secret_stash", "name": "Secret Stash", "desc": "Find a bonus chest", "stat": "bonus_chests", "goal": 1, "coins": 100},
	# Tower
	{"id": "wrecking_ball", "name": "Wrecking Ball", "desc": "Break 100 cracked walls", "stat": "walls_broken", "goal": 100, "item": ["hero", "brick"]},
	{"id": "trap_dodger", "name": "Trap Dodger", "desc": "Reach 25 trap floors", "stat": "trap_floors", "goal": 25, "item": ["walls", "frozen"]},
	{"id": "regular", "name": "Regular", "desc": "Play 25 runs", "stat": "runs", "goal": 25, "coins": 100},
	# Collecting
	{"id": "fashionista", "name": "Fashionista", "desc": "Own 5 hero colours", "stat": "heroes_owned", "goal": 5, "coins": 100},
]


static func find(id: String) -> Dictionary:
	for a in LIST:
		if a.id == id:
			return a
	return {}


static func reward_text(a: Dictionary) -> String:
	if a.has("coins"):
		return "%d coins" % a.coins
	var Skins := load("res://scripts/skins.gd")
	var list: Array = Skins.HERO if a.item[0] == "hero" else Skins.WALLS
	return "Skin: %s" % Skins.find(list, a.item[1]).name
