extends SceneTree
## Checks pets: hatching eggs, feeding and levels, the cosmetic lines they
## unlock, food in levels, and the pet following the hero.
## Run: godot --headless --path . --script res://tests/test_pets.gd

const SAVE := "user://test_pets_save.cfg"
const Pets := preload("res://scripts/pets.gd")
const Skins := preload("res://scripts/skins.gd")

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame

	# Every pet has a full outfit: hat (2), trail (3), hero (4), walls (5).
	for pet in Pets.LIST:
		var levels := []
		for kind in ["hero", "hat", "walls", "trail"]:
			for item in Skins.list(kind):
				if item.get("pet", "") == pet.id:
					levels.append(item.pet_level)
		levels.sort()
		_expect(levels == [2, 3, 4, 5], "%s has one reward at each level 2-5" % pet.id)

	# Eggs.
	game.total_coins = 0
	_expect(game.egg_price() == 0, "the first egg is free")
	var first: Dictionary = game.hatch_egg()
	_expect(not first.is_empty() and game.pets.has(first.id), "hatching gives a pet")
	_expect(game.equipped_pet == first.id, "your first pet follows you straight away")
	_expect(game.hatch_egg().is_empty(), "later eggs cost coins")
	game.total_coins = Pets.EGG_PRICE * Pets.LIST.size()
	for i in Pets.LIST.size() - 1:
		game.hatch_egg()
	_expect(game.pets.size() == Pets.LIST.size(), "eggs never hatch a pet you already have")
	_expect(game.hatch_egg().is_empty() and game.total_coins == Pets.EGG_PRICE, "no eggs once you have them all")

	# Feeding and levels.
	var cat := Pets.find("cat")
	_expect(game.feed_pet("cat") == -1, "no food, no feeding")
	game.pet_food["fish"] = 100
	_expect(game.feed_pet("cat") == 0 and game.pets.cat.fed == 1, "a feed counts toward the next level")
	_expect(game.feed_pet("cat") == 2, "enough feeds level the pet up")
	_expect(game.owned.has("cat_ears") and game.new_items.has("cat_ears"), "level 2 unlocks the hat, flagged new")
	while game.feed_pet("cat") >= 0:
		pass
	_expect(game.pets.cat.level == Pets.MAX_LEVEL, "pets stop at the top level")
	_expect(game.pet_food.fish == 100 - 14, "the whole climb takes 2 + 3 + 4 + 5 food")
	for id in ["cat_ears", "cat_tail", "whiskers", "scratch_post"]:
		_expect(game.owned.has(id), "the cat line includes %s" % id)
	var ears := Skins.find(Skins.HATS, "dog_ears")
	game.total_coins = 99999
	_expect(not game.buy("hat", ears), "pet items can't be bought")

	# Food in levels, along a route you can actually take.
	game.equipped_pet = "cat"
	for i in [0, 4, 11, 23]:
		game.start_campaign_level(i)
		_expect(game.food_cell.x >= 0, "level %d has food for the pet" % (i + 1))
		_expect(game.tower.get_tile(game.food_cell) == game.TowerScript.EMPTY, "level %d's food is on open floor" % (i + 1))
	game.start_campaign_level(0)
	var before: int = game.pet_food.get("fish", 0)
	game.cell = game.food_cell - Vector2i(1, 0)
	game.move_dir = Vector2i.RIGHT
	game._advance()
	_expect(game.pet_food.fish == before + 1 and game.food_cell.x < 0, "sliding over the food picks it up")
	game.equipped_pet = ""
	game.start_campaign_level(0)
	_expect(game.food_cell.x < 0, "no food without a pet")

	# The pet follows the hero.
	game.equipped_pet = "dog"
	game.level = {}
	game.reset()
	var start: Vector2 = game.pet_pos
	game._on_swipe(Vector2i.UP)
	for i in 30:
		await process_frame
	_expect(game.pet_pos.distance_to(start) > 1.0, "the pet moves after the hero")
	_expect(game.pet_pos.distance_to(game._player_center()) < game.TILE * 3.0, "the pet stays close")

	# Saved.
	game._save()
	var again = load("res://scenes/main.tscn").instantiate()
	again.save_path = SAVE
	root.add_child(again)
	await process_frame
	_expect(again.pets.cat.level == Pets.MAX_LEVEL and again.equipped_pet == "dog", "pets and levels are saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: eggs, feeding, pet lines, food in levels, following")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
