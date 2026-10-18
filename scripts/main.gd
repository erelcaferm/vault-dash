extends Node2D
## Vault Dash prototype: swipe to slide, climb the tower, outrun the lava.
## Everything is drawn with shapes so the prototype needs no art.

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Skins := preload("res://scripts/skins.gd")
const ShopScript := preload("res://scripts/shop.gd")
const Chest := preload("res://scripts/chest.gd")
const ChestScreen := preload("res://scripts/chest_screen.gd")
const Achievements := preload("res://scripts/achievements.gd")
const AchievementsScreen := preload("res://scripts/achievements_screen.gd")
const Sfx := preload("res://scripts/sfx.gd")

const TILE := 27
const SLIDE_SPEED := 24.0        # tiles per second while sliding
const SWIPE_MIN_DIST := 24.0     # pixels before a drag counts as a swipe
const LAVA_START_SPEED := 0.5    # tiles per second
const LAVA_ACCEL := 0.012        # extra tiles per second, gained each second
const LAVA_MAX_SPEED := 2.6
const LAVA_MAX_GAP := 11.0       # the lava never falls further behind than this
const RESTART_DELAY := 0.35
const SAVE_PATH := "user://save.cfg"
## The hidden trap meter: every trap floor you reach adds a random amount
## between these to it. When it fills, a bonus chest appears BONUS_CHEST_AHEAD
## floors later (BONUS_CHEST_PUSH more if that's already a chest floor). If you
## die first, the bonus chest waits on floor CARRYOVER_CHEST_FLOOR next run.
## The meter carries over between runs.
const TRAP_METER_MIN := 0.5
const TRAP_METER_MAX := 1.0
const TRAP_METER_FULL := 5.0
const BONUS_CHEST_AHEAD := 5
const BONUS_CHEST_PUSH := 10
const CARRYOVER_CHEST_FLOOR := 8
## Daily Climb: one tower per day, the same for every player. Reaching
## DAILY_GOAL in it pays DAILY_REWARD coins, once per day.
const DAILY_GOAL := 15
const DAILY_REWARD := 100
## One revive per run, paid in coins: the base cost plus a bit per floor.
## You go back to where your last slide started, with the lava pushed back.
const REVIVE_BASE_COST := 50
const REVIVE_COST_PER_FLOOR := 2
const REVIVE_LAVA_GAP := 8.0     # tiles between you and the lava after a revive
const REVIVE_GRACE := 1.5        # seconds the lava waits after a revive

enum State { READY, PLAYING, DEAD, WON, CHEST, PAUSED }

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
var bonus_chests := {}           # rooms with a bonus chest this run
var trap_meter := 0.0            # saved; see TRAP_METER_FULL
var bonus_chest_owed := false    # saved; a bonus chest you haven't opened yet
var meter_rng := RandomNumberGenerator.new()
var chest_return_state := State.PLAYING
var stats := {}                  # saved counters that achievements watch
var unlocked: Array = []         # saved ids of unlocked achievements
var achievements_screen: Control
var menu_bar: HBoxContainer
var banner: PanelContainer
var banner_label: Label
var banner_queue: Array = []
var banner_time := 0.0
var sfx: Node
var vibration_on := true         # saved, like sfx.enabled
var settings_bar: HBoxContainer
var sound_button: Button
var vibration_button: Button
var daily_mode := false
var daily_button: Button
var daily_date := ""             # saved; the day daily_best and daily_claimed are for
var daily_best := 0
var daily_claimed := false
var daily_last_played := ""      # saved; the last day a Daily Climb was started
var daily_streak := 0            # saved; days in a row with a Daily Climb
var revived := false            # whether this run's revive is used
var slide_start := Vector2i.ZERO # where the current or last slide began
var lava_grace := 0.0
var revive_button: Button
var pause_button: Button
var best_at_start := 0           # best floor before this run, for the "New best!" moment
var new_best_shown := false
var idle_time := 0.0             # seconds standing still, for the new-player hints
var marker_floor := 0            # the best to beat, drawn as a line on the tower
## For tests: pretends today is this date ("YYYY-MM-DD").
var test_today := ""


