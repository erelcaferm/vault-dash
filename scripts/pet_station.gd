extends Control
## The pet station: hatch eggs, feed your pets the food you find in levels,
## level them up for their cosmetic lines, and pick which one follows you.

signal closed

const Pets := preload("res://scripts/pets.gd")
const Skins := preload("res://scripts/skins.gd")
const PillStyle := preload("res://scripts/pill_style.gd")

const GOLD := Color("ffd23f")
const DIM := Color(1, 1, 1, 0.55)
const KIND_NAMES := {2: "hat", 3: "trail", 4: "hero skin", 5: "walls"}

var game
var _coins: Label
var _egg: Control
var _egg_button: Button
var _list: VBoxContainer
var _scroll: ScrollContainer
var _hatching := 0.0              # counts down while the egg wobbles and cracks
var _hatched := {}                # the pet that just came out
var _shown := 0.0                 # how much longer to show it
var _time := 0.0


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
	var title := _label("PETS", 28)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_coins = _label("", 24, GOLD)
	header.add_child(_coins)

	# The egg, with the hatch button under it.
	var egg_row := HBoxContainer.new()
	egg_row.add_theme_constant_override("separation", 10)
	column.add_child(egg_row)
	_egg = Control.new()
	_egg.custom_minimum_size = Vector2(84, 84)
	_egg.mouse_filter = MOUSE_FILTER_IGNORE
	_egg.draw.connect(_draw_egg)
	egg_row.add_child(_egg)
	var egg_side := VBoxContainer.new()
	egg_side.size_flags_horizontal = SIZE_EXPAND_FILL
	egg_side.alignment = BoxContainer.ALIGNMENT_CENTER
	egg_row.add_child(egg_side)
	var hint := _label("Eggs hatch straight away. Feed pets the food you find in levels to unlock their outfits.", 12, DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	egg_side.add_child(hint)
	_egg_button = _pill(egg_side, Color(0.85, 0.6, 0.1, 0.85), _hatch)
	_egg_button.custom_minimum_size.y = 42

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 52
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	visible = true
	_hatching = 0.0
	_hatched = {}
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _hatching > 0.0:
		_hatching = maxf(_hatching - delta, 0.0)
		if _hatching == 0.0:
			game.sfx.play("reward")
			game.vibrate(60)
			_shown = 2.5
			_refresh()
	elif _shown > 0.0:
		# The "You hatched..." line goes back to the hatch button after a moment.
		_shown = maxf(_shown - delta, 0.0)
		if _shown == 0.0:
			_hatched = {}
			_refresh()
	_egg.queue_redraw()
	for card in _list.get_children():
		if card.has_meta("pet_view"):
			card.get_meta("pet_view").queue_redraw()


func _hatch() -> void:
	if _hatching > 0.0 or _shown > 0.0:
		return
	var pet: Dictionary = game.hatch_egg()
	if pet.is_empty():
		game.sfx.play("error")
		return
	_hatched = pet
	_hatching = 1.2
	game.sfx.play("buy")
	_refresh()


func _refresh() -> void:
	_coins.text = "● %d" % game.total_coins
	var left: Array = game.pets_left_to_hatch()
	if left.is_empty():
		_egg_button.text = tr("Every pet hatched!")
		_egg_button.disabled = true
	else:
		var price: int = game.egg_price()
		_egg_button.text = tr("HATCH AN EGG") + "   " + (tr("FREE") if price == 0 else "● %d" % price)
		_egg_button.disabled = game.total_coins < price
	if _hatching == 0.0 and not _hatched.is_empty():
		_egg_button.text = tr("You hatched %s!") % tr(_hatched.name)
	var keep := _scroll.scroll_vertical
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	# A pet still in its egg stays a mystery until it hatches.
	var revealed := func(p): return game.pets.has(p.id) and not (_hatching > 0.0 and p.id == _hatched.get("id", ""))
	for pet in Pets.LIST:
		if revealed.call(pet):
			_list.add_child(_pet_card(pet))
	for pet in Pets.LIST:
		if not revealed.call(pet):
			_list.add_child(_locked_card())
	_scroll.set_deferred("scroll_vertical", keep)


func _pet_card(pet: Dictionary) -> Control:
	var info: Dictionary = game.pets[pet.id]
	var equipped: bool = game.equipped_pet == pet.id
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.07)
	style.border_color = GOLD if equipped else Color(1, 1, 1, 0.1)
	style.set_border_width_all(2 if equipped else 1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var view := Control.new()
	view.custom_minimum_size = Vector2(64, 64)
	view.mouse_filter = MOUSE_FILTER_IGNORE
	view.draw.connect(func(): Pets.draw_pet(view, pet, view.size * 0.5 + Vector2(0, 4), 34.0, _time, Vector2.RIGHT))
	row.add_child(view)
	panel.set_meta("pet_view", view)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	row.add_child(mid)
	var name_label := _label("%s   %s" % [tr(pet.name), tr("Lv %d") % info.level], 17, GOLD if equipped else Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mid.add_child(name_label)
	var food: int = game.pet_food.get(pet.food, 0)
	var need: int = Pets.feeds_to_next(info.level)
	var progress := ""
	if need > 0:
		progress = tr("Fed %d / %d") % [info.fed, need]
		var next: Dictionary = _reward_at(pet.id, info.level + 1)
		if not next.is_empty():
			progress += "  ·  " + tr("Next: %s") % tr(next.name)
	else:
		progress = tr("Max level: whole outfit unlocked")
	var p := _label(progress, 12, DIM)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(p)
	var food_label := _label(tr("%s: %d  (find it in levels while %s follows you)") % [tr(pet.food_name), food, tr(pet.name)], 12, Color("ffa8d9"))
	food_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	food_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(food_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 0)
	buttons.custom_minimum_size.y = 34
	mid.add_child(buttons)
	var feed := _pill(buttons, Color(0.23, 0.66, 0.34, 0.8), func():
		var lv: int = game.feed_pet(pet.id)
		if lv > 0:
			game.sfx.play("reward")
			var got: Dictionary = _reward_at(pet.id, lv)
			if not got.is_empty():
				game._toast(tr("%s reached level %d!") % [tr(pet.name), lv] + "\n" + tr("New: %s") % tr(got.name))
		elif lv == 0:
			game.sfx.play("buy")
		else:
			game.sfx.play("error")
		_refresh())
	feed.text = tr("FEED")
	feed.disabled = need == 0 or food <= 0
	feed.add_theme_font_size_override("font_size", 14)
	var wear := _pill(buttons, Color(0.24, 0.25, 0.29, 0.8), func():
		game.equipped_pet = "" if game.equipped_pet == pet.id else pet.id
		game._save()
		_refresh())
	wear.text = tr("PUT AWAY") if equipped else tr("TAKE ALONG")
	wear.add_theme_font_size_override("font_size", 14)
	game._style_bar(buttons)
	return panel


func _locked_card() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.03)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(_label("? ? ?   " + tr("Hatch an egg to meet this pet"), 13, Color(1, 1, 1, 0.3)))
	return panel


## The cosmetic a pet gives at `level`, or {}.
func _reward_at(id: String, level: int) -> Dictionary:
	for kind in ["hero", "hat", "walls", "trail", "lava"]:
		for item in Skins.list(kind):
			if item.get("pet", "") == id and item.pet_level == level:
				return item
	return {}


func _draw_egg() -> void:
	var c := _egg.size * 0.5
	if _hatching == 0.0 and not _hatched.is_empty():
		Pets.draw_pet(_egg, _hatched, c + Vector2(0, 6), 44.0, _time, Vector2.RIGHT)
		_egg.draw_colored_polygon(_egg_half(c, false), Color(1, 1, 1, 0.25))
		return
	var wobble := sin(_time * 30.0) * 0.18 * (_hatching / 1.2) if _hatching > 0.0 else sin(_time * 2.0) * 0.05
	_egg.draw_set_transform(c + Vector2(0, 30), wobble, Vector2.ONE)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 26.0, -30.0 + sin(a) * (34.0 if sin(a) < 0 else 28.0)))
	_egg.draw_colored_polygon(pts, Color("fff3d6"))
	for spot in [Vector2(-10, -42), Vector2(9, -26), Vector2(-4, -14)]:
		_egg.draw_circle(spot, 5.0, Color("ffb3c6"))
	if _hatching > 0.0 and _hatching < 0.7:
		_egg.draw_polyline(PackedVector2Array([Vector2(-24, -32), Vector2(-12, -38), Vector2(-2, -28), Vector2(10, -38), Vector2(24, -30)]), Color("6b4a2e"), 2.0)
	_egg.draw_set_transform(Vector2.ZERO)


func _egg_half(c: Vector2, _top: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(c + Vector2(cos(a) * 26.0, 18.0 + sin(a) * 16.0))
	return pts


func _pill(parent: Control, color: Color, action: Callable) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 16)
	for key in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(key, PillStyle.new(color if key != "disabled" else Color(0.3, 0.3, 0.34, 0.5), key == "pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
