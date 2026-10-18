extends Control
## Crack the Vault: a quick timing minigame. A needle sweeps round the dial;
## tap while it's over the glowing mark to click that tumbler into place.
## Each click speeds the needle up, flips its direction and shrinks the next
## mark. Three clicks open the vault. One free try a day, more for an ad.
## Coins are kept small so it's a treat, not a farm.

signal closed

const PillStyle := preload("res://scripts/pill_style.gd")

const TUMBLERS := 3
const START_SPEED := 1.7          # radians per second
const SPEED_UP := 1.4
const START_WIDTH := 0.42         # radians of mark the needle can be in
const WIDTH_SHRINK := 0.8
## Coins for 0, 1, 2 and 3 tumblers.
const PRIZES := [0, 10, 25, 60]
const FREE_PER_DAY := 1
const AD_PER_DAY := 2
const GOLD := Color("ffd23f")

var game
var playing := false
var angle := 0.0
var speed := START_SPEED
var target := 0.0
var width := START_WIDTH
var locked: Array = []            # angles of tumblers already clicked
var result := -1                  # tumblers clicked in the last try, -1 before any
var _flash := 0.0
var _dial: Control
var _status: Label
var _play: Button
var _ad: Button
var rng := RandomNumberGenerator.new()


func setup(main_game) -> void:
	game = main_game
	rng.randomize()
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
	column.add_child(_label("CRACK THE VAULT", 28, GOLD))
	column.add_child(_label("Tap when the needle is on the glowing mark.", 14, Color(1, 1, 1, 0.65)))
	_dial = Control.new()
	_dial.size_flags_vertical = SIZE_EXPAND_FILL
	_dial.mouse_filter = MOUSE_FILTER_IGNORE
	_dial.draw.connect(_draw_dial)
	column.add_child(_dial)
	_status = _label("", 20)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.custom_minimum_size.y = 50
	column.add_child(row)
	_play = _button(row, Color(0.85, 0.6, 0.1, 0.85), _start)
	_ad = _button(row, Color(0.23, 0.66, 0.34, 0.8), func():
		if game.vault_ad_left() > 0:
			game.ads.show_rewarded("vault", func():
				game.vault_use_ad()
				_start()))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 52
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func():
		playing = false
		closed.emit())
	column.add_child(back)
	visible = false


func open() -> void:
	visible = true
	playing = false
	result = -1
	locked.clear()
	_refresh()


func _start() -> void:
	if playing:
		return
	if not game.vault_take_try():
		_refresh()
		return
	playing = true
	locked.clear()
	result = -1
	speed = START_SPEED
	width = START_WIDTH
	angle = -PI * 0.5
	_new_target()
	_refresh()


func _new_target() -> void:
	# Somewhere well away from the needle, so there's time to react.
	var away := rng.randf_range(PI * 0.6, PI * 1.6) * signf(speed)
	target = wrapf(angle + away, -PI, PI)


func _process(delta: float) -> void:
	if not visible:
		return
	_flash = maxf(_flash - delta * 3.0, 0.0)
	if playing:
		angle = wrapf(angle + speed * delta, -PI, PI)
	_dial.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
	if tapped and playing:
		accept_event()
		tap()


## A tap while playing: clicks the tumbler if the needle is on the mark,
## otherwise the try ends. Returns whether it clicked.
func tap() -> bool:
	if not playing:
		return false
	if absf(angle_difference(angle, target)) <= width * 0.5:
		locked.append(target)
		game.sfx.play("tick", 1.0 + locked.size() * 0.15)
		game.vibrate(30)
		_flash = 1.0
		if locked.size() >= TUMBLERS:
			_finish()
		else:
			speed = -speed * SPEED_UP
			width *= WIDTH_SHRINK
			_new_target()
		_refresh()
		return true
	game.sfx.play("error")
	_finish()
	return false


func _finish() -> void:
	playing = false
	result = locked.size()
	var prize: int = PRIZES[result]
	if prize > 0:
		game.total_coins += prize
		game.sfx.play("reward" if result == TUMBLERS else "buy")
	if result == TUMBLERS:
		game.add_stat("vaults_cracked")
	game._save()
	_refresh()


func _refresh() -> void:
	var free: int = game.vault_free_left()
	var ads: int = game.vault_ad_left()
	if playing:
		_status.text = tr("Tumblers: %d / %d") % [locked.size(), TUMBLERS]
	elif result == TUMBLERS:
		_status.text = tr("VAULT OPEN!") + "  " + tr("+%d coins") % PRIZES[result]
	elif result > 0:
		_status.text = tr("%d of 3 tumblers.") % result + "  " + tr("+%d coins") % PRIZES[result]
	elif result == 0:
		_status.text = tr("Missed! The vault stays shut.")
	else:
		_status.text = tr("Open all three for %d coins.") % PRIZES[TUMBLERS]
	_status.add_theme_color_override("font_color", GOLD if result == TUMBLERS else Color.WHITE)
	_play.visible = not playing and free > 0
	_play.text = tr("PLAY (%d left today)") % free
	_ad.visible = not playing and free <= 0 and ads > 0
	_ad.text = tr("AD: play again (%d)") % ads
	if not playing and free <= 0 and ads <= 0:
		_status.text += "\n" + tr("Come back tomorrow for another try.")
	game._style_bar(_play.get_parent())


func _draw_dial() -> void:
	var c := _dial.size * 0.5
	var r := minf(_dial.size.x, _dial.size.y) * 0.42
	# The vault door.
	_dial.draw_circle(c, r * 1.12, Color(0.18, 0.18, 0.22))
	_dial.draw_circle(c, r * 1.04, Color(0.3, 0.31, 0.36))
	_dial.draw_circle(c, r, Color(0.13, 0.13, 0.17))
	for i in 24:
		var a := TAU * i / 24.0
		var d := Vector2.from_angle(a)
		_dial.draw_line(c + d * r * 0.9, c + d * r * (0.97 if i % 2 == 0 else 0.94), Color(1, 1, 1, 0.3), 1.5)
	# Clicked tumblers, then the mark to hit.
	for a in locked:
		_dial.draw_arc(c, r * 0.8, a - 0.12, a + 0.12, 8, GOLD, r * 0.12)
	if playing:
		var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.012)
		_dial.draw_arc(c, r * 0.8, target - width * 0.5, target + width * 0.5, 16, Color(0.3, 1.0, 0.45, 0.35 * pulse), r * 0.2)
		_dial.draw_arc(c, r * 0.8, target - width * 0.5, target + width * 0.5, 16, Color(0.3, 1.0, 0.45, pulse), r * 0.1)
	# Locking bolts round the edge open up as tumblers click.
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		var out := r * (1.12 + 0.08 * (locked.size() / float(TUMBLERS)) * float(result == TUMBLERS))
		_dial.draw_circle(c + Vector2.from_angle(a) * out, r * 0.06, Color(0.55, 0.56, 0.62))
	# The needle and the hub.
	var tip := c + Vector2.from_angle(angle) * r * 0.86
	_dial.draw_line(c, tip, Color(1, 1, 1, 0.95), 4.0)
	_dial.draw_circle(c, r * 0.16, Color(0.45, 0.46, 0.52).lerp(GOLD, _flash))
	_dial.draw_circle(c, r * 0.07, Color(0.13, 0.13, 0.17))


func _button(row: HBoxContainer, color: Color, action: Callable) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	for key in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(key, PillStyle.new(color, key == "pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	b.pressed.connect(action)
	row.add_child(b)
	return b


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label
