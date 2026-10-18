extends Node2D
## Vault Dash prototype: swipe to slide, climb the tower, outrun the lava.
## Everything is drawn with shapes so the prototype needs no art.

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Skins := preload("res://scripts/skins.gd")
const ShopScript := preload("res://scripts/shop.gd")
const Chest := preload("res://scripts/chest.gd")
const ChestScreen := preload("res://scripts/chest_screen.gd")

const TILE := 27
const SLIDE_SPEED := 24.0        # tiles per second while sliding
const SWIPE_MIN_DIST := 24.0     # pixels before a drag counts as a swipe
const LAVA_START_SPEED := 0.5    # tiles per second
const LAVA_ACCEL := 0.012        # extra tiles per second, gained each second
const LAVA_MAX_SPEED := 2.6
const LAVA_MAX_GAP := 11.0       # the lava never falls further behind than this
const RESTART_DELAY := 0.35
const SAVE_PATH := "user://save.cfg"

enum State { READY, PLAYING, DEAD, WON, CHEST }

# One biome per five rooms. Swapping these colours is the seed of the
# environment cosmetics.
const BIOMES := [
	{"name": "The Crypt", "bg": Color("1d2030"), "wall": Color("4a5068"), "edge": Color("7a82a3")},
	{"name": "Ice Caves", "bg": Color("0f2236"), "wall": Color("2f6f99"), "edge": Color("9fdcf7")},
	{"name": "Jungle Temple", "bg": Color("132519"), "wall": Color("3d6638"), "edge": Color("8fc275")},
]
const COIN_COLOR := Color("ffd23f")
const SPIKE_COLOR := Color("e84855")
const LAVA_COLOR := Color("ff5a1f")
const LAVA_GLOW := Color("ffb347")

var tower: TowerScript
var state := State.READY
var cell := Vector2i.ZERO
var move_dir := Vector2i.ZERO
var move_progress := 0.0
var queued_dir := Vector2i.ZERO
var lava_y := 0.0
var elapsed := 0.0
var state_time := 0.0
var anim_time := 0.0
var shake := 0.0
var squash := 0.0
var run_coins := 0
var run_floor := 1
var last_biome := 0
var bursts: Array = []           # short-lived pops from coins and cracked walls

## Tests set these to build a fixed tower with an exit at the given room.
var test_seed := -1
var test_room_limit := -1
## Tests point this elsewhere so they never touch the player's real save.
var save_path := SAVE_PATH

var total_coins := 0
var best_floor := 0
var best_time := 0.0
var owned: Array = []            # ids of shop items bought (free ones aren't listed)
var equipped_hero := "white"
var equipped_wall := "rubble"
var rainbow_phase := 0.0

var touch_start := Vector2.ZERO
var touch_active := false
var swipe_used := false

var camera: Camera2D
var coins_label: Label
var floor_label: Label
var message_label: Label
var message_backdrop: ColorRect
var toast_label: Label
var toast_time := 0.0
var shop: Control
var shop_button: Button
var chest_label: Label
var chest_screen: Control
var chest_rng := RandomNumberGenerator.new()
var chests_taken := {}           # rooms whose chest was opened this run
var chest_return_state := State.PLAYING


func _ready() -> void:
	_load_save()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()
	_build_hud()
	reset()


func reset() -> void:
	tower = TowerScript.new()
	tower.build(Rooms.START, Rooms.LAYOUTS, test_seed if test_seed >= 0 else randi())
	tower.room_limit = test_room_limit
	cell = tower.start
	move_dir = Vector2i.ZERO
	move_progress = 0.0
	queued_dir = Vector2i.ZERO
	lava_y = (tower.start.y + 6) * TILE
	elapsed = 0.0
	state_time = 0.0
	run_coins = 0
	run_floor = 1
	last_biome = 0
	bursts.clear()
	chests_taken.clear()
	state = State.READY
	camera.position = _camera_target()
	camera.reset_smoothing()
	_update_hud()
	var best := ""
	if best_floor > 0:
		best = "\n\nBest floor: %d\nCoins banked: %d" % [best_floor, total_coins]
	_show_message("VAULT DASH\n\nSwipe to slide.\nClimb as high as you can\nbefore the lava gets you.%s" % best)


# --- Game loop -------------------------------------------------------------