func _ready() -> void:
	sfx = Sfx.new()
	add_child(sfx)
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
	_refresh_daily()
	var seed_value := randi()
	if test_seed >= 0:
		seed_value = test_seed
	elif daily_mode:
		seed_value = daily_seed(daily_date)
	tower.build(Rooms.START, Rooms.LAYOUTS, seed_value)
	tower.room_limit = test_room_limit
	cell = tower.start
	slide_start = cell
	revived = false
	lava_grace = 0.0
	best_at_start = best_floor
	new_best_shown = false
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
	bonus_chests.clear()
	if bonus_chest_owed:
		bonus_chests[CARRYOVER_CHEST_FLOOR - 1] = true
	state = State.READY
	camera.position = _camera_target()
	camera.reset_smoothing()
	_update_hud()
	marker_floor = daily_best if daily_mode else best_floor
	daily_button.text = "ENDLESS" if daily_mode else "DAILY"
	if daily_mode:
		var goal := "Goal done! +%d coins" % DAILY_REWARD if daily_claimed else "Floor %d pays %d coins" % [DAILY_GOAL, DAILY_REWARD]
		var progress := ""
		if daily_best > 0:
			progress += "\nToday's best: floor %d" % daily_best
		if daily_streak > 0:
			progress += "\nStreak: %d day%s" % [daily_streak, "" if daily_streak == 1 else "s"]
		_show_message("DAILY CLIMB\n%s\n\nSame tower for everyone\ntoday.\n%s\n%s" % [_pretty_date(daily_date), goal, progress])
		return
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
		idle_time = idle_time + delta if is_idle() else 0.0
	if state == State.PLAYING:
		_update_lava(delta)
	shake = maxf(shake - delta, 0.0)
	squash = maxf(squash - delta, 0.0)
	toast_time = maxf(toast_time - delta, 0.0)
	toast_label.modulate.a = clampf(toast_time / 0.4, 0.0, 1.0)
	_update_banner(delta)
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
	slide_start = cell
	move_dir = d
	move_progress = 0.0
	sfx.play("swipe", randf_range(0.9, 1.1))


## Called each time the player finishes moving one tile.
func _advance() -> void:
	cell += move_dir
	var t: String = tower.get_tile(cell)
	if t == TowerScript.COIN:
		tower.set_tile(cell, TowerScript.EMPTY)
		run_coins += 1
		add_stat("coins_collected")
		sfx.play("coin", randf_range(0.97, 1.06))
		bursts.append({"pos": _tile_center(cell), "t": 0.0, "color": COIN_COLOR})
		_update_hud()
	elif t == TowerScript.SPIKES:
		_die("Spiked on floor %d", "spikes")
		return
	elif t == TowerScript.FAKE or t == TowerScript.FAKE_COIN:
		_die("Fell through a fake floor\non floor %d", "fake")
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
	if has_chest(k) and not chests_taken.has(k) and cell == tower.chest_cell(k):
		chests_taken[k] = true
		if bonus_chests.has(k):
			bonus_chest_owed = false
			add_stat("bonus_chests")
			_save()
		_stop()
		_open_chest()


func _stop() -> void:
	if move_dir != Vector2i.ZERO:
		sfx.play("stop")
	move_dir = Vector2i.ZERO
	move_progress = 0.0
	squash = 0.12


func _break_wall(c: Vector2i) -> void:
	tower.set_tile(c, TowerScript.EMPTY)
	add_stat("walls_broken")
	sfx.play("break")
	vibrate(25)
	bursts.append({"pos": _tile_center(c), "t": 0.0, "color": Color(_wall_skin().base, 1.0)})
	shake = 0.12


func _update_lava(delta: float) -> void:
	if lava_grace > 0.0:
		lava_grace -= delta
		return
	var speed := minf(LAVA_START_SPEED + LAVA_ACCEL * elapsed, LAVA_MAX_SPEED)
	lava_y -= speed * TILE * delta
	var player_y := _player_center().y
	lava_y = minf(lava_y, player_y + LAVA_MAX_GAP * TILE)
	if lava_y <= player_y:
		_die("Melted on floor %d", "lava")


