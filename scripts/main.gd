extends Node2D
## Vault Dash prototype: swipe to slide, climb the tower, outrun the lava.
## Everything is drawn with shapes so the prototype needs no art.

const TowerScript := preload("res://scripts/tower.gd")
const Rooms := preload("res://scripts/rooms.gd")
const Skins := preload("res://scripts/skins.gd")
const ShopScript := preload("res://scripts/shop.gd")
const Chest := preload("res://scripts/chest.gd")
const ChestScreen := preload("res://scripts/chest_screen.gd")
const PillStyle := preload("res://scripts/pill_style.gd")
const Ads := preload("res://scripts/ads.gd")
## The bottom bars are one pill split into buttons, all this colour.
const BAR_COLOR := Color(0.24, 0.25, 0.29, 0.62)
const Achievements := preload("res://scripts/achievements.gd")
const AchievementsScreen := preload("res://scripts/achievements_screen.gd")
const DailyGift := preload("res://scripts/daily_gift.gd")
const VaultGame := preload("res://scripts/vault_game.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Missions := preload("res://scripts/missions.gd")
const SettingsScreen := preload("res://scripts/settings_screen.gd")
const Solver := preload("res://scripts/solver.gd")
const LevelGrid := preload("res://scripts/level_grid.gd")
const LevelCode := preload("res://scripts/level_code.gd")
const Levels := preload("res://scripts/levels.gd")
const LevelsScreen := preload("res://scripts/levels_screen.gd")
const LevelEditor := preload("res://scripts/level_editor.gd")

const TILE := 27
const SLIDE_SPEED := 24.0        # tiles per second while sliding
const SWIPE_MIN_DIST := 24.0     # pixels before a drag counts as a swipe
const LAVA_START_SPEED := 0.5    # tiles per second
const LAVA_ACCEL := 0.012        # extra tiles per second, gained each second
const LAVA_MAX_SPEED := 2.6
const LAVA_MAX_GAP := 11.0       # the lava never falls further behind than this
## Power-ups replace a coin on some floors: a shield that saves you once,
## a magnet that pulls in nearby coins, and a freeze that stops the lava.
const POWERUP_FROM_FLOOR := 4
const POWERUP_CHANCE := 0.3
const POWERUPS := ["shield", "magnet", "freeze"]
const MAGNET_TIME := 8.0
const MAGNET_RANGE := 2          # tiles, in every direction
const FREEZE_TIME := 4.0
const POWERUP_COLORS := {"shield": Color("4cc9f0"), "magnet": Color("e84855"), "freeze": Color("bdefff")}
## The Daily Climb ghost: your best run today, replayed for you to race.
## Positions are recorded every GHOST_STEP seconds of play.
const GHOST_STEP := 0.1
## Coin combos: grab at least COMBO_MIN coins in one slide and every coin
## past the first COMBO_MIN - 1 pays double.
const COMBO_MIN := 5
const DANGER_GAP := 5.0          # the screen edges glow red when the lava is this close (tiles)
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
## Daily Climb: one tower per day, the same for every player, DAILY_TOP
## floors high. The fastest time to the top is today's best, and earns a
## medal: bronze for finishing, silver and gold for beating times worked out
## from that day's tower (see medal_times). Each medal pays its own prize,
## and a better medal later in the day pays only the prizes not yet won.
const DAILY_TOP := 20
## The daily's lava is gentler than the endless tower's, so a beginner can
## still reach the top; the medal times are what push good players.
const DAILY_LAVA_ACCEL := 0.005
const DAILY_LAVA_MAX_SPEED := 0.8
## It also hangs further back, more than a room's height, so a route that
## drops down a room on its way up is still safe for a slower climber.
const DAILY_LAVA_MAX_GAP := 16.0
const BRONZE_COINS := 50
const SILVER_COINS := 75             # gold's prize is a chest
## Thinking time per swipe that each medal allows, on top of the slides
## themselves. tests/test_daily_skill.gd checks these against simulated
## players: experts get gold, good players silver, beginners bronze.
const GOLD_THINK := 0.42
const SILVER_THINK := 0.75
## Climbing this many floors in a day, over any runs, earns a free chest.
const DAILY_CHEST_FLOORS := 200
const MEDALS := ["", "Bronze medal", "Silver medal", "Gold medal"]
const MEDAL_COLORS := [Color.WHITE, Color("cd7f32"), Color("c0c8d0"), Color("ffd23f")]
## Seconds between the end of a run and its saved chests opening.
const CHEST_OPEN_DELAY := 0.9
## One revive per run, paid in coins: the base cost plus a bit per floor.
## You go back to where your last slide started, with the lava pushed back.
const REVIVE_BASE_COST := 50
const REVIVE_COST_PER_FLOOR := 2
const REVIVE_LAVA_GAP := 8.0     # tiles between you and the lava after a revive
const REVIVE_GRACE := 1.5        # seconds the lava waits after a revive
## Levels: the screen glows red and a heartbeat plays in the last seconds.
const LEVEL_WARN_TIME := 5.0
const LEVEL_HUD_GAP := 70.0      # screen space kept clear for the HUD above a level
const LEVEL_FOOT_GAP := 20.0     # and below it

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
var new_items: Array = []        # won items the player hasn't looked at in the shop yet
var equipped_hero := "white"
var equipped_wall := "rubble"
var equipped_trail := "afterimage"
var equipped_lava := "classic"
var equipped_hat := "no_hat"
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
var pending_chests := 0          # saved; chests picked up this run, opened when it ends
var chest_batch := 0             # how many saved chests are opening, for "CHEST 2 OF 3"
var chest_batch_done := 0
var end_message := ""            # the death or win message, shown again after the chests
var stats := {}                  # saved counters that achievements watch
var unlocked: Array = []         # saved ids of unlocked achievements
var achievements_screen: Control
var daily_gift: Control
var vault_game: Control
var vault_button: Button
var vault_day := ""                # the day the vault counts below are for
var vault_free_used := 0
var vault_ads_used := 0
var gift_day := 0                  # which of the 7 daily gifts is next (0-6)
var gift_date := ""                # the day the last gift was claimed
var menu_bar: HBoxContainer
var banner: PanelContainer
var banner_label: Label
var banner_queue: Array = []
var banner_time := 0.0
var sfx: Node
var vibration_on := true         # saved, like sfx.enabled
var gear_button: Button
var settings_screen: Control
var language := ""               # saved; "" means follow the phone's language
var daily_mode := false
var daily_button: Button
var daily_date := ""             # saved; the day daily_best and daily_medal are for
var daily_best := 0
var daily_medal := 0             # saved; today's best medal: 0 none, 1 bronze, 2 silver, 3 gold
var floors_today := 0            # saved; floors climbed today in any mode, for the daily chest
var floors_day := ""             # saved; the day floors_today counts
var medal_cache := {}            # date -> [gold seconds, silver seconds]
var daily_time := 0.0            # saved; today's fastest climb to the top, 0 if none yet
var daily_time_at_start := 0.0
var daily_last_played := ""      # saved; the last day a Daily Climb was started
var daily_streak := 0            # saved; days in a row with a Daily Climb
var revived := false            # whether this run's revive is used
var slide_start := Vector2i.ZERO # where the current or last slide began
var lava_grace := 0.0
var revive_button: Button
var ads := Ads.new()
var ad_bar: HBoxContainer          # the watch-an-ad buttons on the death screen
var ad_revive_button: Button
var ad_double_button: Button
var doubled := false               # this run's coins were already doubled by an ad
var stats_banked := Vector2i.ZERO  # floors and seconds of this run already added to the stats
var ad_coins_day := ""             # the day ad_coins_today counts
var ad_coins_today := 0            # shop coin ads watched that day
var deal_day := ""                 # the day deal_id was picked
var deal_id := ""                  # today's discounted shop item ("" if none left)
var pause_button: Button
var best_at_start := 0           # best floor before this run, for the "New best!" moment
var new_best_shown := false
var idle_time := 0.0             # seconds standing still, for the new-player hints
var missions: Array = []         # saved; the active missions, see missions.gd
var mission_rng := RandomNumberGenerator.new()
var missions_panel: PanelContainer
var missions_rows: VBoxContainer
var pending_swap := -1           # the mission waiting for a second tap to swap
var powerups := {}               # cell -> power-up type, on floors loaded this run
var powerups_rolled := 0         # floors below this have had their power-up roll
var powerup_rng := RandomNumberGenerator.new()
var shield := false
var magnet_time := 0.0
var freeze_time := 0.0
var effects_label: Label
var daily_ghost := PackedVector2Array()  # saved; today's best daily run
var recording := PackedVector2Array()    # this run, in case it beats the ghost
var daily_best_at_start := 0
var slide_coins := 0             # coins grabbed in the current slide
var danger := 0.0                # 0-1, how close the lava is, for the red glow
var heartbeat_time := 0.0
var danger_overlay: Control
var marker_floor := 0            # the best to beat, drawn as a line on the tower
## Levels (handmade or player-made) replace the tower while `level` is set.
var level := {}                  # {name, time, rows}; empty in the tower
var level_source := ""           # "campaign", "custom" or "test" (from the editor)
var level_index := -1            # which campaign level
var time_left := 0.0
var level_coins := 0             # coins in the level when it started
var levels_cleared: Array = []   # saved; campaign levels cleared
var level_times := {}            # saved; best time per campaign level
var level_stars := {}            # saved; star bits per campaign level (see levels.gd)
var custom_levels: Array = []    # saved; codes of levels made or added by the player
var levels_screen: Control
var level_editor: Control
var level_bar: HBoxContainer
var level_back_button: Button
var level_next_button: Button
## For tests: pretends today is this date ("YYYY-MM-DD").
var test_today := ""
var test_safe_insets: Array = []  # for tests: [left, top, right, bottom] instead of the phone's
var safe_root: Control


func _ready() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	_load_save()
	set_language(language)
	sfx.update_music()
	mission_rng.randomize()
	_fill_missions()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()
	_build_hud()
	# Every button in the game clicks, including ones made later (shop cards, level rows).
	get_tree().node_added.connect(_on_node_added)
	for b in find_children("*", "BaseButton", true, false):
		_add_click(b)
	for c in find_children("*", "Control", true, false):
		_let_scroll_through(c)
	reset()
	# Chests saved in a run that never ended, like when the app was closed.
	if pending_chests > 0:
		_open_next_chest(State.READY)


func reset() -> void:
	var seed_value := randi()
	if is_level():
		tower = LevelGrid.new()
		tower.load_rows(level.rows)
	else:
		tower = TowerScript.new()
		_refresh_daily()
		if test_seed >= 0:
			seed_value = test_seed
		elif daily_mode:
			seed_value = daily_seed(daily_date)
		tower.build(Rooms.START, Rooms.LAYOUTS, seed_value)
	# Seeded from the tower, so the Daily Climb has the same power-ups for everyone.
	powerup_rng.seed = seed_value + 1
	powerups.clear()
	powerups_rolled = 0
	shield = false
	magnet_time = 0.0
	freeze_time = 0.0
	_roll_powerups(3)
	_update_effects()
	tower.room_limit = test_room_limit
	if daily_mode and test_room_limit < 0 and not is_level():
		tower.room_limit = DAILY_TOP
	cell = tower.start
	slide_start = cell
	revived = false
	doubled = false
	stats_banked = Vector2i.ZERO
	lava_grace = 0.0
	best_at_start = best_floor
	daily_best_at_start = daily_best
	daily_time_at_start = daily_time
	recording = PackedVector2Array()
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
	if bonus_chest_owed and not is_level():
		bonus_chests[CARRYOVER_CHEST_FLOOR - 1] = true
	state = State.READY
	if is_level():
		time_left = level.time
		level_coins = tower.coins_left()
		lava_y = INF
		marker_floor = 0
	camera.position = _camera_target()
	camera.reset_smoothing()
	_update_hud()
	if is_level():
		_show_message("%s\n\n%s\n\n%s" % [level_title(), tr("Reach the exit before the time runs out."), _level_best_text()])
		return
	marker_floor = daily_best if daily_mode else best_floor
	daily_button.text = "ENDLESS" if daily_mode else "DAILY"
	if daily_mode:
		var goal := tr("Reach floor %d as fast as you can.") % DAILY_TOP
		var times := medal_times()
		goal += "\n" + tr("Gold %s · Silver %s") % [time_text(times[0]), time_text(times[1])]
		if daily_medal > 0:
			goal += "\n" + tr("Won today: %s") % tr(MEDALS[daily_medal])
		var progress := ""
		if daily_time > 0.0:
			progress += "\n" + tr("Today's best time: %s") % time_text(daily_time)
		elif daily_best > 0:
			progress += "\n" + tr("Today's best: floor %d") % daily_best
		if daily_streak > 0:
			progress += "\n" + tr("Streak: %d days") % daily_streak
		# The tower is the same for everyone, which the date already says, so
		# the space goes to the goal and medal times.
		_show_message("%s · %s\n\n%s\n%s" % [tr("DAILY CLIMB"), _pretty_date(daily_date), goal, progress])
		return
	var best := ""
	if best_floor > 0:
		best = "\n\n" + tr("Best floor %d") % best_floor + "   ● %d" % total_coins
	var left := daily_chest_left()
	best += "\n" + (tr("Daily chest: %d floors to go") % left if left > 0 else tr("Daily chest earned. Back tomorrow!"))
	_show_message("VAULT DASH\n\n%s%s" % [tr("Swipe to slide.") + "\n" + tr("Climb before the lava gets you."), best])


# --- Game loop -------------------------------------------------------------

func _process(delta: float) -> void:
	anim_time += delta
	var moving := move_dir != Vector2i.ZERO
	rainbow_phase += delta * (Skins.RAINBOW_SLIDE_SPEED if moving else Skins.RAINBOW_IDLE_SPEED)
	state_time += delta
	_update_shop_glow()
	if state == State.READY and not (shop.visible or achievements_screen.visible or settings_screen.visible \
			or levels_screen.visible or level_editor.visible or vault_game.visible):
		_maybe_show_gift()
	if state == State.PLAYING:
		elapsed += delta
		_update_slide(delta)
		idle_time = idle_time + delta if is_idle() else 0.0
	if state == State.PLAYING and is_level():
		var before := ceili(time_left)
		time_left -= delta
		# A beep each second over the last few, rising as time runs out.
		if ceili(time_left) < before and before <= LEVEL_WARN_TIME and time_left > 0.0:
			sfx.play("countdown", 1.0 + (LEVEL_WARN_TIME - before) * 0.08)
		if time_left <= 0.0:
			time_left = 0.0
			_die("Out of time!", "time")
		_update_hud()
	elif state == State.PLAYING:
		_update_powerups(delta)
		_update_lava(delta)
		if daily_mode:
			while recording.size() * GHOST_STEP <= elapsed:
				recording.append(_player_center())
			chest_label.text = time_text(elapsed)
	if (state == State.DEAD or state == State.WON) and pending_chests > 0 and state_time >= CHEST_OPEN_DELAY \
			and not chest_screen.visible:
		_open_next_chest(state)
	shake = maxf(shake - delta, 0.0)
	squash = maxf(squash - delta, 0.0)
	toast_time = maxf(toast_time - delta, 0.0)
	toast_label.modulate.a = clampf(toast_time / 0.4, 0.0, 1.0)
	_update_banner(delta)
	_update_danger(delta)
	_update_music()
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
	slide_coins = 0
	move_dir = d
	move_progress = 0.0
	sfx.play("swipe", randf_range(0.9, 1.1))


## Called each time the player finishes moving one tile.
func _advance() -> void:
	cell += move_dir
	var t: String = tower.get_tile(cell)
	if powerups.has(cell):
		_take_powerup(cell)
	if t == TowerScript.COIN:
		slide_coins += 1
		_collect_coin(cell)
	elif t == TowerScript.SPIKES:
		_die("Spiked on floor %d", "spikes")
		return
	elif t == TowerScript.FAKE or t == TowerScript.FAKE_COIN:
		_die("Fell through a fake floor on floor %d", "fake")
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
		_save_chest()


## Pays the combo bonus for the slide that just ended, if it earned one.
func _finish_combo() -> void:
	var combo := slide_coins
	slide_coins = 0
	if combo < COMBO_MIN or is_level():
		return
	var bonus := combo - (COMBO_MIN - 1)
	run_coins += bonus
	report_run("run_coins", run_coins)
	if combo >= 10 and stat("combo_10") == 0:
		add_stat("combo_10")
	_celebrate(tr("COMBO x%d!") % combo + "  +%d" % bonus)
	_update_hud()


func _collect_coin(c: Vector2i) -> void:
	tower.set_tile(c, TowerScript.EMPTY)
	run_coins += 1
	# Coins in levels are for the score only, so made-up levels can't farm them.
	if not is_level():
		add_stat("coins_collected")
		report_run("run_coins", run_coins)
	sfx.play("coin", randf_range(0.97, 1.06))
	bursts.append({"pos": _tile_center(c), "t": 0.0, "color": COIN_COLOR})
	_update_hud()


# --- Power-ups -------------------------------------------------------------

## Rolls power-ups for every floor below `count` not rolled yet. Each one
## takes the place of a coin, since coins sit where you can reach them.
func _roll_powerups(count: int) -> void:
	while powerups_rolled < count:
		var k := powerups_rolled
		powerups_rolled += 1
		if k + 1 < POWERUP_FROM_FLOOR or powerup_rng.randf() >= POWERUP_CHANCE:
			continue
		var coins: Array = []
		for y in range(-(k + 1) * TowerScript.ROOM_H, -k * TowerScript.ROOM_H):
			for x in tower.width:
				var c := Vector2i(x, y)
				if tower.get_tile(c) == TowerScript.COIN and not (has_chest(k) and c == tower.chest_cell(k)):
					coins.append(c)
		if coins.is_empty():
			continue
		var spot: Vector2i = coins[powerup_rng.randi_range(0, coins.size() - 1)]
		tower.set_tile(spot, TowerScript.EMPTY)
		powerups[spot] = POWERUPS[powerup_rng.randi_range(0, POWERUPS.size() - 1)]


func _take_powerup(c: Vector2i) -> void:
	var kind: String = powerups[c]
	powerups.erase(c)
	give_powerup(kind)
	bursts.append({"pos": _tile_center(c), "t": 0.0, "color": POWERUP_COLORS[kind]})


func give_powerup(kind: String) -> void:
	match kind:
		"shield":
			shield = true
			_toast("Shield!")
		"magnet":
			magnet_time = MAGNET_TIME
			_toast("Coin magnet!")
		"freeze":
			freeze_time = FREEZE_TIME
			_toast("Lava frozen!")
	add_stat("powerups")
	sfx.play("trophy", 1.3)
	vibrate(30)
	_update_effects()


## The shield pops instead of you: back to where your slide began, with the
## lava pushed down if it was close.
func _use_shield() -> void:
	shield = false
	cell = slide_start
	move_dir = Vector2i.ZERO
	queued_dir = Vector2i.ZERO
	lava_y = maxf(lava_y, _player_center().y + REVIVE_LAVA_GAP * TILE * 0.5)
	shake = 0.25
	sfx.play("break", 1.4)
	vibrate(80)
	bursts.append({"pos": _player_center(), "t": 0.0, "color": POWERUP_COLORS.shield})
	_toast("Shield saved you!")
	_update_effects()


func _update_powerups(delta: float) -> void:
	if freeze_time > 0.0:
		freeze_time = maxf(freeze_time - delta, 0.0)
	if magnet_time > 0.0:
		magnet_time = maxf(magnet_time - delta, 0.0)
		for dy in range(-MAGNET_RANGE, MAGNET_RANGE + 1):
			for dx in range(-MAGNET_RANGE, MAGNET_RANGE + 1):
				var c := cell + Vector2i(dx, dy)
				if tower.get_tile(c) == TowerScript.COIN:
					_collect_coin(c)
	_update_effects()


func _update_effects() -> void:
	var parts: Array = []
	if shield:
		parts.append(tr("SHIELD"))
	if magnet_time > 0.0:
		parts.append(tr("MAGNET") + " %d" % ceili(magnet_time))
	if freeze_time > 0.0:
		parts.append(tr("FREEZE") + " %d" % ceili(freeze_time))
	effects_label.text = "\n".join(parts)


func _stop() -> void:
	if move_dir != Vector2i.ZERO:
		sfx.play("stop")
		_finish_combo()
	move_dir = Vector2i.ZERO
	move_progress = 0.0
	squash = 0.12


func _break_wall(c: Vector2i) -> void:
	tower.set_tile(c, TowerScript.EMPTY)
	if not is_level():
		add_stat("walls_broken")
	sfx.play("break")
	vibrate(25)
	bursts.append({"pos": _tile_center(c), "t": 0.0, "color": Color(_wall_skin().base, 1.0)})
	shake = 0.12


func _update_lava(delta: float) -> void:
	if lava_grace > 0.0:
		lava_grace -= delta
		return
	if freeze_time > 0.0:
		return
	var speed := minf(LAVA_START_SPEED + LAVA_ACCEL * elapsed, LAVA_MAX_SPEED)
	if daily_mode:
		speed = minf(LAVA_START_SPEED + DAILY_LAVA_ACCEL * elapsed, DAILY_LAVA_MAX_SPEED)
	lava_y -= speed * TILE * delta
	var player_y := _player_center().y
	lava_y = minf(lava_y, player_y + (DAILY_LAVA_MAX_GAP if daily_mode else LAVA_MAX_GAP) * TILE)
	if lava_y <= player_y:
		_die("Melted on floor %d", "lava")


## The music speeds up as the lava does (and in a level's last seconds),
## and goes quiet behind menus and the pause screen.
func _update_music() -> void:
	var speed := 1.0
	if state == State.PLAYING:
		if is_level():
			speed = 1.08 if time_left <= LEVEL_WARN_TIME else 1.0
		else:
			speed = 1.0 + 0.08 * clampf(elapsed / 90.0, 0.0, 1.0)
	var quiet := state == State.PAUSED or shop.visible or achievements_screen.visible \
			or settings_screen.visible or levels_screen.visible or level_editor.visible or chest_screen.visible
	sfx.set_music_mood(speed, quiet)


## Red glow and a heartbeat as the lava closes in.
func _update_danger(delta: float) -> void:
	var target := 0.0
	if state == State.PLAYING and is_level():
		target = clampf(1.0 - time_left / LEVEL_WARN_TIME, 0.0, 1.0)
	elif state == State.PLAYING:
		var gap := (lava_y - _player_center().y) / TILE
		target = clampf(1.0 - (gap - 1.0) / (DANGER_GAP - 1.0), 0.0, 1.0)
	danger = move_toward(danger, target, delta * 3.0)
	danger_overlay.queue_redraw()
	heartbeat_time -= delta
	if danger > 0.4 and heartbeat_time <= 0.0:
		heartbeat_time = lerpf(0.75, 0.4, danger)
		sfx.play("heartbeat")


func _draw_danger() -> void:
	if danger <= 0.0:
		return
	var view := danger_overlay.size
	var pulse := 0.75 + 0.25 * sin(anim_time * lerpf(6.0, 12.0, danger))
	var bands := 12
	var w := 5.0
	for i in bands:
		var a := danger * pulse * 0.7 * pow(1.0 - float(i) / bands, 1.5)
		var c := Color(1.0, 0.12, 0.04, a)
		danger_overlay.draw_rect(Rect2(i * w, 0, w, view.y), c)
		danger_overlay.draw_rect(Rect2(view.x - (i + 1) * w, 0, w, view.y), c)
		danger_overlay.draw_rect(Rect2(0, i * w, view.x, w), Color(c, a * 0.7))


func _update_floor() -> void:
	if is_level():
		return
	var f: int = tower.room_of(cell.y) + 1
	if f > run_floor:
		# A slide can carry you through more than one door at once.
		for passed in range(run_floor + 1, f + 1):
			if tower.is_trap(passed - 1):
				add_stat("trap_floors")
				add_trap_meter(passed, meter_rng.randf_range(TRAP_METER_MIN, TRAP_METER_MAX))
		_count_daily_floors(f - run_floor)
		run_floor = f
		_roll_powerups(f + 3)
		report_run("run_floor", f)
		if daily_mode:
			report_run("daily_floor", f)
		if f > best_floor:
			best_floor = f
			check_achievements()
		if f > best_at_start and best_at_start > 0 and not new_best_shown and not daily_mode:
			new_best_shown = true
			_celebrate("NEW BEST!")
		if daily_mode:
			daily_best = mini(maxi(daily_best, f), DAILY_TOP)
		if f >= 20 and elapsed <= 60.0 and stat("fast_20") == 0:
			add_stat("fast_20")
		_update_hud()
		if tower.is_trap(f - 1):
			_toast(tr("Floor %d") % f + "\n" + tr("Watch your step..."))
			sfx.play("trap")
	var biome := _biome_index(cell.y)
	if biome != last_biome:
		last_biome = biome
		_toast(tr(BIOMES[biome].name))


func _die(reason: String, cause: String) -> void:
	if is_level():
		_level_lost(cause)
		return
	if shield:
		_use_shield()
		return
	state = State.DEAD
	add_stat("deaths")
	add_stat("deaths_" + cause)
	sfx.play("death")
	vibrate(150)
	state_time = 0.0
	move_dir = Vector2i.ZERO
	shake = 0.35
	# A climb that reached the top always beats one that didn't.
	if daily_mode and daily_time == 0.0 and run_floor > daily_best_at_start:
		daily_ghost = recording.duplicate()
	_bank_run()
	ads.after_run()
	var best := tr("Today's best: floor %d") % daily_best if daily_mode else tr("Best: floor %d") % best_floor
	if daily_mode and daily_time > 0.0:
		best = tr("Today's best time: %s") % time_text(daily_time)
	_end_run("%s\n\n%s   %s\n\n%s" % [tr(reason) % run_floor, tr("+%d coins") % run_coins, best, tr("Swipe to try again")])


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
	var where := _clock(time_left) if is_level() else tr("Floor %d") % run_floor
	where += "   ● %d" % run_coins
	if pending_chests > 0:
		where += "\n" + tr("Chests saved: %d") % pending_chests
	_show_message("%s\n\n%s\n\n%s" % [tr("PAUSED"), where, tr("Tap to carry on")])
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
	_revive_now()
	return true


## A free revive for watching an ad, instead of paying coins.
func ad_revive() -> bool:
	if state != State.DEAD or revived or not ads.can_show_rewarded():
		return false
	ads.show_rewarded("revive", _revive_now)
	return true


## Watch an ad to bank this run's coins a second time.
func ad_double_coins() -> bool:
	if doubled or run_coins <= 0 or (state != State.DEAD and state != State.WON) or not ads.can_show_rewarded():
		return false
	ads.show_rewarded("double_coins", _double_coins_now)
	return true


func _double_coins_now() -> void:
	doubled = true
	total_coins += run_coins
	sfx.play("buy")
	_toast(tr("+%d coins") % run_coins)
	_save()
	_update_hud()
	_update_revive_button()


## Shop coins for watching an ad, a few times a day.
func ad_coins_left() -> int:
	if not ads.can_show_rewarded():
		return 0
	if ad_coins_day != today():
		return Ads.SHOP_PER_DAY
	return maxi(Ads.SHOP_PER_DAY - ad_coins_today, 0)


func ad_shop_coins() -> bool:
	if ad_coins_left() <= 0:
		return false
	ads.show_rewarded("shop_coins", _shop_coins_now)
	return true


func _shop_coins_now() -> void:
	if ad_coins_day != today():
		ad_coins_day = today()
		ad_coins_today = 0
	ad_coins_today += 1
	total_coins += Ads.SHOP_COINS
	sfx.play("buy")
	_save()


func _revive_now() -> void:
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


func _update_revive_button() -> void:
	revive_button.visible = state == State.DEAD and not revived and pending_chests == 0
	revive_button.text = tr("REVIVE") + "   ● %d" % revive_cost()
	revive_button.disabled = total_coins < revive_cost()
	var ending := (state == State.DEAD or state == State.WON) and pending_chests == 0 and not is_level()
	ad_revive_button.visible = revive_button.visible and ads.can_show_rewarded()
	ad_double_button.visible = ending and not doubled and run_coins > 0 and ads.can_show_rewarded()
	ad_revive_button.text = tr("FREE REVIVE") + " (" + tr("AD") + ")"
	ad_double_button.text = tr("2x COINS") + " (" + tr("AD") + ")"
	ad_bar.visible = ad_revive_button.visible or ad_double_button.visible


## Reached in levels, or when a test gives the tower an exit.
func _win() -> void:
	if is_level():
		_level_won()
		return
	state = State.WON
	state_time = 0.0
	move_dir = Vector2i.ZERO
	if daily_mode:
		_daily_won()
		return
	if best_time == 0.0 or elapsed < best_time:
		best_time = elapsed
	_bank_run()
	_end_run("YOU ESCAPED!\n\n%.1f seconds   +%d coins\nBest time: %.1f s\n\nSwipe to climb again" % [elapsed, run_coins, best_time])


## Reaching the top of the Daily Climb: the time counts, and the first finish
## of the day pays the daily reward.
func _daily_won() -> void:
	sfx.play("level_clear")
	vibrate(60)
	var lines: Array = [tr("TOP REACHED!"), "", tr("Time: %s") % time_text(elapsed) + "   " + tr("+%d coins") % run_coins]
	if daily_time == 0.0 or elapsed < daily_time:
		if daily_time > 0.0:
			lines.append(tr("New best time!"))
		daily_time = elapsed
		daily_ghost = recording.duplicate()
	else:
		lines.append(tr("Today's best time: %s") % time_text(daily_time))
	var medal := medal_level(elapsed)
	lines.append(tr(MEDALS[medal]) + "!")
	if medal > daily_medal:
		if daily_medal == 0:
			add_stat("daily_goals")
		var prize := _medal_prize(daily_medal, medal)
		if prize != "":
			lines.append(prize)
		if medal == 3:
			add_stat("daily_golds")
		daily_medal = medal
	daily_best = DAILY_TOP
	_bank_run()
	lines.append("")
	lines.append(tr("Swipe to climb again"))
	_end_run("\n".join(lines))


## Counts floors towards today's free chest, which is saved for the end of
## the run like any other chest.
func _count_daily_floors(n: int) -> void:
	if floors_day != today():
		floors_day = today()
		floors_today = 0
	var before := floors_today
	floors_today += n
	if before < DAILY_CHEST_FLOORS and floors_today >= DAILY_CHEST_FLOORS:
		pending_chests += 1
		add_stat("daily_chests")
		banner_queue.append("%s\n%s" % [tr("DAILY CHEST!"), tr("%d floors climbed today") % DAILY_CHEST_FLOORS])
		sfx.play("trophy")
		_save()


## Floors still to climb today for the daily chest; 0 once it's earned.
func daily_chest_left() -> int:
	if floors_day != today():
		return DAILY_CHEST_FLOORS
	return maxi(DAILY_CHEST_FLOORS - floors_today, 0)


## Pays the prizes for every medal above `old` up to `new`, and says what
## they were. Gold's chest is saved and opens as the run ends.
func _medal_prize(old: int, new: int) -> String:
	var coins := 0
	if old < 1 and new >= 1:
		coins += BRONZE_COINS
	if old < 2 and new >= 2:
		coins += SILVER_COINS
	total_coins += coins
	var parts: Array = []
	if coins > 0:
		parts.append(tr("+%d coins") % coins)
	if old < 3 and new >= 3:
		pending_chests += 1
		parts.append(tr("+1 chest"))
	return "   ".join(parts)


## The gold and silver times for today's Daily Climb, in seconds. They come
## from the quickest route up the tower: the time its slides take, plus a
## little thinking time per swipe (GOLD_THINK, SILVER_THINK).
func medal_times() -> Array:
	if medal_cache.has(daily_date):
		return medal_cache[daily_date]
	var route := _daily_route()
	var times := [
		route.slide_time + route.moves * GOLD_THINK,
		route.slide_time + route.moves * SILVER_THINK,
	]
	medal_cache[daily_date] = times
	return times


## 3 gold, 2 silver, 1 bronze for a finish in `seconds`.
func medal_level(seconds: float) -> int:
	var times := medal_times()
	if seconds <= times[0]:
		return 3
	if seconds <= times[1]:
		return 2
	return 1


func medal_for(seconds: float) -> String:
	return ["", "bronze", "silver", "gold"][medal_level(seconds)]


## The fewest-swipes route up today's tower, and how long its slides take.
func _daily_route() -> Dictionary:
	var t := TowerScript.new()
	t.build(Rooms.START, Rooms.LAYOUTS, daily_seed(daily_date))
	t.room_limit = DAILY_TOP
	var solver = Solver.new(t)
	solver.upward_only = true
	solver.run()
	var tiles := 0
	var c: Vector2i = t.start
	var broken := {}
	for dir: Vector2i in solver.solution:
		var r: Dictionary = t.simulate_slide(c, dir, broken)
		var end: Vector2i = r.end
		tiles += absi(end.x - c.x) + absi(end.y - c.y)
		if r.broke != null:
			broken[r.broke] = true
		c = end
	return {"moves": solver.solution.size(), "slide_time": tiles / SLIDE_SPEED}


## Seconds with tenths, like "47.3 s", or "1:05.2" past a minute.
static func time_text(seconds: float) -> String:
	var tenths := roundi(seconds * 10.0)
	if tenths < 600:
		return "%.1f s" % (tenths / 10.0)
	return "%d:%04.1f" % [tenths / 600, (tenths % 600) / 10.0]


## Shows the death or win message, after opening any chests saved this run.
func _end_run(text: String) -> void:
	end_message = text
	_show_message(text)
	_update_revive_button()
	if pending_chests > 0:
		# The menus wait until the saved chests are open.
		menu_bar.visible = false
		_show_top_buttons(false)
		missions_panel.visible = false


func _bank_run() -> void:
	# Lifetime totals for the stats page (a revive banks only what's new).
	if not is_level():
		add_stat("floors_climbed", maxi(run_floor - stats_banked.x, 0))
		add_stat("play_seconds", maxi(int(elapsed) - stats_banked.y, 0))
		stats_banked = Vector2i(run_floor, int(elapsed))
	total_coins += run_coins
	best_floor = maxi(best_floor, run_floor)
	check_achievements()
	_save()
	_update_hud()


# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if shop.visible or chest_screen.visible or achievements_screen.visible or settings_screen.visible \
			or levels_screen.visible or level_editor.visible or daily_gift.visible or vault_game.visible:
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
			if is_level():
				sfx.play("start")
				_hide_message()
				try_move(d)
				return
			_start_mission_run()
			add_stat("runs")
			if daily_mode:
				_start_daily_run()
			_hide_message()
			try_move(d)
		State.PLAYING:
			try_move(d)
		State.DEAD, State.WON:
			if pending_chests > 0:
				_open_next_chest(state)
			elif state_time >= RESTART_DELAY:
				reset()
		State.PAUSED:
			resume()


func _on_tap() -> void:
	if state == State.PAUSED:
		resume()
		return
	if (state == State.DEAD or state == State.WON) and pending_chests > 0:
		_open_next_chest(state)
	elif (state == State.DEAD or state == State.WON) and state_time >= RESTART_DELAY:
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
	if is_level():
		return _level_camera()
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
	effects_label = _make_label(hud, 15, HORIZONTAL_ALIGNMENT_LEFT)
	effects_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	effects_label.offset_left = 14
	effects_label.offset_top = 40
	effects_label.add_theme_color_override("font_color", Color("bdefff"))
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
	message_label = _make_label(hud, 22, HORIZONTAL_ALIGNMENT_CENTER)
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.offset_left = 24
	# Leave room for the missions panel above and the buttons below.
	message_label.offset_top = 195
	message_label.offset_bottom = -150
	message_label.offset_right = -24
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	danger_overlay = Control.new()
	danger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_overlay.draw.connect(_draw_danger)
	hud.add_child(danger_overlay)
	hud.move_child(danger_overlay, 0)

	missions_panel = PanelContainer.new()
	var missions_style := StyleBoxFlat.new()
	missions_style.bg_color = Color(0.05, 0.05, 0.09, 0.85)
	missions_style.border_color = Color(1, 0.82, 0.25, 0.5)
	missions_style.set_border_width_all(1)
	missions_style.set_corner_radius_all(8)
	missions_style.set_content_margin_all(8)
	missions_panel.add_theme_stylebox_override("panel", missions_style)
	missions_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	missions_panel.offset_left = -160
	missions_panel.offset_right = 160
	missions_panel.offset_top = 70
	missions_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.add_child(missions_panel)
	missions_rows = VBoxContainer.new()
	missions_rows.add_theme_constant_override("separation", 3)
	missions_rows.mouse_filter = Control.MOUSE_FILTER_PASS
	missions_panel.add_child(missions_rows)
	_update_missions_label()
	toast_label = _make_label(hud, 28, HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 70
	toast_label.modulate.a = 0.0

	menu_bar = HBoxContainer.new()
	menu_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	menu_bar.offset_left = -172
	menu_bar.offset_right = 172
	menu_bar.offset_top = -74
	menu_bar.offset_bottom = -20
	menu_bar.add_theme_constant_override("separation", 0)
	hud.add_child(menu_bar)
	shop_button = _menu_button("SHOP", _open_shop, BAR_COLOR)
	_menu_button("LEVELS", _open_levels, BAR_COLOR)
	daily_button = _menu_button("DAILY", func():
		daily_mode = not daily_mode
		reset(), BAR_COLOR)
	_menu_button("TROPHIES", _open_achievements, BAR_COLOR)

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

	level_bar = HBoxContainer.new()
	level_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	level_bar.offset_left = -172
	level_bar.offset_right = 172
	level_bar.offset_top = -74
	level_bar.offset_bottom = -20
	level_bar.add_theme_constant_override("separation", 0)
	level_bar.visible = false
	hud.add_child(level_bar)
	level_back_button = _bar_button(level_bar, "LEVELS", _leave_level, BAR_COLOR)
	_bar_button(level_bar, "RETRY", func():
		if state == State.PAUSED:
			state = State.DEAD
		reset(), BAR_COLOR)
	level_next_button = _bar_button(level_bar, "NEXT", func(): start_campaign_level(level_index + 1), BAR_COLOR)

	revive_button = Button.new()
	revive_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	revive_button.offset_left = -110
	revive_button.offset_right = 110
	revive_button.offset_top = -146
	revive_button.offset_bottom = -92
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

	ad_bar = HBoxContainer.new()
	ad_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ad_bar.offset_left = -150
	ad_bar.offset_right = 150
	ad_bar.offset_top = -200
	ad_bar.offset_bottom = -154
	ad_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	ad_bar.add_theme_constant_override("separation", 0)
	ad_bar.visible = false
	hud.add_child(ad_bar)
	ad_revive_button = _bar_button(ad_bar, "FREE REVIVE", ad_revive, Color(0.23, 0.66, 0.34, 0.6))
	ad_double_button = _bar_button(ad_bar, "2x COINS", ad_double_coins, Color(0.23, 0.66, 0.34, 0.6))
	for b in [ad_revive_button, ad_double_button]:
		b.add_theme_font_size_override("font_size", 14)
		b.clip_text = false

	gear_button = Button.new()
	gear_button.flat = true
	gear_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	gear_button.offset_left = -24
	gear_button.offset_right = 24
	gear_button.offset_top = 4
	gear_button.offset_bottom = 48
	gear_button.tooltip_text = "Settings"
	gear_button.draw.connect(_draw_gear)
	gear_button.pressed.connect(_open_settings)
	hud.add_child(gear_button)
	vault_button = _top_icon(gear_button.get_parent(), -64, "VAULT", _draw_vault_icon, func(): vault_game.open())

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

	settings_screen = SettingsScreen.new()
	hud.add_child(settings_screen)
	settings_screen.setup(self)
	settings_screen.closed.connect(_close_settings)

	levels_screen = LevelsScreen.new()
	hud.add_child(levels_screen)
	levels_screen.setup(self)

	level_editor = LevelEditor.new()
	hud.add_child(level_editor)
	level_editor.setup(self)

	achievements_screen = AchievementsScreen.new()
	hud.add_child(achievements_screen)
	achievements_screen.setup(self)
	achievements_screen.closed.connect(func(): achievements_screen.visible = false)
	vault_game = VaultGame.new()
	hud.add_child(vault_game)
	vault_game.setup(self)
	vault_game.closed.connect(func():
		vault_game.visible = false
		reset())
	daily_gift = DailyGift.new()
	hud.add_child(daily_gift)
	daily_gift.setup(self)
	daily_gift.claimed.connect(_claim_gift)
	# The banner goes on top of every other screen.
	hud.add_child(banner)
	chest_rng.randomize()
	meter_rng.randomize()
	# Buttons, text and menus live inside the screen's safe area, clear of
	# notches, camera holes and gesture bars. The tower, the lava glow and
	# the menu backgrounds still fill the whole screen.
	safe_root = Control.new()
	safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(safe_root)
	for child in hud.get_children():
		if child != safe_root and child != message_backdrop and child != danger_overlay:
			child.reparent(safe_root, false)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


## How far the safe area is from each screen edge, in game units: left, top,
## right, bottom. Zero on phones without a notch, and on desktop.
func safe_insets() -> Array:
	if test_safe_insets.size() == 4:
		return test_safe_insets
	if not OS.has_feature("mobile"):
		return [0.0, 0.0, 0.0, 0.0]
	var window := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if window.x <= 0.0 or safe.size.x <= 0.0:
		return [0.0, 0.0, 0.0, 0.0]
	var units := get_viewport_rect().size / window
	return [
		maxf(safe.position.x, 0.0) * units.x,
		maxf(safe.position.y, 0.0) * units.y,
		maxf(window.x - safe.end.x, 0.0) * units.x,
		maxf(window.y - safe.end.y, 0.0) * units.y,
	]


func _apply_safe_area() -> void:
	var inset := safe_insets()
	safe_root.offset_left = inset[0]
	safe_root.offset_top = inset[1]
	safe_root.offset_right = -inset[2]
	safe_root.offset_bottom = -inset[3]
	# Full-screen menus keep their background edge to edge.
	for screen in [shop, chest_screen, settings_screen, levels_screen, level_editor, achievements_screen, daily_gift, vault_game]:
		var bg: Control = screen.get_child(0)
		if bg is ColorRect:
			bg.offset_left = -inset[0]
			bg.offset_top = -inset[1]
			bg.offset_right = inset[2]
			bg.offset_bottom = inset[3]


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
	if is_level():
		coins_label.text = "● %d/%d" % [run_coins, level_coins]
		floor_label.text = _clock(time_left)
		floor_label.add_theme_color_override("font_color", Color("ff6b5b") if time_left <= LEVEL_WARN_TIME else Color.WHITE)
		chest_label.text = level_title()
		return
	floor_label.remove_theme_color_override("font_color")
	coins_label.text = "● %d" % run_coins
	floor_label.text = tr("Floor %d") % run_floor
	var every := TowerScript.CHEST_EVERY
	var next := ceili(float(run_floor) / every) * every
	if chests_taken.has(next - 1):
		next += every
	for k in bonus_chests:
		if k + 1 >= run_floor and k + 1 < next and not chests_taken.has(k):
			next = k + 1
	chest_label.text = tr("Chest at floor %d") % next
	if daily_mode:
		floor_label.text = tr("Floor %d") % run_floor + "/%d" % DAILY_TOP
		chest_label.text = time_text(elapsed)


func _show_message(text: String) -> void:
	pause_button.visible = false
	missions_panel.visible = state != State.PAUSED and not is_level()
	revive_button.visible = false
	ad_bar.visible = false
	message_label.text = text
	message_label.visible = true
	message_backdrop.visible = true
	menu_bar.visible = not is_level()
	level_bar.visible = is_level()
	if is_level():
		level_back_button.text = "EDIT" if level_source == "test" else "LEVELS"
		level_next_button.visible = level_source == "campaign" and level_index + 1 < Levels.LEVELS.size() \
				and levels_cleared.has(level_index) and state != State.PAUSED
		_fit_bar(level_bar)
	else:
		_fit_bar(menu_bar)
	_show_top_buttons(true)


func _hide_message() -> void:
	pending_swap = -1
	pause_button.visible = state == State.PLAYING
	missions_panel.visible = false
	message_label.visible = false
	message_backdrop.visible = false
	menu_bar.visible = false
	level_bar.visible = false
	_show_top_buttons(false)
	revive_button.visible = false
	ad_bar.visible = false


func _menu_button(text: String, action: Callable, color: Color) -> Button:
	return _bar_button(menu_bar, text, action, color)


## The bottom-bar buttons are two-half pills (see pill_style.gd).
func _bar_button(bar: HBoxContainer, text: String, action: Callable, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	var face := PillStyle.new(color)
	b.add_theme_stylebox_override("normal", face)
	b.add_theme_stylebox_override("hover", face)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("pressed", PillStyle.new(color, true))
	b.add_theme_stylebox_override("disabled", PillStyle.new(color.darkened(0.4)))
	b.visibility_changed.connect(_style_bar.bind(bar))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(color.darkened(0.7), 0.9))
	b.add_theme_constant_override("outline_size", 5)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = 1.0
	b.add_theme_font_size_override("font_size", 16)
	b.clip_text = true
	b.pressed.connect(action)
	bar.add_child(b)
	return b


## Rounds the ends of the first and last visible buttons and puts a dividing
## line after every other one, so the bar reads as one pill.
func _style_bar(bar: HBoxContainer) -> void:
	var shown: Array = bar.get_children().filter(func(b): return b.visible)
	for i in shown.size():
		var b: Button = shown[i]
		for key in ["normal", "pressed", "disabled"]:
			var face: PillStyle = b.get_theme_stylebox(key)
			face.round_left = i == 0
			face.round_right = i == shown.size() - 1
			face.divider = i < shown.size() - 1
		b.queue_redraw()


## Shrinks the bar buttons' text to fit, after the language changes.
func _fit_bar(bar: HBoxContainer) -> void:
	_style_bar(bar)
	var count := bar.get_child_count()
	for b: Button in bar.get_children():
		b.add_theme_font_size_override("font_size", 16)
		var label := Label.new()
		label.text = b.text
		label.add_theme_font_size_override("font_size", 16)
		fit_font(label, 344.0 / count - 22.0, 10)
		b.add_theme_font_size_override("font_size", label.get_theme_font_size("font_size"))
		label.free()


## The small round buttons beside the gear (vault, pets), with a caption.
func _top_icon(parent: Node, x: float, caption: String, drawer: Callable, action: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	b.offset_left = x - 22
	b.offset_right = x + 22
	b.offset_top = 2
	b.offset_bottom = 50
	b.draw.connect(drawer.bind(b))
	b.pressed.connect(action)
	parent.add_child(b)
	var label := _make_label(b, 9, HORIZONTAL_ALIGNMENT_CENTER)
	label.text = caption
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -13
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	return b


func _show_top_buttons(on: bool) -> void:
	gear_button.visible = on
	vault_button.visible = on and not is_level() and state != State.PAUSED


func _draw_vault_icon(b: Button) -> void:
	var c := Vector2(b.size.x * 0.5, 18)
	var color := Color(1, 1, 1, 0.9)
	b.draw_circle(c, 12, color)
	b.draw_circle(c, 9.5, Color(0.08, 0.08, 0.12))
	b.draw_circle(c, 3, color)
	for i in 3:
		b.draw_line(c, c + Vector2.from_angle(TAU * i / 3.0 - PI * 0.5) * 8, color, 1.5)
	if vault_free_left() > 0:
		b.draw_circle(c + Vector2(10, -9), 3.5, Color("ff4d4d"))


## Crack the Vault tries: FREE_PER_DAY free, then AD_PER_DAY more for ads
## (Steam has no ads, so it gets those as free tries instead).
func _vault_new_day() -> void:
	if vault_day != today():
		vault_day = today()
		vault_free_used = 0
		vault_ads_used = 0


func vault_free_left() -> int:
	_vault_new_day()
	var free := VaultGame.FREE_PER_DAY + (0 if ads.can_show_rewarded() else VaultGame.AD_PER_DAY)
	return maxi(free - vault_free_used, 0)


func vault_ad_left() -> int:
	_vault_new_day()
	return maxi(VaultGame.AD_PER_DAY - vault_ads_used, 0) if ads.can_show_rewarded() else 0


## Spends a free try; ad tries are granted by vault_use_ad first.
func vault_take_try() -> bool:
	if vault_free_left() <= 0:
		return false
	vault_free_used += 1
	_save()
	return true


func vault_use_ad() -> void:
	_vault_new_day()
	vault_ads_used += 1
	vault_free_used -= 1    # the ad hands back one try, which _start spends


## A gear drawn in code, so it looks the same whatever the font.
func _draw_gear() -> void:
	var c := gear_button.size * 0.5
	var r := 8.0
	var color := Color(1, 1, 1, 0.9)
	for i in 8:
		var a := TAU * i / 8.0
		var d := Vector2.from_angle(a)
		var side := Vector2(-d.y, d.x)
		gear_button.draw_colored_polygon(PackedVector2Array([
			c + d * r * 0.8 + side * 2.4, c + d * (r + 3.0) + side * 1.8,
			c + d * (r + 3.0) - side * 1.8, c + d * r * 0.8 - side * 2.4,
		]), color)
	gear_button.draw_circle(c, r, color)
	gear_button.draw_circle(c, r * 0.42, Color(0.08, 0.08, 0.12))


func _open_settings() -> void:
	settings_screen.open()


func _close_settings() -> void:
	settings_screen.visible = false
	_refresh_texts()


## Switches the game's language ("" follows the phone's).
func set_language(locale: String) -> void:
	language = locale
	TranslationServer.set_locale(locale if locale != "" else device_locale())


## Shrinks a label's font, down to `min_size`, until its (translated) text
## fits `max_width`. Some languages run much longer than English.
static func fit_font(label: Label, max_width: float, min_size: int) -> void:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var text := TranslationServer.translate(label.text)
	while size > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width:
		size -= 1
	label.add_theme_font_size_override("font_size", size)


## The game's closest language to the phone's. Hong Kong, Macau, Taiwan and
## "Hant" phones get Traditional Chinese; other Chinese phones get Simplified.
static func device_locale() -> String:
	var os_locale := OS.get_locale()
	var lang := OS.get_locale_language()
	if lang == "zh":
		for tag in ["TW", "HK", "MO", "Hant"]:
			if tag in os_locale:
				return "zh_TW"
		return "zh_CN"
	if lang in ["es", "fr", "de", "tr", "ru"]:
		return lang
	return "en"


## Redraws text that was set in code, after the language changes.
func _refresh_texts() -> void:
	match state:
		State.READY:
			reset()
		State.PAUSED:
			state = State.PLAYING
			pause()
	shop_button.text = tr("SHOP")
	_update_missions_label()
	_update_hud()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_add_click(node)
	if node is Control:
		_let_scroll_through(node)


## A finger that lands on a card, row or progress bar in a scrolling list
## must still scroll it. Controls that stop touches would swallow the drag
## and the list would feel stuck, so inside a ScrollContainer they pass
## touches on instead. Taps still press buttons; drags never do.
static func _let_scroll_through(node: Control) -> void:
	if node.mouse_filter != Control.MOUSE_FILTER_STOP or node is ScrollBar:
		return
	var p := node.get_parent()
	while p != null:
		if p is ScrollContainer:
			node.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		p = p.get_parent()


func _add_click(b: BaseButton) -> void:
	if not b.pressed.is_connected(_click):
		b.pressed.connect(_click)


func _click() -> void:
	sfx.play("click", randf_range(0.95, 1.05))


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
		"levels_cleared":
			return levels_cleared.size()
		"level_stars":
			return total_stars()
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
	check_missions()


# --- Missions --------------------------------------------------------------

## Tops the list back up to Missions.ACTIVE, each from a different template.
func _fill_missions() -> void:
	while missions.size() < Missions.ACTIVE:
		missions.append(Missions.make(mission_rng, stat("missions_done"), _mission_ids(), stat))


func _mission_ids() -> Array:
	return missions.map(func(m): return m.id)


## Reports a within-one-run value (run_coins, run_floor or daily_floor).
func report_run(key: String, value: int) -> void:
	for m in missions:
		if Missions.find(m.id).get("run", "") == key:
			m.progress = maxi(m.progress, value)
	check_missions()


## Pays out finished missions and swaps each for a new one.
func check_missions() -> void:
	var done := false
	for i in missions.size():
		var m: Dictionary = missions[i]
		var t := Missions.find(m.id)
		if t.is_empty():
			missions[i] = {}
			continue
		if t.has("stat"):
			m.progress = stat(t.stat) - m.start
		if m.progress < m.goal:
			continue
		total_coins += m.reward
		banner_queue.append("%s\n%s\n%s" % [tr("MISSION DONE"), Missions.describe(m), tr("+%d coins") % m.reward])
		stats["missions_done"] = stats.get("missions_done", 0) + 1
		missions[i] = {}
		done = true
	missions = missions.filter(func(m): return not m.is_empty())
	if done or missions.size() < Missions.ACTIVE:
		_fill_missions()
		check_achievements()
		_save()
	_update_missions_label()


## Within-one-run missions start from 0 each run.
func _start_mission_run() -> void:
	for m in missions:
		if Missions.find(m.id).has("run"):
			m.progress = 0


func _update_missions_label() -> void:
	if missions_rows == null:
		return
	for c in missions_rows.get_children():
		missions_rows.remove_child(c)
		c.queue_free()
	var title := _plain_label("MISSIONS", 13, Color("ffd23f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missions_rows.add_child(title)
	for i in missions.size():
		var m: Dictionary = missions[i]
		# Each row is a button: tap twice to swap a mission you don't fancy.
		var button := Button.new()
		button.flat = true
		button.custom_minimum_size.y = 24
		button.pressed.connect(_on_mission_tapped.bind(i))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		button.add_child(row)
		var swapping := pending_swap == i
		var text := tr("Tap again to swap for ● %d") % Missions.SWAP_COST if swapping else Missions.describe(m)
		var what := _plain_label(text, 14, Color("ffd23f") if swapping else Color.WHITE)
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		what.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		what.clip_text = true
		fit_font(what, 210 if swapping else 205, 10)
		row.add_child(what)
		if not swapping:
			row.add_child(_plain_label("%d/%d" % [mini(m.progress, m.goal), m.goal], 14, Color(1, 1, 1, 0.6)))
			row.add_child(_plain_label("● %d" % m.reward, 14, Color("ffd23f")))
		missions_rows.add_child(button)


func _on_mission_tapped(i: int) -> void:
	if pending_swap != i:
		pending_swap = i if total_coins >= Missions.SWAP_COST else -1
		if pending_swap == -1:
			_toast(tr("Swapping costs ● %d") % Missions.SWAP_COST)
	else:
		swap_mission(i)
	_update_missions_label()


## Replaces mission `i` with a different one, for Missions.SWAP_COST coins.
func swap_mission(i: int) -> bool:
	pending_swap = -1
	if i < 0 or i >= missions.size() or total_coins < Missions.SWAP_COST:
		return false
	total_coins -= Missions.SWAP_COST
	var old: String = missions[i].id
	var exclude := _mission_ids()
	missions[i] = Missions.make(mission_rng, stat("missions_done"), exclude, stat)
	sfx.play("coin", 0.8)
	_save()
	_update_missions_label()
	if state == State.READY:
		reset()    # refreshes the coin count on the title screen
	return missions[i].id != old


func _plain_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func check_achievements() -> void:
	for a in Achievements.LIST:
		if not unlocked.has(a.id) and stat(a.stat) >= a.goal:
			_unlock(a)


func _unlock(a: Dictionary) -> void:
	unlocked.append(a.id)
	var reward := ""
	if a.has("coins"):
		total_coins += a.coins
		reward = tr("+%d coins") % a.coins
	else:
		var kind: String = a.item[0]
		var item := Skins.find(Skins.list(kind), a.item[1])
		if not owned.has(item.id):
			owned.append(item.id)
			mark_new(item.id)
		reward = tr("New {kind}: {item}").format({"kind": tr(Skins.kind_name(kind)), "item": tr(item.name)})
	banner_queue.append("%s\n%s\n%s" % [tr("TROPHY UNLOCKED"), tr(a.name), reward])
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

## The daily gift waits on the title screen once a day, from the second
## run on (a brand-new player gets the game first).
func gift_ready() -> bool:
	return gift_date != today() and stat("runs") >= 1 and not is_level()


func _maybe_show_gift() -> void:
	if state == State.READY and gift_ready() and not daily_gift.visible and not chest_screen.visible:
		daily_gift.open()


func _claim_gift(gift: Dictionary) -> void:
	gift_date = today()
	gift_day = (gift_day + 1) % DailyGift.GIFTS.size()
	add_stat("gifts")
	if gift.has("chest"):
		pending_chests += 1
		_save()
		_open_next_chest(State.READY)
		return
	total_coins += gift.coins
	sfx.play("reward")
	_toast(tr("+%d coins") % gift.coins)
	_save()
	reset()


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
		daily_medal = 0
		daily_time = 0.0
		daily_ghost = PackedVector2Array()


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
	return TranslationServer.translate("{month} {day}").format({"month": TranslationServer.translate(MONTHS[int(parts[1]) - 1]), "day": int(parts[2])})


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


## Picking up a chest saves it for the end of the run, so the climb keeps going.
func _save_chest() -> void:
	pending_chests += 1
	sfx.play("reward")
	vibrate(40)
	_toast(tr("Chest saved!") + ("  ×%d" % pending_chests if pending_chests > 1 else ""))
	_save()
	_update_hud()


## Opens one saved chest; the rest follow one after another.
func _open_next_chest(return_state: State) -> void:
	if pending_chests <= 0 or chest_screen.visible:
		return
	if state != State.CHEST:
		chest_batch = pending_chests
		chest_batch_done = 0
	chest_batch_done += 1
	pending_chests -= 1
	_save()
	var title := tr("TREASURE CHEST")
	if chest_batch > 1:
		title = tr("CHEST %d OF %d") % [chest_batch_done, chest_batch]
	_open_chest(return_state, title)


func _open_chest(return_state: State = state, title := "TREASURE CHEST") -> void:
	chest_return_state = return_state
	state = State.CHEST
	move_dir = Vector2i.ZERO
	queued_dir = Vector2i.ZERO
	_hide_message()
	var reward := Chest.roll(chest_rng, owns)
	chest_screen.open(reward, chest_rng, tr(title))


func _on_chest_finished(reward: Dictionary) -> void:
	grant(reward)
	if chest_screen.equip_now:
		equip(reward.kind, reward.item.id)
	add_stat("chests_opened")
	if reward.rarity.id == "legendary":
		add_stat("legendaries")
	_toast("+ " + Chest.describe(reward))
	if pending_chests > 0:
		_open_next_chest(chest_return_state)
		return
	if chest_return_state == State.READY:
		reset()
	elif chest_return_state == State.DEAD or chest_return_state == State.WON:
		state = chest_return_state
		state_time = RESTART_DELAY
		_show_message(end_message)
		_update_revive_button()
	else:
		state = State.PLAYING
		pause_button.visible = true
		_update_hud()


## Won items are never equipped for you: they're flagged NEW and the shop
## button glows until you've seen them, so you choose whether to wear them.
func mark_new(id: String) -> void:
	if not new_items.has(id):
		new_items.append(id)


func seen(id: String) -> void:
	new_items.erase(id)


## Chest coins go straight to the bank, so they're safe even if you die.
func grant(reward: Dictionary) -> void:
	if reward.kind == "coins":
		total_coins += reward.coins
	elif not owned.has(reward.item.id):
		owned.append(reward.item.id)
		mark_new(reward.item.id)
		check_achievements()
	_save()


# --- Shop ------------------------------------------------------------------

## The shop button pulses gold while there are new items in it.
func _update_shop_glow() -> void:
	var glow := 0.0
	if not new_items.is_empty() and menu_bar.visible:
		glow = 0.55 + 0.45 * sin(anim_time * 4.0)
	for key in ["normal", "hover"]:
		var face: PillStyle = shop_button.get_theme_stylebox(key)
		if face.glow != glow:
			face.glow = glow
			shop_button.queue_redraw()


func _open_shop() -> void:
	shop.open()


func _close_shop() -> void:
	shop.visible = false
	if state == State.READY:
		reset()    # refreshes the title screen's coin count


## Today's deal: one shop item you don't own, DEAL_OFF cheaper, picked once
## a day. Returns [kind, item], or [] when there's nothing left to discount.
const DEAL_OFF := 0.3
const DEAL_KINDS := ["hero", "hat", "walls", "trail", "lava"]

func deal() -> Array:
	if deal_day != today():
		deal_day = today()
		deal_id = ""
		var choices: Array = []
		for kind in DEAL_KINDS:
			for item in Skins.list(kind):
				if item.price > 0 and not owns(item):
					choices.append(item.id)
		if not choices.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.seed = ("deal-" + deal_day).hash()
			deal_id = choices[rng.randi_range(0, choices.size() - 1)]
		_save()
	if deal_id == "":
		return []
	for kind in DEAL_KINDS:
		for item in Skins.list(kind):
			if item.id == deal_id and not owns(item):
				return [kind, item]
	return []


## What an item costs today, after any deal.
func price(item: Dictionary) -> int:
	if item.id == deal_id and deal_day == today():
		return snappedi(roundi(item.price * (1.0 - DEAL_OFF)), 10)
	return item.price


func owns(item: Dictionary) -> bool:
	return item.price == 0 or owned.has(item.id)


func buy(kind: String, item: Dictionary) -> bool:
	if owns(item) or item.get("chest_only", false) or item.has("achievement") or item.has("level") or total_coins < price(item):
		return false
	total_coins -= price(item)
	sfx.play("buy")
	owned.append(item.id)
	equip(kind, item.id)
	check_achievements()
	return true


func equip(kind: String, id: String) -> void:
	seen(id)
	match kind:
		"hero":
			equipped_hero = id
		"trail":
			equipped_trail = id
		"lava":
			equipped_lava = id
		"hat":
			equipped_hat = id
		_:
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
		new_items = cfg.get_value("shop", "new", [])
		ads.no_forced_ads = cfg.get_value("shop", "no_forced_ads", false)
		ad_coins_day = cfg.get_value("ads", "day", "")
		ad_coins_today = cfg.get_value("ads", "today", 0)
		deal_day = cfg.get_value("shop", "deal_day", "")
		deal_id = cfg.get_value("shop", "deal_id", "")
		gift_day = cfg.get_value("gift", "day", 0)
		vault_day = cfg.get_value("vault", "day", "")
		vault_free_used = cfg.get_value("vault", "free_used", 0)
		vault_ads_used = cfg.get_value("vault", "ads_used", 0)
		gift_date = cfg.get_value("gift", "date", "")
		trap_meter = cfg.get_value("secret", "meter", 0.0)
		bonus_chest_owed = cfg.get_value("secret", "chest_owed", false)
		unlocked = cfg.get_value("achievements", "unlocked", [])
		sfx.enabled = cfg.get_value("settings", "sound", true)
		sfx.music_enabled = cfg.get_value("settings", "music", true)
		sfx.set_volume(cfg.get_value("settings", "sound_volume", 1.0))
		sfx.set_music_volume(cfg.get_value("settings", "music_volume", 1.0))
		vibration_on = cfg.get_value("settings", "vibration", true)
		language = cfg.get_value("settings", "language", "")
		daily_date = cfg.get_value("daily", "date", "")
		daily_best = cfg.get_value("daily", "best", 0)
		daily_medal = cfg.get_value("daily", "medal", 0)
		floors_today = cfg.get_value("daily", "floors_today", 0)
		floors_day = cfg.get_value("daily", "floors_day", "")
		daily_time = cfg.get_value("daily", "time", 0.0)
		pending_chests = cfg.get_value("secret", "pending_chests", 0)
		daily_last_played = cfg.get_value("daily", "last_played", "")
		daily_streak = cfg.get_value("daily", "streak", 0)
		daily_ghost = cfg.get_value("daily", "ghost", PackedVector2Array())
		if cfg.has_section("stats"):
			for key in cfg.get_section_keys("stats"):
				stats[key] = cfg.get_value("stats", key)
		equipped_hero = cfg.get_value("shop", "hero", "white")
		equipped_wall = cfg.get_value("shop", "wall", "rubble")
		equipped_trail = cfg.get_value("shop", "trail", "afterimage")
		equipped_lava = cfg.get_value("shop", "lava", "classic")
		equipped_hat = cfg.get_value("shop", "hat", "no_hat")
		missions = cfg.get_value("missions", "active", [])
		levels_cleared = cfg.get_value("levels", "cleared", [])
		level_times = cfg.get_value("levels", "times", {})
		level_stars = cfg.get_value("levels", "stars", {})
		custom_levels = cfg.get_value("levels", "custom", [])


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "total_coins", total_coins)
	cfg.set_value("progress", "best_floor", best_floor)
	cfg.set_value("progress", "best_time", best_time)
	cfg.set_value("shop", "owned", owned)
	cfg.set_value("shop", "new", new_items)
	cfg.set_value("shop", "no_forced_ads", ads.no_forced_ads)
	cfg.set_value("ads", "day", ad_coins_day)
	cfg.set_value("ads", "today", ad_coins_today)
	cfg.set_value("shop", "deal_day", deal_day)
	cfg.set_value("shop", "deal_id", deal_id)
	cfg.set_value("gift", "day", gift_day)
	cfg.set_value("vault", "day", vault_day)
	cfg.set_value("vault", "free_used", vault_free_used)
	cfg.set_value("vault", "ads_used", vault_ads_used)
	cfg.set_value("gift", "date", gift_date)
	cfg.set_value("shop", "hero", equipped_hero)
	cfg.set_value("shop", "wall", equipped_wall)
	cfg.set_value("shop", "trail", equipped_trail)
	cfg.set_value("shop", "lava", equipped_lava)
	cfg.set_value("shop", "hat", equipped_hat)
	cfg.set_value("missions", "active", missions)
	cfg.set_value("levels", "cleared", levels_cleared)
	cfg.set_value("levels", "times", level_times)
	cfg.set_value("levels", "stars", level_stars)
	cfg.set_value("levels", "custom", custom_levels)
	cfg.set_value("secret", "meter", trap_meter)
	cfg.set_value("secret", "chest_owed", bonus_chest_owed)
	cfg.set_value("achievements", "unlocked", unlocked)
	cfg.set_value("settings", "sound", sfx.enabled)
	cfg.set_value("settings", "music", sfx.music_enabled)
	cfg.set_value("settings", "sound_volume", sfx.volume)
	cfg.set_value("settings", "music_volume", sfx.music_volume)
	cfg.set_value("settings", "vibration", vibration_on)
	cfg.set_value("settings", "language", language)
	cfg.set_value("daily", "date", daily_date)
	cfg.set_value("daily", "best", daily_best)
	cfg.set_value("daily", "medal", daily_medal)
	cfg.set_value("daily", "floors_today", floors_today)
	cfg.set_value("daily", "floors_day", floors_day)
	cfg.set_value("daily", "time", daily_time)
	cfg.set_value("secret", "pending_chests", pending_chests)
	cfg.set_value("daily", "last_played", daily_last_played)
	cfg.set_value("daily", "streak", daily_streak)
	cfg.set_value("daily", "ghost", daily_ghost)
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
	_draw_powerups(y0, y1)
	_draw_best_marker(top, bottom)
	_draw_hints()
	_draw_ghost()
	_draw_player()
	for b in bursts:
		var k: float = b.t / 0.35
		draw_arc(b.pos, 6.0 + k * 18.0, 0, TAU, 20, Color(b.color, 1.0 - k), 3.0)
	if not is_level():
		_draw_lava(view)


func _draw_tile(c: Vector2i, biome: Dictionary) -> void:
	var t: String = tower.get_tile(c)
	var r := Rect2(Vector2(c) * TILE, Vector2(TILE, TILE))
	var mid := r.get_center()
	match t:
		TowerScript.WALL:
			draw_rect(r, biome.wall)
			if _has_roof(c):
				draw_rect(Rect2(r.position, Vector2(TILE, 4)), biome.edge)
		TowerScript.COIN, TowerScript.FAKE_COIN:
			if t == TowerScript.FAKE_COIN:
				_draw_fake_floor(r, c)
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
		TowerScript.FAKE:
			_draw_fake_floor(r, c)
		TowerScript.GOAL:
			var pulse := 0.5 + 0.5 * sin(anim_time * 5.0)
			draw_circle(mid, 12.0 + pulse * 4.0, Color(COIN_COLOR, 0.35))
			draw_circle(mid, 9.0, COIN_COLOR)
			draw_circle(mid, 4.0, Color.WHITE)


## Whether a wall at `c` shows its lit top edge: only when nothing solid
## sits right above it, so stacked walls read as one block. (Cracked walls
## always keep theirs, so they stand out.)
func _has_roof(c: Vector2i) -> bool:
	var above: String = tower.get_tile(c + Vector2i.UP)
	return above != TowerScript.WALL and above != TowerScript.CRACKED


## Fake floor that will give way looks like normal floor with a dark crack
## that has a subtle white edge, so it stands out without boxing the tile.
## (On normal floors fake tiles are solid and unmarked, so only real traps show.)
func _draw_fake_floor(r: Rect2, _c: Vector2i) -> void:
	var p := r.position
	var main := PackedVector2Array([p + Vector2(7, 8), p + Vector2(13, 14), p + Vector2(12, 18), p + Vector2(18, 22)])
	var branch := PackedVector2Array([p + Vector2(13, 14), p + Vector2(20, 11)])
	for line in [main, branch]:
		draw_polyline(line, Color(1, 1, 1, 0.45), 3.5)
	for line in [main, branch]:
		draw_polyline(line, Color(0, 0, 0, 0.75), 1.5)


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
	if move_dir != Vector2i.ZERO:
		Skins.draw_trail(self, Skins.find(Skins.TRAILS, equipped_trail), p, Vector2(move_dir), size, color, anim_time)
	# Eyes look where you're going.
	var look := Vector2(move_dir if move_dir != Vector2i.ZERO else queued_dir) * 3.0
	Skins.draw_hero_item(self, _hero_skin(), p, size, color, look, anim_time, Vector2(move_dir))
	Skins.draw_hat(self, Skins.find(Skins.HATS, equipped_hat), p, size, anim_time)
	if shield:
		draw_arc(p, TILE * 0.72, 0, TAU, 28, Color(POWERUP_COLORS.shield, 0.6 + 0.3 * sin(anim_time * 6.0)), 2.5)
	if magnet_time > 0.0:
		var reach := (MAGNET_RANGE + 0.5) * TILE
		draw_arc(p, reach * (0.6 + 0.4 * fposmod(anim_time * 1.5, 1.0)), 0, TAU, 40, Color(POWERUP_COLORS.magnet, 0.35), 1.5)


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


## Where today's best Daily Climb run was at this point in the run.
func ghost_position() -> Vector2:
	var t := elapsed / GHOST_STEP
	var i := mini(floori(t), daily_ghost.size() - 1)
	var next := mini(i + 1, daily_ghost.size() - 1)
	return daily_ghost[i].lerp(daily_ghost[next], t - floorf(t))


func _draw_ghost() -> void:
	if not daily_mode or daily_ghost.is_empty() or state == State.READY:
		return
	var p := ghost_position()
	var finished := elapsed / GHOST_STEP >= daily_ghost.size() - 1
	var alpha := 0.15 if finished else 0.35
	Skins.draw_hero(self, p, Vector2(TILE - 6, TILE - 6), Color(0.85, 0.95, 1.0), Vector2.ZERO, alpha)
	var font := ThemeDB.fallback_font
	var label := "BEST"
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	draw_string(font, p - Vector2(size.x * 0.5, TILE * 0.6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, alpha + 0.2))


func _draw_powerups(y0: int, y1: int) -> void:
	for c: Vector2i in powerups:
		if c.y < y0 or c.y > y1:
			continue
		var kind: String = powerups[c]
		var color: Color = POWERUP_COLORS[kind]
		var mid := _tile_center(c) + Vector2(0, sin(anim_time * 3.0 + c.x) * 2.0)
		draw_circle(mid, TILE * 0.55, Color(color, 0.18 + 0.08 * sin(anim_time * 5.0)))
		draw_circle(mid, TILE * 0.4, Color(0.08, 0.08, 0.14))
		draw_arc(mid, TILE * 0.4, 0, TAU, 24, color, 2.0)
		_draw_powerup_icon(kind, mid, TILE * 0.22, color)


func _draw_powerup_icon(kind: String, mid: Vector2, r: float, color: Color) -> void:
	match kind:
		"shield":
			draw_colored_polygon(PackedVector2Array([
				mid + Vector2(-r, -r * 0.8), mid + Vector2(r, -r * 0.8), mid + Vector2(r * 0.8, r * 0.3),
				mid + Vector2(0, r * 1.1), mid + Vector2(-r * 0.8, r * 0.3),
			]), color)
		"magnet":
			draw_arc(mid + Vector2(0, -r * 0.1), r * 0.75, 0, PI, 12, color, r * 0.55)
			draw_line(mid + Vector2(-r * 0.75, -r * 0.1), mid + Vector2(-r * 0.75, -r), color, r * 0.55)
			draw_line(mid + Vector2(r * 0.75, -r * 0.1), mid + Vector2(r * 0.75, -r), color, r * 0.55)
			draw_line(mid + Vector2(-r * 0.75, -r * 0.75), mid + Vector2(-r * 0.75, -r * 1.05), Color.WHITE, r * 0.55)
			draw_line(mid + Vector2(r * 0.75, -r * 0.75), mid + Vector2(r * 0.75, -r * 1.05), Color.WHITE, r * 0.55)
		"freeze":
			for i in 3:
				var d := Vector2.from_angle(i * PI / 3.0) * r * 1.1
				draw_line(mid - d, mid + d, color, 2.0)


func _draw_lava(view: Vector2) -> void:
	# Frozen lava turns icy blue, thawing back over its last second.
	Skins.draw_lava(self, Skins.find(Skins.LAVA, equipped_lava), -view.x, tower.width * TILE + view.x,
			lava_y, lava_y + view.y * 2, anim_time, clampf(freeze_time, 0.0, 1.0))


# --- Levels ----------------------------------------------------------------

func is_level() -> bool:
	return not level.is_empty()


## Plays a level instead of the tower. `source` is "campaign" (with its
## `index`), "custom" or "test" (straight from the editor).
func start_level(lv: Dictionary, source: String, index := -1) -> void:
	level = lv
	level_source = source
	level_index = index
	daily_mode = false
	levels_screen.visible = false
	level_editor.visible = false
	reset()


func start_campaign_level(i: int) -> void:
	if i >= 0 and i < Levels.LEVELS.size():
		start_level(Levels.level(i), "campaign", i)


func campaign_unlocked(i: int) -> bool:
	return i == 0 or levels_cleared.has(i - 1)


func level_title() -> String:
	if level_source == "campaign":
		return tr("Level %d") % (level_index + 1) + ": " + tr(level.name)
	return level.name if level.name != "" else tr("Untitled level")


func total_stars() -> int:
	var n := 0
	for i in level_stars:
		n += Levels.star_count(level_stars[i])
	return n


## "★★☆" for a campaign level's best.
func stars_text(i: int) -> String:
	var n := Levels.star_count(level_stars.get(i, 0))
	return "★".repeat(n) + "☆".repeat(Levels.STARS_PER_LEVEL - n)


func _level_best_text() -> String:
	var text := tr("Time limit: %s") % _clock(level.time)
	if level_source == "campaign":
		text += "\n" + tr("★ Under %d s   ★ Every coin") % Levels.par(level_index)
		var best: float = level_times.get(level_index, 0.0)
		if best > 0.0:
			text += "\n" + tr("Best: %.1f s") % best
		elif not levels_cleared.has(level_index):
			text += "\n" + tr("Reward: %s") % Achievements.reward_text(Levels.LEVELS[level_index].reward)
	return text


## Back to the tower, and to the levels list or the editor it came from.
func _leave_level() -> void:
	var from_editor := level_source == "test"
	level = {}
	level_source = ""
	reset()
	if from_editor:
		level_editor.open_again()
	else:
		_open_levels()


func _open_levels() -> void:
	sfx.play("open")
	levels_screen.open()


## A level that fits on screen sits still, centred under the HUD. A bigger
## one scrolls with the hero, along whichever direction doesn't fit, and
## never past its edges.
func _level_camera() -> Vector2:
	var view := get_viewport_rect().size
	var w := tower.width * TILE
	var h: float = tower.height * TILE
	var p := _player_center()
	var target := Vector2(w * 0.5, -h * 0.5 - (LEVEL_HUD_GAP - LEVEL_FOOT_GAP) * 0.5)
	if w > view.x:
		target.x = clampf(p.x, view.x * 0.5, w - view.x * 0.5)
	if h > view.y - LEVEL_HUD_GAP - LEVEL_FOOT_GAP:
		var highest: float = -h + view.y * 0.5 - LEVEL_HUD_GAP
		var lowest := -view.y * 0.5 + LEVEL_FOOT_GAP
		target.y = clampf(p.y, highest, lowest)
	return target


func _clock(seconds: float) -> String:
	var s := ceili(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _level_won() -> void:
	state = State.WON
	state_time = 0.0
	move_dir = Vector2i.ZERO
	queued_dir = Vector2i.ZERO
	sfx.play("level_clear")
	vibrate(60)
	_celebrate("")
	var lines: Array = [tr("LEVEL CLEAR!"), "%s   ● %d/%d" % [tr("%.1f seconds") % elapsed, run_coins, level_coins]]
	match level_source:
		"campaign":
			var earned := Levels.STAR_CLEAR
			if elapsed <= Levels.par(level_index):
				earned |= Levels.STAR_PAR
			if run_coins >= level_coins:
				earned |= Levels.STAR_COINS
			var had: int = level_stars.get(level_index, 0)
			level_stars[level_index] = had | earned
			lines[0] = "%s   %s" % [tr("LEVEL CLEAR!"), "★".repeat(Levels.star_count(earned)) + "☆".repeat(Levels.STARS_PER_LEVEL - Levels.star_count(earned))]
			if (had | earned) != had and had != 0:
				lines.append(tr("New star!"))
			var best: float = level_times.get(level_index, 0.0)
			if best == 0.0 or elapsed < best:
				level_times[level_index] = snappedf(elapsed, 0.1)
				if best > 0.0:
					lines.append(tr("New best time!"))
			if not levels_cleared.has(level_index):
				levels_cleared.append(level_index)
				var reward: Dictionary = Levels.LEVELS[level_index].reward
				_grant_level_reward(reward)
				lines.append(tr("Reward: %s") % Achievements.reward_text(reward))
			check_achievements()
			_save()
		"test":
			level_editor.mark_tested()
	lines.append("")
	lines.append(tr("Swipe to play again"))
	_show_message("\n".join(lines))


func _grant_level_reward(reward: Dictionary) -> void:
	if reward.has("coins"):
		total_coins += reward.coins
	elif not owned.has(reward.item[1]):
		owned.append(reward.item[1])
		mark_new(reward.item[1])
	check_achievements()


func _level_lost(cause: String) -> void:
	state = State.DEAD
	state_time = 0.0
	move_dir = Vector2i.ZERO
	queued_dir = Vector2i.ZERO
	sfx.play("time_up" if cause == "time" else "death")
	vibrate(150)
	shake = 0.35
	var reason := {"spikes": "Spiked!", "fake": "The floor gave way!", "time": "Out of time!"}.get(cause, "Out of time!") as String
	_show_message("%s\n\n%s" % [tr(reason), tr("Swipe to try again")])


## Adds a level the player made or was sent to their list (or updates it
## in place at `index`). Returns its place in the list.
func save_custom_level(lv: Dictionary, index := -1) -> int:
	var code := LevelCode.encode(lv)
	if index >= 0 and index < custom_levels.size():
		custom_levels[index] = code
	else:
		custom_levels.append(code)
		index = custom_levels.size() - 1
	_save()
	return index


func delete_custom_level(index: int) -> void:
	if index >= 0 and index < custom_levels.size():
		custom_levels.remove_at(index)
		_save()
