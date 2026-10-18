extends SceneTree
## Checks the rewarded-ad buttons (which pay out straight away until an ad
## network is added): free revive, double coins, shop coins, and no ads on Steam.
## Run: godot --headless --path . --script res://tests/test_ads.gd

const SAVE := "user://test_ads_save.cfg"
const Ads := preload("res://scripts/ads.gd")

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
	game.run_coins = 20
	var safe: Vector2i = game.cell
	game.slide_start = safe
	game.cell = safe + Vector2i.UP
	game._die("Test on floor %d", "spikes")
	game.check_achievements()
	_expect(game.ad_revive_button.visible and game.ad_double_button.visible, "both ad buttons show after dying")
	var before: int = game.total_coins
	_expect(game.ad_double_coins(), "watching an ad doubles the run's coins")
	_expect(game.total_coins == before + 20, "the run's coins are paid again")
	_expect(not game.ad_double_coins() and not game.ad_double_button.visible, "coins double once per run")
	before = game.total_coins
	_expect(game.ad_revive(), "an ad revive works with no coins")
	_expect(game.state == game.State.PLAYING and game.cell == safe, "the ad revive brings you back")
	game.check_achievements()
	_expect(game.total_coins >= before, "the ad revive costs nothing")
	game._die("Test on floor %d", "lava")
	_expect(not game.ad_revive_button.visible and not game.ad_revive(), "still only one revive per run")

	game.ad_coins_day = ""
	_expect(game.ad_coins_left() == Ads.SHOP_PER_DAY, "shop coin ads reset each day")
	before = game.total_coins
	for i in Ads.SHOP_PER_DAY:
		game.ad_shop_coins()
	_expect(game.total_coins == before + Ads.SHOP_COINS * Ads.SHOP_PER_DAY, "each shop ad pays coins")
	_expect(not game.ad_shop_coins() and game.ad_coins_left() == 0, "shop ads stop at the daily limit")

	var ads := Ads.new()
	var forced := 0
	for i in Ads.INTERSTITIAL_EVERY * 2:
		forced += int(ads.after_run())
	_expect(forced == 2, "a forced ad every few runs")
	ads.purchase_completed()
	for i in Ads.INTERSTITIAL_EVERY * 2:
		_expect(not ads.after_run(), "no forced ads after a real-money purchase")
	ads.enabled = false    # what the "steam" feature tag does
	_expect(not ads.can_show_rewarded(), "Steam builds show no ads")
	game.ads.enabled = false
	game.reset()
	game._die("Test on floor %d", "spikes")
	_expect(not game.ad_bar.visible, "no ad buttons when ads are off")
	_expect(game.ad_coins_left() == 0 and not game.ad_shop_coins(), "no shop ads when ads are off")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: rewarded ads, limits and Steam switch")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
