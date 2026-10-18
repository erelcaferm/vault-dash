extends SceneTree
## Checks chest odds, rewards, placement and granting.
## Run: godot --headless --path . --script res://tests/test_chest.gd

const Chest := preload("res://scripts/chest.gd")
const Skins := preload("res://scripts/skins.gd")
const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const SAVE := "user://test_chest_save.cfg"

var failures := 0


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var nothing := func(_item): return false
	var everything := func(_item): return true

	# Odds match the weights.
	var counts := {}
	var n := 20000
	for i in n:
		var r: Dictionary = Chest.roll(rng, nothing)
		counts[r.rarity.id] = counts.get(r.rarity.id, 0) + 1
		if r.rarity.id == "epic":
			_expect(r.kind != "coins" and r.item.price > 0, "epic drops a shop item")
		if r.rarity.id == "legendary":
			_expect(r.item.get("chest_only", false), "legendary drops a chest-only item")
	for rarity in Chest.RARITIES:
		var share: float = counts.get(rarity.id, 0) * 100.0 / n
		_expect(absf(share - rarity.weight) < 1.5, "%s drops %.1f%% of the time (want %d%%)" % [rarity.name, share, rarity.weight])

	# Owned items never drop; with everything owned, coins come instead.
	for i in 2000:
		var r: Dictionary = Chest.roll(rng, everything)
		_expect(r.kind == "coins" and r.coins > 0, "nothing owned drops again")

	# Every layout puts the chest somewhere you can stand.
	for i in Rooms.LAYOUTS.size():
		var tower = TowerScript.new()
		tower.build(Rooms.START, [Rooms.LAYOUTS[i]], i)
		tower.chest_every = 2
		var c: Vector2i = tower.chest_cell(1)
		var t: String = tower.get_tile(c)
		_expect(tower.room_of(c.y) == 1 and (t == TowerScript.EMPTY or t == TowerScript.COIN),
				"layout %d: chest lands on open floor (got '%s')" % [i, t])

	# Granting rewards.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame
	var before: int = game.total_coins
	game.grant({"rarity": Chest.RARITIES[0], "kind": "coins", "coins": 70, "item": {}})
	_expect(game.total_coins == before + 70, "coin rewards go to the bank")
	var neon := Skins.find(Skins.HERO, "neon")
	_expect(not game.owns(neon), "neon starts locked")
	_expect(not game.buy("hero", neon), "chest-only items can't be bought")
	game.grant({"rarity": Chest.RARITIES[3], "kind": "hero", "coins": 0, "item": neon})
	_expect(game.owns(neon) and game.equipped_hero == "neon", "item rewards are unlocked and equipped")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: chest odds, rewards, placement and granting")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
