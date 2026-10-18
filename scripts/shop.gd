extends Control
## The coin shop: hero colours, hats, cracked-wall skins, slide trails and lava.
## Coins, owned items and what's equipped live in main.gd, which saves them.

signal closed

const Skins := preload("res://scripts/skins.gd")
const Preview := preload("res://scripts/skin_preview.gd")
const Achievements := preload("res://scripts/achievements.gd")
const PillStyle := preload("res://scripts/pill_style.gd")
const LookPreview := preload("res://scripts/look_preview.gd")

const GOLD := Color("ffd23f")
const DIM := Color(1, 1, 1, 0.5)

var game
var tab := "hero"
var pending_buy := ""            # the item waiting for a second tap to confirm
var _coins_label: Label
var _scroll: ScrollContainer
var _grid: GridContainer
var _tab_buttons := {}
var _ad_button: Button
var _deal_button: Button
var _offers: HBoxContainer
var _look: Control               # try-on window
var _look_label: Label


func setup(main_game) -> void:
	game = main_game
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("SHOP", 28)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_coins_label = _label("", 24, GOLD)
	header.add_child(_coins_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 5)
	column.add_child(tabs)
	for t in [["hero", "Hero"], ["hat", "Hats"], ["walls", "Walls"], ["trail", "Trails"], ["lava", "Lava"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_show_tab.bind(t[0]))
		var dot := Panel.new()       # shown while the tab has NEW items
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = Color("ff4d4d")
		dot_style.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", dot_style)
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		dot.set_anchors_preset(PRESET_TOP_RIGHT)
		dot.offset_left = -12
		dot.offset_right = -2
		dot.offset_top = 2
		dot.offset_bottom = 12
		b.add_child(dot)
		tabs.add_child(b)
		_tab_buttons[t[0]] = b

	_look = LookPreview.new()
	_look.game = game
	_look.clip_contents = true
	_look.custom_minimum_size.y = 96
	_look.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(_look)
	_look_label = _label("", 13, Color(1, 1, 1, 0.75))
	_look_label.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	_look_label.offset_top = 4
	_look.add_child(_look_label)

	# One pill: watch an ad for coins | today's deal.
	_offers = HBoxContainer.new()
	_offers.add_theme_constant_override("separation", 0)
	_offers.custom_minimum_size.y = 40
	column.add_child(_offers)
	_ad_button = _offer_button(Color(0.23, 0.66, 0.34, 0.75))
	_ad_button.pressed.connect(func():
		if game.ad_shop_coins():
			_refresh())
	_deal_button = _offer_button(Color(0.85, 0.6, 0.1, 0.75))
	_deal_button.pressed.connect(func():
		var d: Array = game.deal()
		if d.is_empty():
			return
		_show_tab(d[0])
		_look.trying[d[0]] = d[1]
		_scroll_to(d[1])
		_refresh())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 52
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func():
		_look.trying.clear()
		_mark_tab_seen()
		closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	pending_buy = ""
	_look.trying.clear()
	visible = true
	# Start on a tab with something new in it.
	for t in _tab_buttons:
		if _has_new(t):
			tab = t
			break
	_show_tab(tab)


func _show_tab(t: String) -> void:
	if t != tab:
		_mark_tab_seen()
		_scroll.scroll_vertical = 0
	tab = t
	pending_buy = ""
	_refresh()


func _refresh() -> void:
	_coins_label.text = "● %d" % game.total_coins
	var tried: Array = _look.trying.values()
	_look_label.text = tr("Preview: %s") % tr(tried[0].name) if tried.size() == 1 \
			else (tr("Your look") if tried.is_empty() else tr("Preview: %d items") % tried.size())
	var left: int = game.ad_coins_left()
	_ad_button.visible = game.ads.can_show_rewarded()
	_ad_button.disabled = left <= 0
	_ad_button.text = tr("AD: +%d coins (%d)") % [game.Ads.SHOP_COINS, left] if left > 0 else tr("No more ads today")
	var d: Array = game.deal()
	_deal_button.visible = not d.is_empty()
	if not d.is_empty():
		_deal_button.text = tr("DEAL: %s -%d%%") % [tr(d[1].name), roundi(game.DEAL_OFF * 100)]
	_offers.visible = _ad_button.visible or _deal_button.visible
	game._style_bar(_offers)
	for b: Button in _offers.get_children():
		var label := Label.new()
		label.text = b.text
		label.add_theme_font_size_override("font_size", 14)
		game.fit_font(label, (size.x - 28.0) / maxf(_offers.get_children().filter(func(c): return c.visible).size(), 1) - 20.0, 9)
		b.add_theme_font_size_override("font_size", label.get_theme_font_size("font_size"))
		label.free()
	var keep := _scroll.scroll_vertical
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for k in _tab_buttons:
		var b: Button = _tab_buttons[k]
		b.set_pressed_no_signal(k == tab)
		b.get_child(0).visible = _has_new(k) and k != tab
	var items: Array = Skins.list(tab)
	for item in items:
		_grid.add_child(_card(item))
	_scroll.set_deferred("scroll_vertical", keep)


func _card(item: Dictionary) -> Button:
	var equipped: String = {"hero": game.equipped_hero, "hat": game.equipped_hat, "walls": game.equipped_wall, "trail": game.equipped_trail, "lava": game.equipped_lava}[tab]
	var owned: bool = game.owns(item)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 132)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	if item.id == equipped:
		var ring := StyleBoxFlat.new()
		ring.bg_color = Color(1, 1, 1, 0.08)
		ring.border_color = GOLD
		ring.set_border_width_all(3)
		ring.set_corner_radius_all(6)
		for state in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, ring)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	box.offset_top = 6
	box.offset_bottom = -6
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	b.add_child(box)
	var preview := Preview.new()
	preview.item = item
	preview.kind = tab
	preview.hero = game._hero_skin()
	preview.size_flags_vertical = SIZE_EXPAND_FILL
	preview.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(preview)
	var name_label := _label(item.name, 16)
	game.fit_font(name_label, 100, 11)
	box.add_child(name_label)

	var status: Label
	if item.id == equipped:
		status = _label("Equipped", 14, GOLD)
	elif owned:
		status = _label("Tap to use", 14, DIM)
	elif item.get("chest_only", false):
		status = _label("Chest only", 14, Color("ffd700"))
	elif item.has("achievement"):
		status = _label(Achievements.find(item.achievement).get("name", "Achievement"), 13, Color("7fd6ff"))
	elif item.has("level"):
		status = _label(tr("Level %d") % item.level, 13, Color("7fd6ff"))
	elif item.has("pet"):
		status = _label(tr("%s Lv %d") % [tr(game.Pets.find(item.pet).name), item.pet_level], 13, Color("ffa8d9"))
	elif pending_buy == item.id:
		status = _label("Tap to buy!", 14, GOLD)
	elif game.price(item) < item.price:
		status = _label("● %d  -%d%%" % [game.price(item), roundi(game.DEAL_OFF * 100)], 14, Color("ffb347") if game.total_coins >= game.price(item) else DIM)
	elif game.total_coins >= item.price:
		status = _label("● %d" % item.price, 15, GOLD)
	else:
		status = _label("● %d" % item.price, 15, DIM)
	game.fit_font(status, 100, 10)
	box.add_child(status)
	if game.new_items.has(item.id):
		var badge := _label("NEW", 12, Color.WHITE)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color("e8382f")
		badge_style.set_corner_radius_all(4)
		badge_style.content_margin_left = 5
		badge_style.content_margin_right = 5
		badge.add_theme_stylebox_override("normal", badge_style)
		badge.position = Vector2(4, 4)
		b.add_child(badge)
	b.pressed.connect(_on_card.bind(item))
	return b