func _process(delta: float) -> void:
	anim_time += delta
	var moving := move_dir != Vector2i.ZERO
	rainbow_phase += delta * (Skins.RAINBOW_SLIDE_SPEED if moving else Skins.RAINBOW_IDLE_SPEED)
	state_time += delta
	if state == State.PLAYING:
		elapsed += delta
		_update_slide(delta)
	if state == State.PLAYING:
		_update_lava(delta)
	shake = maxf(shake - delta, 0.0)
	squash = maxf(squash - delta, 0.0)
	toast_time = maxf(toast_time - delta, 0.0)
	toast_label.modulate.a = clampf(toast_time / 0.4, 0.0, 1.0)
	for b in bursts:
		b.t += delta
	bursts = bursts.filter(func(b): return b.t < 0.35)
	_update_camera()
	queue_redraw()


func _update_slide(delta: float) -> void:
	if move_dir == Vector2i.ZERO:
		if queued_dir != Vector2i.ZERO:
			var d := queued_dir
			queued_dir = Vector2i.ZERO
			_start_move(d)
		return
	move_progress += SLIDE_SPEED * delta
	while move_progress >= 1.0 and move_dir != Vector2i.ZERO and state == State.PLAYING:
		move_progress -= 1.0
		_advance()


func _start_move(d: Vector2i) -> void:
	var t: String = tower.get_tile(cell + d)
	if t == TowerScript.WALL:
		return
	if t == TowerScript.CRACKED:
		_break_wall(cell + d)
		return
	move_dir = d
	move_progress = 0.0


## Called each time the player finishes moving one tile.
func _advance() -> void:
	cell += move_dir
	var t: String = tower.get_tile(cell)
	if t == TowerScript.COIN:
		tower.set_tile(cell, TowerScript.EMPTY)
		run_coins += 1
		bursts.append({"pos": _tile_center(cell), "t": 0.0, "color": COIN_COLOR})
		_update_hud()
	elif t == TowerScript.SPIKES:
		_die("Spiked on floor %d")
		return
	elif t == TowerScript.FAKE or t == TowerScript.FAKE_COIN:
		_die("Fell through a fake floor\non floor %d")
		return
	elif t == TowerScript.GOAL:
		_win()
		return
	_update_floor()
	var ahead: String = tower.get_tile(cell + move_dir)
	if ahead == TowerScript.WALL:
		_stop()
	elif ahead == TowerScript.CRACKED:
		_break_wall(cell + move_dir)
		_stop()
	var k := tower.room_of(cell.y)
	if tower.is_chest_floor(k) and not chests_taken.has(k) and cell == tower.chest_cell(k):
		chests_taken[k] = true
		_stop()
		_open_chest()


func _stop() -> void:
	move_dir = Vector2i.ZERO
	move_progress = 0.0
	squash = 0.12


func _break_wall(c: Vector2i) -> void:
	tower.set_tile(c, TowerScript.EMPTY)
	bursts.append({"pos": _tile_center(c), "t": 0.0, "color": Color(_wall_skin().base, 1.0)})
	shake = 0.12


func _update_lava(delta: float) -> void:
	var speed := minf(LAVA_START_SPEED + LAVA_ACCEL * elapsed, LAVA_MAX_SPEED)
	lava_y -= speed * TILE * delta
	var player_y := _player_center().y
	lava_y = minf(lava_y, player_y + LAVA_MAX_GAP * TILE)
	if lava_y <= player_y:
		_die("Melted on floor %d")


func _update_floor() -> void:
	var f: int = tower.room_of(cell.y) + 1
	if f > run_floor:
		run_floor = f
		_update_hud()
		if tower.is_trap(f - 1):
			_toast("Floor %d\nWatch your step..." % f)
	var biome := _biome_index(cell.y)
	if biome != last_biome:
		last_biome = biome
		_toast(BIOMES[biome].name)


func _die(reason: String) -> void:
	state = State.DEAD
	state_time = 0.0
	move_dir = Vector2i.ZERO
	shake = 0.35
	_bank_run()
	_show_message("%s\n\n+%d coins\nBest: floor %d\n\nSwipe to try again" % [reason % run_floor, run_coins, best_floor])


## Only reachable when a test gives the tower an exit.
func _win() -> void:
	state = State.WON
	state_time = 0.0
	move_dir = Vector2i.ZERO
	if best_time == 0.0 or elapsed < best_time:
		best_time = elapsed
	_bank_run()
	_show_message("YOU ESCAPED!\n\n%.1f seconds   +%d coins\nBest time: %.1f s\n\nSwipe to climb again" % [elapsed, run_coins, best_time])


func _bank_run() -> void:
	total_coins += run_coins
	best_floor = maxi(best_floor, run_floor)
	_save()
	_update_hud()


# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if shop.visible or chest_screen.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_active = true
			swipe_used = false
		else:
			if touch_active and not swipe_used:
				var d: Vector2 = event.position - touch_start
				if d.length() >= SWIPE_MIN_DIST:
					_on_swipe(_dir_from(d))
				else:
					_on_tap()
			touch_active = false
	elif event is InputEventScreenDrag:
		# Fire as soon as the finger has moved far enough, not on release.
		if touch_active and not swipe_used:
			var d: Vector2 = event.position - touch_start
			if d.length() >= SWIPE_MIN_DIST:
				swipe_used = true
				_on_swipe(_dir_from(d))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				_on_swipe(Vector2i.UP)
			KEY_DOWN, KEY_S:
				_on_swipe(Vector2i.DOWN)
			KEY_LEFT, KEY_A:
				_on_swipe(Vector2i.LEFT)
			KEY_RIGHT, KEY_D:
				_on_swipe(Vector2i.RIGHT)
			KEY_SPACE, KEY_ENTER:
				_on_tap()
			KEY_F2:
				# Developer shortcut for trying the chest without climbing 100 floors.
				if OS.is_debug_build() and (state == State.READY or state == State.PLAYING):
					_open_chest()


func _dir_from(d: Vector2) -> Vector2i:
	if absf(d.x) > absf(d.y):
		return Vector2i.RIGHT if d.x > 0 else Vector2i.LEFT
	return Vector2i.DOWN if d.y > 0 else Vector2i.UP


func _on_swipe(d: Vector2i) -> void:
	match state:
		State.READY:
			state = State.PLAYING
			_hide_message()
			try_move(d)
		State.PLAYING:
			try_move(d)
		State.DEAD, State.WON:
			if state_time >= RESTART_DELAY:
				reset()


func _on_tap() -> void:
	if (state == State.DEAD or state == State.WON) and state_time >= RESTART_DELAY:
		reset()


## A swipe made mid-slide is remembered and used when the slide ends.
func try_move(d: Vector2i) -> void:
	if move_dir != Vector2i.ZERO:
		queued_dir = d
	else:
		_start_move(d)


func is_idle() -> bool:
	return move_dir == Vector2i.ZERO and queued_dir == Vector2i.ZERO


# --- Camera and HUD --------------------------------------------------------

func _camera_target() -> Vector2:
	# Keep the player a little below centre so you see more of what's above.
	return Vector2(tower.width * TILE * 0.5, _player_center().y - TILE * 2)


