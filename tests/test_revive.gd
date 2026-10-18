extends SceneTree
## Checks the coin revive: its cost, once per run, and where you come back.
## Run: godot --headless --path . --script res://tests/test_revive.gd

const SAVE := "user://test_revive_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_seed = 3
	root.add_child(game)
	await process_frame

	game.total_coins = 0
	game._on_swipe(Vector2i.UP)
	game.run_floor = 10
	game.run_coins = 7
	var safe: Vector2i = game.cell
	game.slide_start = safe
	game.cell = safe + Vector2i.UP
	game._die("Test on floor %d", "spikes")
	_expect(game.revive_cost() == 70, "the revive costs 50 plus 2 a floor")
	_expect(game.revive_button.visible and game.revive_button.disabled, "the revive button shows, greyed out, when you can't afford it")
	_expect(not game.revive(), "you can't revive without the coins")

	game.check_achievements()    # settles trophies earned by the death itself
	game.total_coins = 500
	game._update_revive_button()
	_expect(not game.revive_button.disabled, "the revive button works once you can afford it")
	_expect(game.revive(), "reviving works with enough coins")
	_expect(game.total_coins == 500 - 70 + 25, "reviving takes the cost (and Second Wind pays 25)")
	_expect(game.state == game.State.PLAYING and game.cell == safe, "you come back where your last slide started")
	_expect(game.lava_y > game._player_center().y + 7 * game.TILE, "the lava is pushed back")
	_expect(game.run_coins == 0, "coins from before the death stay banked, not counted twice")
	_expect(game.unlocked.has("second_wind"), "reviving unlocks Second Wind")

	game._die("Test on floor %d", "lava")
	_expect(not game.revive_button.visible and not game.revive(), "only one revive per run")
	game.reset()
	_expect(not game.revived, "a new run gets its revive back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: revive cost, once per run, and safe return")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