func _on_card(item: Dictionary) -> void:
	if game.owns(item):
		game.equip(tab, item.id)
		pending_buy = ""
	elif item.get("chest_only", false) or item.has("achievement") or item.has("level") or item.has("pet"):
		pending_buy = ""
	elif pending_buy == item.id:
		game.buy(tab, item)
		pending_buy = ""
	elif game.total_coins >= game.price(item):
		pending_buy = item.id
	else:
		pending_buy = ""
		game.sfx.play("error")
	# Tapping an item you don't own shows it on your hero in the window above.
	if game.owns(item):
		_look.trying.erase(tab)
	else:
		_look.trying[tab] = item
	_refresh()


func _offer_button(color: Color) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 14)
	for key in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(key, PillStyle.new(color if key != "disabled" else Color(0.3, 0.3, 0.34, 0.6), key == "pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	_offers.add_child(b)
	return b


## Scrolls the grid so `item`'s card is in view.
func _scroll_to(item: Dictionary) -> void:
	var i: int = Skins.list(tab).find(item)
	if i < 0:
		return
	await get_tree().process_frame
	var card: Control = _grid.get_child(i)
	_scroll.scroll_vertical = int(card.position.y)


func _has_new(t: String) -> bool:
	for item in Skins.list(t):
		if game.new_items.has(item.id):
			return true
	return false


## Leaving a tab counts as having seen its new items.
func _mark_tab_seen() -> void:
	for item in Skins.list(tab):
		game.seen(item.id)
	game._save()


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
