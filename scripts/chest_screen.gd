extends Control
## The chest opening: a strip of prizes spins past a marker, slows down and
## lands on the reward. Tap while it spins to skip; tap again to carry on.

signal finished(reward: Dictionary)
signal ticked                    # a card passed the marker
signal revealed(reward: Dictionary)

const Chest := preload("res://scripts/chest.gd")
const Preview := preload("res://scripts/skin_preview.gd")

const CARD_W := 96.0
const CARD_H := 124.0
const GAP := 6.0
const CARD_COUNT := 48
const WINNER := 40               # the reward sits this far along the strip
const SPIN_TIME := 5.5

var _reward: Dictionary
var _window: Control
var _strip: Control
var _marker: ColorRect
var _title: Label
var _result: Label
var _hint: Label
var _tween: Tween
var _final_x := 0.0
var _revealed := false
var _last_card := -1
var _tick := 0.0


func setup() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.06, 0.94)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	_title = _label("TREASURE CHEST", 30, Color("ffd23f"))
	_title.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	_title.offset_top = 120
	add_child(_title)

	_window = Control.new()
	_window.clip_contents = true
	_window.mouse_filter = MOUSE_FILTER_IGNORE
	_window.set_anchors_preset(PRESET_CENTER)
	add_child(_window)
	var frame := ColorRect.new()
	frame.color = Color(1, 1, 1, 0.06)
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_window.add_child(frame)
	_strip = Control.new()
	_strip.mouse_filter = MOUSE_FILTER_IGNORE
	_window.add_child(_strip)
	_marker = ColorRect.new()
	_marker.color = Color("ffd23f")
	_marker.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_marker)

	_result = _label("", 26)
	_result.set_anchors_and_offsets_preset(PRESET_CENTER)
	_result.offset_left = -170
	_result.offset_right = 170
	_result.offset_top = CARD_H * 0.5 + 30
	_result.offset_bottom = CARD_H * 0.5 + 110
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result)
	_hint = _label("Tap to skip", 18, Color(1, 1, 1, 0.6))
	_hint.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	_hint.offset_top = -120
	_hint.offset_bottom = -80
	add_child(_hint)
	visible = false


## Shows the chest and spins to `reward`. `rng` fills the strip with decoys.
func open(reward: Dictionary, rng: RandomNumberGenerator) -> void:
	_reward = reward
	_revealed = false
	_last_card = -1
	visible = true
	_result.text = ""
	_hint.text = "Tap to skip"

	var width := minf(get_viewport_rect().size.x - 24.0, 420.0)
	_window.offset_left = -width * 0.5
	_window.offset_right = width * 0.5
	_window.offset_top = -CARD_H * 0.5 - 8
	_window.offset_bottom = CARD_H * 0.5 + 8
	var center := get_viewport_rect().size * 0.5
	_marker.position = Vector2(center.x - 1.5, center.y - CARD_H * 0.5 - 18)
	_marker.size = Vector2(3, CARD_H + 36)

	for c in _strip.get_children():
		c.queue_free()
	var nothing_owned := func(_item): return false
	for i in CARD_COUNT:
		var r: Dictionary = reward if i == WINNER else Chest.roll(rng, nothing_owned)
		var card := _card(r)
		card.position = Vector2(i * (CARD_W + GAP), 8)
		_strip.add_child(card)

	# Land somewhere inside the winning card, not always dead centre.
	var jitter := rng.randf_range(-0.35, 0.35) * CARD_W
	_final_x = width * 0.5 - (WINNER * (CARD_W + GAP) + CARD_W * 0.5) + jitter
	_strip.position.x = width * 0.5 - CARD_W * 0.5
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_strip, "position:x", _final_x, SPIN_TIME) \
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(_reveal)


func is_spinning() -> bool:
	return visible and not _revealed


func _process(delta: float) -> void:
	if not visible:
		return
	# Flash the marker each time a new card passes under it.
	var under := floori((_window.size.x * 0.5 - _strip.position.x) / (CARD_W + GAP))
	if under != _last_card:
		_last_card = under
		_tick = 1.0
		if not _revealed:
			ticked.emit()
	_tick = maxf(_tick - delta * 6.0, 0.0)
	_marker.color = Color("ffd23f").lerp(Color.WHITE, _tick)
	_marker.scale = Vector2(1.0 + _tick, 1.0)


func _reveal() -> void:
	if _revealed:
		return
	_revealed = true
	if _tween:
		_tween.kill()
	_strip.position.x = _final_x
	var rarity: Dictionary = _reward.rarity
	_result.text = "%s\n%s" % [tr(rarity.name).to_upper(), Chest.describe(_reward)]
	_result.add_theme_color_override("font_color", rarity.color)
	_hint.text = "Tap to continue"
	revealed.emit(_reward)
	var winner: Control = _strip.get_child(WINNER)
	winner.pivot_offset = winner.size * 0.5
	var pop := create_tween()
	pop.tween_property(winner, "scale", Vector2(1.12, 1.12), 0.15)
	pop.tween_property(winner, "scale", Vector2.ONE, 0.2)


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
	if not tapped:
		return
	accept_event()
	if not _revealed:
		_reveal()
	else:
		visible = false
		finished.emit(_reward)


func _card(reward: Dictionary) -> Control:
	var card := Panel.new()
	card.size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c1c26")
	style.border_color = reward.rarity.color
	style.border_width_bottom = 8
	style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", style)
	# A soft wash of the rarity colour from the bottom.
	var wash := ColorRect.new()
	wash.color = Color(reward.rarity.color, 0.18)
	wash.position = Vector2(0, CARD_H * 0.5)
	wash.size = Vector2(CARD_W, CARD_H * 0.5)
	wash.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(wash)
	var preview := Preview.new()
	preview.kind = reward.kind
	preview.item = reward.item
	preview.position = Vector2(8, 6)
	preview.size = Vector2(CARD_W - 16, CARD_H - 50)
	preview.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(preview)
	var caption := "+%d" % reward.coins if reward.kind == "coins" else String(reward.item.name)
	var label := _label(caption, 15)
	label.position = Vector2(0, CARD_H - 42)
	label.size = Vector2(CARD_W, 26)
	card.add_child(label)
	return card


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