func _update_floor() -> void:
	var f: int = tower.room_of(cell.y) + 1
	if f > run_floor:
		# A slide can carry you through more than one door at once.
		for passed in range(run_floor + 1, f + 1):
			if tower.is_trap(passed - 1):
				add_stat("trap_floors")
				add_trap_meter(passed, meter_rng.randf_range(TRAP_METER_MIN, TRAP_METER_MAX))
		run_floor = f
		if f > best_floor:
			best_floor = f
			check_achievements()
		if f > best_at_start and best_at_start > 0 and not new_best_shown and not daily_mode:
			new_best_shown = true
			_celebrate("NEW BEST!")
		if daily_mode:
			daily_best = maxi(daily_best, f)
			if f >= DAILY_GOAL and not daily_claimed:
				daily_claimed = true
				total_coins += DAILY_REWARD
				add_stat("daily_goals")
				banner_queue.append("DAILY GOAL!\nFloor %d reached\n+%d coins" % [DAILY_GOAL, DAILY_REWARD])
				_save()
		if f >= 20 and elapsed <= 60.0 and stat("fast_20") == 0:
			add_stat("fast_20")
		_update_hud()
		if tower.is_trap(f - 1):
			_toast("Floor %d\nWatch your step..." % f)
			sfx.play("trap")
	var biome := _biome_index(cell.y)
	if biome != last_biome:
		last_biome = biome
		_toast(BIOMES[biome].name)


func _die(reason: String, cause: String) -> void:
	state = State.DEAD
	add_stat("deaths")
	add_stat("deaths_" + cause)
	sfx.play("death")
	vibrate(150)
	state_time = 0.0
	move_dir = Vector2i.ZERO
	shake = 0.35
	_bank_run()
	var best := "Today's best: floor %d" % daily_best if daily_mode else "Best: floor %d" % best_floor
	_show_message("%s\n\n+%d coin%s\n%s\n\nSwipe to try again" % [reason % run_floor, run_coins, "" if run_coins == 1 else "s", best])
	_update_revive_button()


## A big toast with a sound and a shower of gold, for moments worth noticing.
func _celebrate(text: String) -> void:
	_toast(text)
	sfx.play("trophy")
	vibrate(30)
	for i in 8:
		var angle := TAU * i / 8.0
		bursts.append({"pos": _player_center() + Vector2.from_angle(angle) * TILE * 0.9, "t": 0.0, "color": COIN_COLOR})


func pause() -> void:
	if state != State.PLAYING:
		return
	# The slide is frozen, not stopped, so pausing can't be used to turn mid-slide.
	state = State.PAUSED
	pause_button.visible = false
	_show_message("PAUSED\n\nFloor %d   ● %d\n\nTap to carry on" % [run_floor, run_coins])
	# Only the settings show while paused; the shop and trophies wait for the menu.
	menu_bar.visible = false


func resume() -> void:
	if state != State.PAUSED:
		return
	state = State.PLAYING
	_hide_message()
	pause_button.visible = true


## Phones pause the game when you switch apps or get a call.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		pause()


func revive_cost() -> int:
	return snappedi(REVIVE_BASE_COST + run_floor * REVIVE_COST_PER_FLOOR, 10)


## Spends coins to carry on after dying, once per run. Coins from before the
## death are already banked, so the run's coin count starts again from 0.
func revive() -> bool:
	if state != State.DEAD or revived or total_coins < revive_cost():
		return false
	total_coins -= revive_cost()
	revived = true
	run_coins = 0
	add_stat("revives")
	cell = slide_start
	move_dir = Vector2i.ZERO
	queued_dir = Vector2i.ZERO
	lava_y = _player_center().y + REVIVE_LAVA_GAP * TILE
	lava_grace = REVIVE_GRACE
	state = State.PLAYING
	state_time = 0.0
	_hide_message()
	sfx.play("reward")
	vibrate(40)
	_toast("Second chance!")
	_save()
	_update_hud()
	return true


func _update_revive_button() -> void:
	revive_button.visible = state == State.DEAD and not revived
	revive_button.text = "REVIVE   ● %d" % revive_cost()
	revive_button.disabled = total_coins < revive_cost()


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
	check_achievements()
	_save()
	_update_hud()


# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if shop.visible or chest_screen.visible or achievements_screen.visible:
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
			KEY_ESCAPE, KEY_P:
				if state == State.PLAYING:
					pause()
				else:
					resume()
			KEY_SPACE, KEY_ENTER:
				_on_tap()
			KEY_F2:
				# Developer shortcut for trying the chest without climbing to the next chest.
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
			add_stat("runs")
			if daily_mode:
				_start_daily_run()
			_hide_message()
			try_move(d)
		State.PLAYING:
			try_move(d)
		State.DEAD, State.WON:
			if state_time >= RESTART_DELAY:
				reset()
		State.PAUSED:
			resume()


