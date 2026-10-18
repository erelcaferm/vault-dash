extends SceneTree
## Checks power-ups: where they appear, and what shield, magnet and freeze do.
## Run: godot --headless --path . --script res://tests/test_powerups.gd

const TowerScript := preload("res://scripts/tower.gd")
const SAVE := "user://test_powerups_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_seed = 5
	root.add_child(game)
	await process_frame

	game._roll_powerups(200)
	var floors := {}
	for c: Vector2i in game.powerups:
		var k: int = game.tower.room_of(c.y)
		_expect(k + 1 >= game.POWERUP_FROM_FLOOR, "no power-ups on the first floors")
		_expect(not floors.has(k), "at most one power-up per floor")
		floors[k] = true
		_expect(game.tower.get_tile(c) == TowerScript.EMPTY, "a power-up replaces a coin")
	var share := floors.size() / 197.0
	_expect(share > 0.18 and share < 0.42, "about %d%% of floors have one (got %d%%)" % [game.POWERUP_CHANCE * 100, share * 100])
	var first: Dictionary = game.powerups.duplicate()
	game.reset()
	game._roll_powerups(200)
	_expect(game.powerups == first, "the same tower gets the same power-ups")

	game.reset()
	game._on_swipe(Vector2i.UP)
	game.move_dir = Vector2i.ZERO
	game.queued_dir = Vector2i.ZERO
	var safe: Vector2i = game.cell

	# Shield: saves you once.
	game.give_powerup("shield")
	game.slide_start = safe
	game.cell = safe + Vector2i.UP
	game._die("Spiked on floor %d", "spikes")
	_expect(game.state == game.State.PLAYING and game.cell == safe and not game.shield, "the shield saves you and goes back to safety")
	game._die("Spiked on floor %d", "spikes")
	_expect(game.state == game.State.DEAD, "the shield only works once")

	# Freeze: the lava stops.
	game.reset()
	game._on_swipe(Vector2i.UP)
	game.move_dir = Vector2i.ZERO
	game.queued_dir = Vector2i.ZERO
	game.give_powerup("freeze")
	var lava: float = game.lava_y
	for i in 60:
		await process_frame
	_expect(game.lava_y == lava, "frozen lava doesn't move")
	game.freeze_time = 0.0
	for i in 10:
		await process_frame
	_expect(game.lava_y < lava, "the lava moves again after the freeze")

	# Magnet: pulls in coins close by, not far away.
	var near: Vector2i = game.cell + Vector2i(2, 0)
	var far: Vector2i = game.cell + Vector2i(0, -5)
	game.tower.set_tile(near, TowerScript.COIN)
	game.tower.set_tile(far, TowerScript.COIN)
	var coins: int = game.run_coins
	game.give_powerup("magnet")
	await process_frame
	await process_frame
	_expect(game.tower.get_tile(near) == TowerScript.EMPTY and game.run_coins > coins, "the magnet collects nearby coins")
	_expect(game.tower.get_tile(far) == TowerScript.COIN, "the magnet has a limited range")
	_expect(game.stat("powerups") == 3, "power-ups are counted")
	game.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: power-up placement, shield, freeze and magnet")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
