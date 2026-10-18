extends SceneTree
## Checks that the trophies and shop lists scroll when a drag starts on a
## card or row, and that a drag doesn't press the card it started on.
## Run: godot --headless --path . --script res://tests/test_scroll.gd

const SAVE := "user://test_scroll_save.cfg"

var failures := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame

	game._open_achievements()
	await _settle()
	var trophies: ScrollContainer = game.achievements_screen.find_children("*", "ScrollContainer", true, false)[0]
	await _drag(trophies)
	_expect(trophies.scroll_vertical > 50, "dragging on a trophy row scrolls the list (got %d)" % trophies.scroll_vertical)
	game.achievements_screen.closed.emit()

	game.total_coins = 100000
	game._open_shop()
	game.shop._show_tab("hero")
	await _settle()
	var shop_scroll: ScrollContainer = game.shop._scroll
	var hero_before: String = game.equipped_hero
	var coins_before: int = game.total_coins
	await _drag(shop_scroll)
	_expect(shop_scroll.scroll_vertical > 50, "dragging on a shop card scrolls the shop (got %d)" % shop_scroll.scroll_vertical)
	_expect(game.equipped_hero == hero_before and game.total_coins == coins_before, "a drag doesn't buy or equip the card under the finger")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures == 0:
		print("PASS: trophies and shop scroll from anywhere")
	quit(1 if failures > 0 else 0)


func _settle() -> void:
	for i in 4:
		await process_frame


## A finger drag upwards that starts in the middle of the list.
func _drag(scroll: ScrollContainer) -> void:
	var r := scroll.get_global_rect()
	var at := Vector2(r.position.x + r.size.x * 0.3, r.position.y + r.size.y * 0.75)
	# Events arrive in window pixels; the game is drawn scaled to the window.
	var to_window := root.get_final_transform()
	var t := InputEventScreenTouch.new()
	t.position = to_window * at
	t.pressed = true
	Input.parse_input_event(t)
	await process_frame
	for k in 12:
		var d := InputEventScreenDrag.new()
		d.relative = to_window.basis_xform(Vector2(0, -15))
		at += Vector2(0, -15)
		d.position = to_window * at
		Input.parse_input_event(d)
		await process_frame
	t = InputEventScreenTouch.new()
	t.position = to_window * at
	t.pressed = false
	Input.parse_input_event(t)
	await _settle()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		printerr("FAIL: ", what)
		failures += 1