func _on_tap() -> void:
	if state == State.PAUSED:
		resume()
		return
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

	menu_bar = HBoxContainer.new()
	menu_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	menu_bar.offset_left = -165
	menu_bar.offset_right = 165
	menu_bar.offset_top = -110
	menu_bar.offset_bottom = -56
	menu_bar.add_theme_constant_override("separation", 10)
	hud.add_child(menu_bar)
	shop_button = _menu_button("SHOP", _open_shop)
	daily_button = _menu_button("DAILY", func():
		daily_mode = not daily_mode
		reset())
	_menu_button("TROPHIES", _open_achievements)

	pause_button = Button.new()
	pause_button.text = "II"
	pause_button.flat = true
	pause_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pause_button.offset_left = -24
	pause_button.offset_right = 24
	pause_button.offset_top = 4
	pause_button.offset_bottom = 44
	pause_button.add_theme_font_size_override("font_size", 22)
	pause_button.pressed.connect(pause)
	pause_button.visible = false
	hud.add_child(pause_button)

	revive_button = Button.new()
	revive_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	revive_button.offset_left = -110
	revive_button.offset_right = 110
	revive_button.offset_top = -178
	revive_button.offset_bottom = -124
	revive_button.add_theme_font_size_override("font_size", 20)
	revive_button.add_theme_color_override("font_color", Color("ffd23f"))
	var revive_style := StyleBoxFlat.new()
	revive_style.bg_color = Color(0.25, 0.16, 0.02, 0.92)
	revive_style.border_color = Color("ffd23f")
	revive_style.set_border_width_all(2)
	revive_style.set_corner_radius_all(8)
	revive_button.add_theme_stylebox_override("normal", revive_style)
	revive_button.add_theme_stylebox_override("hover", revive_style)
	revive_button.add_theme_stylebox_override("pressed", revive_style)
	revive_button.pressed.connect(revive)
	revive_button.visible = false
	hud.add_child(revive_button)

	settings_bar = HBoxContainer.new()
	settings_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	settings_bar.offset_left = -150
	settings_bar.offset_right = 150
	settings_bar.offset_top = -48
	settings_bar.offset_bottom = -12
	settings_bar.add_theme_constant_override("separation", 10)
	hud.add_child(settings_bar)
	sound_button = _small_button(settings_bar, func():
		sfx.enabled = not sfx.enabled
		sfx.play("coin")
		_update_settings())
	vibration_button = _small_button(settings_bar, func():
		vibration_on = not vibration_on
		vibrate(40)
		_update_settings())
	_update_settings()

	banner = PanelContainer.new()
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	banner_style.border_color = Color("ffd23f")
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(8)
	banner_style.set_content_margin_all(10)
	banner.add_theme_stylebox_override("panel", banner_style)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -150
	banner.offset_right = 150
	banner.offset_top = 64
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 17)
	banner.add_child(banner_label)
	banner.modulate.a = 0.0

	shop = ShopScript.new()
	hud.add_child(shop)
	shop.setup(self)
	shop.closed.connect(_close_shop)

	chest_screen = ChestScreen.new()
	hud.add_child(chest_screen)
	chest_screen.setup()
	chest_screen.finished.connect(_on_chest_finished)
	chest_screen.ticked.connect(func(): sfx.play("tick", randf_range(0.95, 1.05)))
	chest_screen.revealed.connect(func(_r): sfx.play("reward"); vibrate(50))

	achievements_screen = AchievementsScreen.new()
	hud.add_child(achievements_screen)
	achievements_screen.setup(self)
	achievements_screen.closed.connect(func(): achievements_screen.visible = false)
	# The banner goes on top of every other screen.
	hud.add_child(banner)
	chest_rng.randomize()
	meter_rng.randomize()


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
	for k in bonus_chests:
		if k + 1 >= run_floor and k + 1 < next and not chests_taken.has(k):
			next = k + 1
	chest_label.text = "Chest at floor %d" % next


func _show_message(text: String) -> void:
	pause_button.visible = false
	message_label.text = text
	message_label.visible = true
	message_backdrop.visible = true
	menu_bar.visible = true
	settings_bar.visible = true


func _hide_message() -> void:
	pause_button.visible = state == State.PLAYING
	message_label.visible = false
	message_backdrop.visible = false
	menu_bar.visible = false
	settings_bar.visible = false
	revive_button.visible = false