func _update_camera() -> void:
	camera.position = _camera_target()
	if shake > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 24.0
	else:
		camera.offset = Vector2.ZERO


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	coins_label = _make_label(hud, 22, HORIZONTAL_ALIGNMENT_LEFT)
	coins_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	coins_label.offset_left = 14
	coins_label.offset_top = 10
	floor_label = _make_label(hud, 22, HORIZONTAL_ALIGNMENT_RIGHT)
	floor_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	floor_label.offset_right = -14
	floor_label.offset_top = 10
	chest_label = _make_label(hud, 15, HORIZONTAL_ALIGNMENT_RIGHT)
	chest_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	chest_label.offset_right = -14
	chest_label.offset_top = 40
	chest_label.add_theme_color_override("font_color", Color("ffd23f"))
	message_backdrop = ColorRect.new()
	message_backdrop.color = Color(0, 0, 0, 0.55)
	message_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(message_backdrop)
	message_label = _make_label(hud, 24, HORIZONTAL_ALIGNMENT_CENTER)
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.offset_left = 24
	message_label.offset_right = -24
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label = _make_label(hud, 28, HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 70
	toast_label.modulate.a = 0.0

	shop_button = Button.new()
	shop_button.text = "SHOP"
	shop_button.add_theme_font_size_override("font_size", 22)
	shop_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	shop_button.offset_left = -80
	shop_button.offset_right = 80
	shop_button.offset_top = -110
	shop_button.offset_bottom = -56
	shop_button.pressed.connect(_open_shop)
	hud.add_child(shop_button)

	shop = ShopScript.new()
	hud.add_child(shop)
	shop.setup(self)
	shop.closed.connect(_close_shop)

	chest_screen = ChestScreen.new()
	hud.add_child(chest_screen)
	chest_screen.setup()
	chest_screen.finished.connect(_on_chest_finished)
	chest_rng.randomize()


func _make_label(parent: Node, size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _update_hud() -> void:
	coins_label.text = "● %d" % run_coins
	floor_label.text = "Floor %d" % run_floor
	var every := TowerScript.CHEST_EVERY
	var next := ceili(float(run_floor) / every) * every
	if chests_taken.has(next - 1):
		next += every
	chest_label.text = "Chest at floor %d" % next


func _show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_backdrop.visible = true
	shop_button.visible = true


func _hide_message() -> void:
	message_label.visible = false
	message_backdrop.visible = false
	shop_button.visible = false


# --- Chests ----------------------------------------------------------------

func _open_chest() -> void:
	chest_return_state = state
	state = State.CHEST
	move_dir = Vector2i.ZERO
	queued_dir = Vector2i.ZERO
	_hide_message()
	var reward := Chest.roll(chest_rng, owns)
	chest_screen.open(reward, chest_rng)


func _on_chest_finished(reward: Dictionary) -> void:
	grant(reward)
	if chest_return_state == State.READY:
		reset()
	else:
		state = State.PLAYING
		_update_hud()
	_toast("+ " + Chest.describe(reward))


## Chest coins go straight to the bank, so they're safe even if you die.
func grant(reward: Dictionary) -> void:
	if reward.kind == "coins":
		total_coins += reward.coins
	elif not owned.has(reward.item.id):
		owned.append(reward.item.id)
		equip(reward.kind, reward.item.id)
	_save()


# --- Shop ------------------------------------------------------------------

func _open_shop() -> void:
	shop.open()


func _close_shop() -> void:
	shop.visible = false
	if state == State.READY:
		reset()    # refreshes the title screen's coin count


func owns(item: Dictionary) -> bool:
	return item.price == 0 or owned.has(item.id)


func buy(kind: String, item: Dictionary) -> bool:
	if owns(item) or item.get("chest_only", false) or total_coins < item.price:
		return false
	total_coins -= item.price
	owned.append(item.id)
	equip(kind, item.id)
	return true


func equip(kind: String, id: String) -> void:
	if kind == "hero":
		equipped_hero = id
	else:
		equipped_wall = id
	_save()


func _hero_skin() -> Dictionary:
	return Skins.find(Skins.HERO, equipped_hero)


func _wall_skin() -> Dictionary:
	return Skins.find(Skins.WALLS, equipped_wall)


func _toast(text: String) -> void:
	toast_label.text = text
	toast_time = 1.6


# --- Save ------------------------------------------------------------------

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		total_coins = cfg.get_value("progress", "total_coins", 0)
		best_floor = cfg.get_value("progress", "best_floor", 0)
		best_time = cfg.get_value("progress", "best_time", 0.0)
		owned = cfg.get_value("shop", "owned", [])
		equipped_hero = cfg.get_value("shop", "hero", "white")
		equipped_wall = cfg.get_value("shop", "wall", "rubble")


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_coins", total_coins)
	cfg.set_value("progress", "best_floor", best_floor)
	cfg.set_value("progress", "best_time", best_time)
	cfg.set_value("shop", "owned", owned)
	cfg.set_value("shop", "hero", equipped_hero)
	cfg.set_value("shop", "wall", equipped_wall)
	cfg.save(save_path)


# --- Drawing ---------------------------------------------------------------

func _tile_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TILE


func _player_center() -> Vector2:
	return _tile_center(cell) + Vector2(move_dir) * move_progress * TILE


func _biome_index(row: int) -> int:
	return posmod(floori(maxi(tower.room_of(row), 0) / 5.0), BIOMES.size())


func _draw() -> void:
	var view := get_viewport_rect().size
	var center := camera.get_screen_center_position()
	var top := center.y - view.y * 0.5 - TILE
	var bottom := center.y + view.y * 0.5 + TILE
	var y0 := floori(top / TILE)
	var y1 := ceili(bottom / TILE)

	for y in range(y0, y1 + 1):
		var biome: Dictionary = BIOMES[_biome_index(y)]
		draw_rect(Rect2(-view.x, y * TILE, view.x * 3, TILE), biome.bg.darkened(0.35))
		draw_rect(Rect2(0, y * TILE, tower.width * TILE, TILE), biome.bg)
		for x in tower.width:
			_draw_tile(Vector2i(x, y), biome)

	_draw_chests(y0, y1)
	_draw_player()
	for b in bursts:
		var k: float = b.t / 0.35
		draw_arc(b.pos, 6.0 + k * 18.0, 0, TAU, 20, Color(b.color, 1.0 - k), 3.0)
	_draw_lava(view)


func _draw_tile(c: Vector2i, biome: Dictionary) -> void:
	var t: String = tower.get_tile(c)
	var r := Rect2(Vector2(c) * TILE, Vector2(TILE, TILE))
	var mid := r.get_center()
	match t:
		TowerScript.WALL:
			draw_rect(r, biome.wall)
			draw_rect(Rect2(r.position, Vector2(TILE, 4)), biome.edge)
		TowerScript.COIN, TowerScript.FAKE_COIN:
			var bob := sin(anim_time * 4.0 + c.y * 0.7) * 2.0
			draw_circle(mid + Vector2(0, bob), 6.0, COIN_COLOR)
			draw_circle(mid + Vector2(-1.5, bob - 1.5), 2.5, COIN_COLOR.lightened(0.6))
		TowerScript.SPIKES:
			var w := (TILE - 4) / 3.0
			for i in 3:
				var bx := r.position.x + 2 + i * w
				draw_colored_polygon(PackedVector2Array([
					Vector2(bx, r.end.y - 3), Vector2(bx + w * 0.5, r.position.y + TILE * 0.25), Vector2(bx + w, r.end.y - 3),
				]), SPIKE_COLOR)
		TowerScript.CRACKED:
			Skins.draw_cracked(self, r, _wall_skin(), anim_time)
		TowerScript.GOAL:
			var pulse := 0.5 + 0.5 * sin(anim_time * 5.0)
			draw_circle(mid, 12.0 + pulse * 4.0, Color(COIN_COLOR, 0.35))
			draw_circle(mid, 9.0, COIN_COLOR)
			draw_circle(mid, 4.0, Color.WHITE)


func _draw_player() -> void:
	var p := _player_center()
	var size := Vector2(TILE - 6, TILE - 6)
	if move_dir.x != 0:
		size *= Vector2(1.2, 0.82)
	elif move_dir.y != 0:
		size *= Vector2(0.82, 1.2)
	elif squash > 0.0:
		size *= Vector2(1.15, 0.88)
	var color := Skins.hero_color(_hero_skin(), rainbow_phase)
	# Speed trail
	if move_dir != Vector2i.ZERO:
		for i in range(3, 0, -1):
			var ghost := p - Vector2(move_dir) * TILE * 0.4 * i
			Skins.draw_hero(self, ghost, size, color, Vector2.ZERO, 0.12 * (4 - i))
	# Eyes look where you're going.
	var look := Vector2(move_dir if move_dir != Vector2i.ZERO else queued_dir) * 3.0
	Skins.draw_hero(self, p, size, color, look, 1.0, Skins.hero_glow(_hero_skin()))


func _draw_chests(y0: int, y1: int) -> void:
	for k in range(maxi(tower.room_of(y1), 0), tower.room_of(y0) + 1):
		if not tower.is_chest_floor(k) or chests_taken.has(k):
			continue
		var mid := _tile_center(tower.chest_cell(k)) + Vector2(0, sin(anim_time * 3.0) * 2.0)
		var w := TILE * 0.9
		var h := TILE * 0.7
		var glow := 0.5 + 0.5 * sin(anim_time * 4.0)
		draw_circle(mid, TILE * (0.8 + glow * 0.15), Color(1, 0.85, 0.25, 0.18))
		var body := Rect2(mid - Vector2(w, h) * 0.5 + Vector2(0, h * 0.1), Vector2(w, h * 0.8))
		draw_rect(body, Color("7a4a22"))
		draw_rect(Rect2(body.position - Vector2(1, h * 0.25), Vector2(w + 2, h * 0.35)), Color("9c5f2c"))
		draw_rect(Rect2(body.position.x, body.position.y - h * 0.25, w, h * 1.05), Color("ffd23f"), false, 2.0)
		draw_rect(Rect2(mid.x - 2.5, mid.y - h * 0.15, 5, 7), Color("ffd23f"))


func _draw_lava(view: Vector2) -> void:
	var left := -view.x
	var right := tower.width * TILE + view.x
	var points := PackedVector2Array()
	var steps := 40
	for i in steps + 1:
		var x := lerpf(left, right, float(i) / steps)
		points.append(Vector2(x, lava_y + sin(x * 0.045 + anim_time * 3.0) * 5.0))
	var glow := points.duplicate()
	points.append(Vector2(right, lava_y + view.y * 2))
	points.append(Vector2(left, lava_y + view.y * 2))
	draw_colored_polygon(points, LAVA_COLOR)
	draw_polyline(glow, LAVA_GLOW, 4.0)
