extends SceneTree
## Checks the daily gift calendar and the daily shop deal.
## Run: godot --headless --path . --script res://tests/test_gift.gd

const SAVE := "user://test_gift_save.cfg"
const DailyGift := preload("res://scripts/daily_gift.gd")
const Skins := preload("res://scripts/skins.gd")

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	game.test_today = "2026-10-20"
	root.add_child(game)
	await process_frame
	await process_frame

	# Daily gift.
	_expect(not game.daily_gift.visible, "no gift before the first run")
	game.stats["runs"] = 1
	await process_frame
	_expect(game.daily_gift.visible, "the gift shows on the title screen")
	var before: int = game.total_coins
	game.daily_gift._on_claim()
	_expect(game.total_coins == before + DailyGift.GIFTS[0].coins, "day 1 pays its coins")
	_expect(game.gift_day == 1 and not game.gift_ready(), "one gift a day")
	await process_frame
	_expect(not game.daily_gift.visible, "the gift doesn't come back the same day")
	game.test_today = "2026-10-25"    # days missed don't reset it
	_expect(game.gift_ready(), "a new day brings a new gift")
	game.gift_day = 6
	var chests: int = game.pending_chests
	game._claim_gift(DailyGift.GIFTS[6])
	_expect(game.state == game.State.CHEST and game.gift_day == 0, "day 7 opens a chest and the strip starts again")
	game.chest_screen._reveal()
	game.chest_screen.finished.emit(game.chest_screen._reward)
	_expect(game.pending_chests == chests and game.state == game.State.READY, "the gift chest is opened, back to the title")

	# Daily deal.
	game.test_today = "2026-10-21"
	var d: Array = game.deal()
	_expect(not d.is_empty() and d[1].price > 0 and not game.owns(d[1]), "a deal is an unowned shop item")
	var item: Dictionary = d[1]
	_expect(game.price(item) < item.price, "the deal is cheaper")
	_expect(game.deal()[1].id == item.id, "the deal stays the same all day")
	game.total_coins = game.price(item)
	_expect(game.buy(d[0], item) and game.total_coins == 0, "buying the deal costs the deal price")
	_expect(game.deal().is_empty(), "a bought deal is gone for the day")
	game.test_today = "2026-10-22"
	_expect(not game.deal().is_empty() and game.deal()[1].id != item.id, "a new deal the next day")

	# The preview shows any item you tap, and the deal button jumps to the deal.
	var deal_item: Array = game.deal()
	game.shop.open()
	game.shop._show_tab("hero")
	var other := Skins.find(Skins.HERO, "rainbow" if deal_item[1].id != "rainbow" else "gold")
	game.shop._on_card(other)
	_expect(game.shop._look.trying.get("hero", {}).get("id", "") == other.id, "tapping an item previews it")
	game.shop._deal_button.pressed.emit()
	_expect(game.shop.tab == deal_item[0] and game.shop._look.trying[deal_item[0]].id == deal_item[1].id, "the deal button shows the deal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if failures == 0:
		print("PASS: daily gift and daily deal")
	quit(1 if failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