func _menu_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(action)
	menu_bar.add_child(b)
	return b


func _small_button(parent: Node, action: Callable) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 15)
	b.flat = true
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _update_settings() -> void:
	sound_button.text = "Sound: %s" % ("On" if sfx.enabled else "Off")
	vibration_button.text = "Vibration: %s" % ("On" if vibration_on else "Off")
	_save()


func vibrate(ms: int) -> void:
	if vibration_on:
		Input.vibrate_handheld(ms)


# --- Achievements ----------------------------------------------------------

## The current value of an achievement stat.
func stat(id: String) -> int:
	match id:
		"best_floor":
			return best_floor
		"daily_streak":
			return daily_streak
		"heroes_owned":
			var n := 0
			for item in Skins.HERO:
				if owns(item):
					n += 1
			return n
	return stats.get(id, 0)


func add_stat(id: String, amount := 1) -> void:
	stats[id] = stats.get(id, 0) + amount
	check_achievements()


func check_achievements() -> void:
	for a in Achievements.LIST:
		if not unlocked.has(a.id) and stat(a.stat) >= a.goal:
			_unlock(a)


func _unlock(a: Dictionary) -> void:
	unlocked.append(a.id)
	var reward := ""
	if a.has("coins"):
		total_coins += a.coins
		reward = "+%d coins" % a.coins
	else:
		var kind: String = a.item[0]
		var item := Skins.find(Skins.HERO if kind == "hero" else Skins.WALLS, a.item[1])
		if not owned.has(item.id):
			owned.append(item.id)
		reward = "New %s: %s" % ["colour" if kind == "hero" else "wall skin", item.name]
	banner_queue.append("TROPHY UNLOCKED\n%s\n%s" % [a.name, reward])
	_save()


func _update_banner(delta: float) -> void:
	if banner_time > 0.0:
		banner_time -= delta
		banner.modulate.a = clampf(minf(banner_time, 2.8 - banner_time) / 0.3, 0.0, 1.0)
	elif not banner_queue.is_empty():
		banner_label.text = banner_queue.pop_front()
		banner_time = 2.8
		sfx.play("trophy")
	else:
		banner.modulate.a = 0.0


func _open_achievements() -> void:
	achievements_screen.open()


# --- Daily Climb -----------------------------------------------------------

func today() -> String:
	return test_today if test_today != "" else Time.get_date_string_from_system()


## The tower seed for a date. String.hash is the same on every device, so
## every player climbs the same tower that day.
static func daily_seed(date: String) -> int:
	return ("vault-dash-daily-" + date).hash() & 0x7fffffff


## Starts a fresh daily best when the day has changed.
func _refresh_daily() -> void:
	if daily_date != today():
		daily_date = today()
		daily_best = 0
		daily_claimed = false


## Counts the day towards the daily stats and the streak, once per day.
func _start_daily_run() -> void:
	_refresh_daily()
	if daily_last_played == daily_date:
		return
	var yesterday := Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(daily_date) - 86400)
	daily_streak = daily_streak + 1 if daily_last_played == yesterday else 1
	daily_last_played = daily_date
	add_stat("daily_days")
	_save()


static func _pretty_date(date: String) -> String:
	const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var parts := date.split("-")
	if parts.size() != 3:
		return date
	return "%s %d" % [MONTHS[int(parts[1]) - 1], int(parts[2])]


# --- Chests ----------------------------------------------------------------

func has_chest(k: int) -> bool:
	return tower.is_chest_floor(k) or bonus_chests.has(k)


## Adds to the hidden trap meter for reaching trap floor `floor_number`. When
## it fills, books a bonus chest a few floors ahead and returns that floor
## number; otherwise returns 0.
func add_trap_meter(floor_number: int, amount: float) -> int:
	trap_meter += amount
	if trap_meter < TRAP_METER_FULL:
		_save()
		return 0
	trap_meter -= TRAP_METER_FULL
	var target := floor_number + BONUS_CHEST_AHEAD
	if tower.is_chest_floor(target - 1) or bonus_chests.has(target - 1):
		target += BONUS_CHEST_PUSH
	bonus_chests[target - 1] = true
	bonus_chest_owed = true
	_save()
	_update_hud()
	return target


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
	add_stat("chests_opened")
	if reward.rarity.id == "legendary":
		add_stat("legendaries")
	if chest_return_state == State.READY:
		reset()
	else:
		state = State.PLAYING
		pause_button.visible = true
		_update_hud()
	_toast("+ " + Chest.describe(reward))


