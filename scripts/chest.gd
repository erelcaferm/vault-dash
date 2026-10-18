extends RefCounted
## Chest rewards: the rarities, how likely each is, and rolling one.
## Chests are never sold; you find one every CHEST_EVERY floors (tower.gd).

const Skins := preload("res://scripts/skins.gd")

## Weights are out of 100.
const RARITIES := [
	{"id": "common", "name": "Common", "weight": 55, "color": Color("4b69ff")},
	{"id": "rare", "name": "Rare", "weight": 25, "color": Color("8847ff")},
	{"id": "epic", "name": "Epic", "weight": 15, "color": Color("d32ce6")},
	{"id": "legendary", "name": "Legendary", "weight": 5, "color": Color("ffd700")},
]
const COMMON_COINS := [50, 100]
const RARE_COINS := [150, 250]
## Paid instead when every item of that rarity is already owned.
const EPIC_FALLBACK_COINS := 400
const LEGENDARY_FALLBACK_COINS := 1000


## Rolls one reward. `owns` is a Callable taking a shop item and returning
## whether the player has it, so nothing already owned is ever dropped.
## Returns {rarity, kind ("coins", "hero", "walls" or "trail"), coins, item}.
static func roll(rng: RandomNumberGenerator, owns: Callable) -> Dictionary:
	var rarity := pick_rarity(rng)
	match rarity.id:
		"common":
			return _coins(rarity, snappedi(rng.randi_range(COMMON_COINS[0], COMMON_COINS[1]), 10))
		"rare":
			return _coins(rarity, snappedi(rng.randi_range(RARE_COINS[0], RARE_COINS[1]), 10))
		"epic":
			var shop_items := _items(func(item): return item.price > 0 and not owns.call(item))
			if shop_items.is_empty():
				return _coins(rarity, EPIC_FALLBACK_COINS)
			return _item(rarity, shop_items[rng.randi_range(0, shop_items.size() - 1)])
		_:
			var exclusive := _items(func(item): return item.get("chest_only", false) and not owns.call(item))
			if exclusive.is_empty():
				return _coins(rarity, LEGENDARY_FALLBACK_COINS)
			return _item(rarity, exclusive[rng.randi_range(0, exclusive.size() - 1)])


static func pick_rarity(rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for r in RARITIES:
		total += r.weight
	var n := rng.randi_range(1, total)
	for r in RARITIES:
		n -= r.weight
		if n <= 0:
			return r
	return RARITIES[0]


static func describe(reward: Dictionary) -> String:
	if reward.kind == "coins":
		return "%d coins" % reward.coins
	return "%s %s" % [reward.item.name, Skins.kind_name(reward.kind)]


static func _coins(rarity: Dictionary, amount: int) -> Dictionary:
	return {"rarity": rarity, "kind": "coins", "coins": amount, "item": {}}


static func _item(rarity: Dictionary, entry: Array) -> Dictionary:
	return {"rarity": rarity, "kind": entry[0], "coins": 0, "item": entry[1]}


## Every shop item matching `filter`, as [kind, item] pairs.
static func _items(filter: Callable) -> Array:
	var out: Array = []
	for kind in ["hero", "walls", "trail"]:
		for item in Skins.list(kind):
			if filter.call(item):
				out.append([kind, item])
	return out
