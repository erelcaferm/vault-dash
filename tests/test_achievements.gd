extends SceneTree
## Checks achievements unlock, pay out and save.
## Run: godot --headless --path . --script res://tests/test_achievements.gd

const Achievements := preload("res://scripts/achievements.gd")
const Skins := preload("res://scripts/skins.gd")
const SAVE := "user://test_achievements_save.cfg"

var failures := 0


func _initialize() -> void:
	# Every achievement reward exists, and every achievement skin has an achievement.
	var ids := {}
	for a in Achievements.LIST:
		_expect(not ids.has(a.id), "achievement id %s is unique" % a.id)
		ids[a.id] = true
		_expect(a.has("coins") != a.has("item"), "%s has exactly one reward" % a.id)
		if a.has("item"):
			var list: Array = Skins.HERO if a.item[0] == "hero" else Skins.WALLS
			var item := Skins.find(list, a.item[1])
			_expect(item.id == a.item[1] and item.get("achievement", "") == a.id, "%s rewards a real skin tied to it" % a.id)
	for item in Skins.HERO + Skins.WALLS:
		if item.has("achievement"):
			_expect(ids.has(item.achievement), "%s is tied to a real achievement" % item.id)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = _new_game()
	await process_frame
	game.total_coins = 0

	for i in 9:
		game.add_stat("coins_collected")
	_expect(not game.unlocked.has("pocket_change"), "9 coins isn't enough")
	game.add_stat("coins_collected")
	_expect(game.unlocked.has("pocket_change"), "10 coins unlocks Pocket Change")
	_expect(game.total_coins == 10, "Pocket Change pays 10 coins")

	for i in 5:
		game._die("Test on floor %d", "spikes")
	_expect(game.unlocked.has("oops") and game.unlocked.has("persistent"), "dying 5 times unlocks Oops and Persistent")
	_expect(game.stat("deaths_spikes") == 5, "deaths are counted by cause")

	var brick := Skins.find(Skins.HERO, "brick")
	_expect(not game.owns(brick), "Brick starts locked")
	game.total_coins = 99999
	_expect(not game.buy("hero", brick), "achievement skins can't be bought")
	game.add_stat("walls_broken", 100)
	_expect(game.owns(brick), "breaking 100 walls unlocks Brick")

	game.best_floor = 49
	game.check_achievements()
	_expect(not game.unlocked.has("sky_high"), "floor 49 isn't Sky High")
	game.best_floor = 50
	game.check_achievements()
	_expect(game.owns(Skins.find(Skins.HERO, "cloud")), "floor 50 unlocks Cloud")
	game._save()
	game.queue_free()

	var again = _new_game()
	await process_frame
	_expect(again.unlocked.has("persistent") and again.unlocked.has("sky_high"), "unlocked achievements survive a restart")
	_expect(again.stat("coins_collected") == 10 and again.stat("deaths") == 5, "stats survive a restart")
	_expect(again.owns(brick), "achievement skins survive a restart")
	again._open_achievements()
	_expect(again.achievements_screen.visible, "trophies screen opens")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: achievements unlock, pay out and save")
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
