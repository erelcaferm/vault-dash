extends SceneTree
## Checks buying, equipping and saving shop items.
## Run: godot --headless --path . --script res://tests/test_shop.gd

const Skins := preload("res://scripts/skins.gd")
const SAVE := "user://test_shop_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = _new_game()
	await process_frame
	var rainbow := Skins.find(Skins.HERO, "rainbow")
	var glass := Skins.find(Skins.WALLS, "glass")

	_expect(game.owns(Skins.find(Skins.HERO, "white")), "white is free")
	_expect(game.owns(Skins.find(Skins.HERO, "black")), "black is free")
	_expect(game.owns(Skins.find(Skins.WALLS, "rubble")), "rubble is free")
	_expect(not game.owns(rainbow), "rainbow starts locked")
	var priciest := 0
	for item in Skins.HERO:
		priciest = maxi(priciest, item.price)
	_expect(rainbow.price == priciest, "rainbow is the most expensive colour")

	game.total_coins = rainbow.price - 1
	_expect(not game.buy("hero", rainbow), "can't buy without enough coins")
	_expect(game.total_coins == rainbow.price - 1, "failed purchase costs nothing")

	game.total_coins = rainbow.price + glass.price + 5
	_expect(game.buy("hero", rainbow), "buys rainbow")
	_expect(game.buy("walls", glass), "buys glass")
	_expect(game.total_coins == 5, "coins are spent")
	_expect(game.equipped_hero == "rainbow" and game.equipped_wall == "glass", "purchases are equipped")
	_expect(not game.buy("hero", rainbow), "can't buy twice")

	var fire := Skins.find(Skins.TRAILS, "fire")
	_expect(game.owns(Skins.find(Skins.TRAILS, "afterimage")) and not game.owns(fire), "only the Afterimage trail is free")
	game.total_coins += fire.price
	_expect(game.buy("trail", fire) and game.equipped_trail == "fire", "buys and equips a trail")
	game._open_shop()
	game.shop._show_tab("trail")
	_expect(game.shop._grid.get_child_count() == Skins.TRAILS.size(), "the Trails tab lists every trail")
	var crown := Skins.find(Skins.HATS, "crown")
	var cap := Skins.find(Skins.HATS, "cap")
	_expect(game.owns(Skins.find(Skins.HATS, "no_hat")) and not game.buy("hat", crown), "no hat is free, the crown can't be bought")
	game.total_coins += cap.price
	_expect(game.buy("hat", cap) and game.equipped_hat == "cap", "buys and equips a hat")
	var acid := Skins.find(Skins.LAVA, "acid")
	game.total_coins += acid.price
	_expect(game.buy("lava", acid) and game.equipped_lava == "acid", "buys and equips a lava skin")
	game.shop.visible = false

	game.equip("hero", "black")
	game.queue_free()

	var reloaded = _new_game()
	await process_frame
	_expect(reloaded.total_coins == 5, "coins survive a restart")
	_expect(reloaded.owns(rainbow) and reloaded.owns(glass), "purchases survive a restart")
	_expect(reloaded.equipped_hero == "black" and reloaded.equipped_wall == "glass" and reloaded.equipped_trail == "fire" and reloaded.equipped_lava == "acid" and reloaded.equipped_hat == "cap", "equipped items survive a restart")

	var red := Skins.hero_color(rainbow, 0.0)
	var later := Skins.hero_color(rainbow, 0.25)
	_expect(not red.is_equal_approx(later), "rainbow changes colour")
	_expect(Skins.RAINBOW_SLIDE_SPEED > Skins.RAINBOW_IDLE_SPEED, "rainbow cycles faster while sliding")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures == 0:
		print("PASS: shop buys, equips and saves correctly")
	quit(1 if failures > 0 else 0)


func _new_game():
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	return game


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