## Chest coins go straight to the bank, so they're safe even if you die.
func grant(reward: Dictionary) -> void:
	if reward.kind == "coins":
		total_coins += reward.coins
	elif not owned.has(reward.item.id):
		owned.append(reward.item.id)
		equip(reward.kind, reward.item.id)
		check_achievements()
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
	if owns(item) or item.get("chest_only", false) or item.has("achievement") or total_coins < item.price:
		return false
	total_coins -= item.price
	owned.append(item.id)
	equip(kind, item.id)
	check_achievements()
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
		trap_meter = cfg.get_value("secret", "meter", 0.0)
		bonus_chest_owed = cfg.get_value("secret", "chest_owed", false)
		unlocked = cfg.get_value("achievements", "unlocked", [])
		sfx.enabled = cfg.get_value("settings", "sound", true)
		vibration_on = cfg.get_value("settings", "vibration", true)
		daily_date = cfg.get_value("daily", "date", "")
		daily_best = cfg.get_value("daily", "best", 0)
		daily_claimed = cfg.get_value("daily", "claimed", false)
		daily_last_played = cfg.get_value("daily", "last_played", "")
		daily_streak = cfg.get_value("daily", "streak", 0)
		if cfg.has_section("stats"):
			for key in cfg.get_section_keys("stats"):
				stats[key] = cfg.get_value("stats", key)
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
	cfg.set_value("secret", "meter", trap_meter)
	cfg.set_value("secret", "chest_owed", bonus_chest_owed)
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.set_value("settings", "sound", sfx.enabled)
	cfg.set_value("settings", "vibration", vibration_on)
	cfg.set_value("daily", "date", daily_date)
	cfg.set_value("daily", "best", daily_best)
	cfg.set_value("daily", "claimed", daily_claimed)
	cfg.set_value("daily", "last_played", daily_last_played)
	cfg.set_value("daily", "streak", daily_streak)
	for key in stats:
		cfg.set_value("stats", key, stats[key])
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
	_draw_best_marker(top, bottom)
	_draw_hints()
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
		if not has_chest(k) or chests_taken.has(k):
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


## Pulsing arrows round the player, for new players who stand still: one
## for each way they can slide from here.
const HINT_RUNS := 3
const HINT_DELAY := 1.2

func _draw_hints() -> void:
	if state != State.PLAYING or stat("runs") > HINT_RUNS or run_floor > 2 or idle_time < HINT_DELAY:
		return
	var p := _player_center()
	var pulse := 0.5 + 0.5 * sin(anim_time * 6.0)
	var alpha := clampf((idle_time - HINT_DELAY) / 0.4, 0.0, 1.0) * (0.5 + 0.5 * pulse)
	for d in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		if tower.get_tile(cell + d) == TowerScript.WALL:
			continue
		var dir := Vector2(d)
		var side := Vector2(-dir.y, dir.x)
		var tip := p + dir * TILE * (1.1 + 0.2 * pulse)
		var back := tip - dir * 9.0
		draw_polyline(PackedVector2Array([back + side * 8.0, tip, back - side * 8.0]), Color(1, 1, 1, alpha), 4.0)


## A dashed gold line across the door you need to pass to beat your best
## (today's best in the Daily Climb). It goes once you've beaten it.
func _draw_best_marker(top: float, bottom: float) -> void:
	if marker_floor < 2 or run_floor > marker_floor:
		return
	var y := -marker_floor * TowerScript.ROOM_H * TILE
	if y < top or y > bottom:
		return
	var width := tower.width * TILE
	var color := Color(COIN_COLOR, 0.65 + 0.25 * sin(anim_time * 3.0))
	var dash := 9.0
	var x := 0.0
	while x < width:
		draw_line(Vector2(x, y), Vector2(minf(x + dash, width), y), color, 3.0)
		x += dash * 2.0
	var label := "TODAY'S BEST %d" if daily_mode else "BEST %d"
	var font := ThemeDB.fallback_font
	var text := label % marker_floor
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var pos := Vector2(width - size.x - 6, y - 5)
	draw_rect(Rect2(pos - Vector2(4, size.y - 2), size + Vector2(8, 2)), Color(0, 0, 0, 0.6))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)


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
