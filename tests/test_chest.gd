extends SceneTree
## Checks chest odds, rewards, placement, granting and the hidden trap meter.
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

	# The hidden trap meter.
	game.trap_meter = 0.0
	game.bonus_chests.clear()
	game.bonus_chest_owed = false
	var full: float = game.TRAP_METER_FULL
	_expect(game.add_trap_meter(12, full - 0.5) == 0, "meter below full books nothing")
	_expect(game.add_trap_meter(14, 0.75) == 19, "full meter books a chest 5 floors ahead")
	_expect(is_equal_approx(game.trap_meter, 0.25), "overflow carries into the next fill")
	_expect(game.has_chest(18) and game.bonus_chest_owed, "bonus chest is on floor 19 and owed")
	game.trap_meter = full
	_expect(game.add_trap_meter(25, 0.0) == 40, "a chest floor (30) pushes the bonus 10 floors later")

	# Dying before the bonus chest moves it to floor 8 of the next run.
	game.bonus_chests.clear()
	game.bonus_chest_owed = true
	game.reset()
	_expect(game.has_chest(game.CARRYOVER_CHEST_FLOOR - 1), "owed chest waits on floor 8 next run")
	game._save()
	var meter: float = game.trap_meter
	game.queue_free()
	var again = load("res://scenes/main.tscn").instantiate()
	again.save_path = SAVE
	root.add_child(again)
	await process_frame
	_expect(again.bonus_chest_owed and again.has_chest(7), "owed chest survives closing the game")
	_expect(is_equal_approx(again.trap_meter, meter), "meter survives closing the game")

	# Chests picked up in a run wait for the end, then open one at a time.
	again.reset()
	again.chest_rng.seed = 5
	again.state = again.State.PLAYING
	again._save_chest()
	again._save_chest()
	_expect(again.pending_chests == 2 and again.state == again.State.PLAYING and not again.chest_screen.visible,
			"picking up chests saves them and the run carries on")
	var opened: int = again.stat("chests_opened")
	again._die("Test on floor %d", "lava")
	_expect(again.state == again.State.DEAD and not again.chest_screen.visible, "the death shows first")
	again._process(again.CHEST_OPEN_DELAY + 0.1)
	_expect(again.chest_screen.visible and again.pending_chests == 1, "then the first saved chest opens")
	_expect(again.chest_screen._title.text == "CHEST 1 OF 2", "the chest says which one it is")
	again._process(0.1)
	_expect(again.pending_chests == 1, "only one chest opens at a time")
	_tap(again.chest_screen)
	_expect(again.chest_screen.visible and again.pending_chests == 0 and again.chest_screen._title.text == "CHEST 2 OF 2",
			"the next chest opens straight after")
	_tap(again.chest_screen)
	_expect(not again.chest_screen.visible and again.state == again.State.DEAD and again.message_label.visible,
			"after the last chest the death message comes back")
	_expect(again.stat("chests_opened") == opened + 2, "both chests were opened")
	_expect(again.revive_button.visible, "the revive is still offered")
	# Chests saved when the game closes mid-run open next time.
	again.pending_chests = 1
	again._save()
	again.queue_free()
	var third = load("res://scenes/main.tscn").instantiate()
	third.save_path = SAVE
	root.add_child(third)
	await process_frame
	_expect(third.chest_screen.visible and third.pending_chests == 0, "chests saved before closing open on the next launch")
	third.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: chest odds, rewards, placement and granting")
	quit(1 if failures > 0 else 0)


## Skips the spin, then collects.
func _tap(screen) -> void:
	var tap := InputEventMouseButton.new()
	tap.pressed = true
	tap.button_index = MOUSE_BUTTON_LEFT
	screen._gui_input(tap)
	screen._gui_input(tap)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
