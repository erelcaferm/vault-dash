extends SceneTree
## Plays the game from a brand-new save as a simulated person, to measure how
## fast coins come in and how long each shop item takes to earn.
##
## The player plays the real game (the same main scene, missions, trophies,
## chests, daily gift and Daily Climb) for DAYS days of MINUTES minutes each.
## How they play:
## - Each swipe follows a route to two floors up, planned from where they
##   stand, after a short think (longer when a new floor scrolls in).
## - They grab coins: when a slide off the route would pick some up and they
##   can still get out from where it ends, they usually take it.
## - Now and then they swipe the wrong way, and sometimes that wrong way is
##   into spikes or a cracked tile, which ends the run. Mistakes get rarer as
##   they get better over the days.
## - They wait for moving blocks, spikes and lasers to clear before sliding.
## - Each day they claim the daily gift, play the Daily Climb once, try the
##   vault once and clear a couple of the handmade levels (until there are
##   none left). With "ads" they also watch the shop's coin ads and double
##   about one run in three.
## - Time between runs (menus, chests opening, deciding) counts as play time.
## - Whenever they can afford the next item on their wish list they buy it.
##
## Run: godot --headless --path . --script res://tools/economy_sim.gd -- [ads] [days=7] [minutes=30] [skill=casual|good|beginner] [out=report.txt]
## Prints coins per minute, where the coins came from, minutes of play to
## afford each price tier and a buying timeline.

const Solver := preload("res://scripts/solver.gd")
const Skins := preload("res://scripts/skins.gd")
const Chest := preload("res://scripts/chest.gd")
const DailyGift := preload("res://scripts/daily_gift.gd")
const Levels := preload("res://scripts/levels.gd")
const Vault := preload("res://scripts/vault_game.gd")
const TowerScript := preload("res://scripts/tower.gd")
var SAVE := "user://economy_sim_%d.cfg" % OS.get_process_id()
const DT := 1.0 / 30.0
## [name, think per swipe, extra think on a new floor, wrong swipe chance on day 1, by day 7,
##  chance a wrong swipe is a deadly one when one is there, coin greed]
const SKILLS := {
	"beginner": [1.2, 1.6, 0.10, 0.06, 0.45, 0.6],
	"casual": [0.85, 1.2, 0.07, 0.04, 0.35, 0.75],
	"good": [0.55, 0.8, 0.04, 0.02, 0.25, 0.85],
}
const BETWEEN_RUNS := 6.0        # seconds on the death screen and menu
const PER_CHEST := 5.0           # seconds watching a chest spin
const PER_LEVEL := 90.0          # seconds a handmade level takes, with retries
const LEVELS_PER_DAY := 2
const DAILY_CLIMB := 120.0       # seconds for one Daily Climb

var game
var rng := RandomNumberGenerator.new()
var skill: Array
var day := 0
var days := 7
var minutes := 30.0
var with_ads := false
var play_time := 0.0             # seconds of the player's time, all of it
var earned := {}                 # where coins came from
var timeline: Array = []         # [minute, item name, price, how it came]
var wish: Array = []
var runs: Array = []             # floors reached each run
var mistakes := 0.0
var last_total := 0
var report := ""
var out_path := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	with_ads = args.has("ads")
	var skill_name := "casual"
	for a: String in args:
		if a.begins_with("days="):
			days = int(a.substr(5))
		elif a.begins_with("minutes="):
			minutes = float(a.substr(8))
		elif a.begins_with("skill="):
			skill_name = a.substr(6)
		elif a.begins_with("out="):
			out_path = a.substr(4)
	skill = SKILLS[skill_name]
	rng.seed = 2026
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame
	wish = _wish_list()
	last_total = game.total_coins
	_out("Simulating a %s player%s, %d days x %d min" % [skill_name, " who watches ads" if with_ads else "", days, minutes])
	for d in days:
		day = d
		game.test_today = "2026-11-%02d" % (d + 1)
		var day_end := play_time + minutes * 60.0
		_daily_extras()
		while play_time < day_end:
			_play_run()
			_shop()
	_report()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	# Quitting normally can hang on the game's leftover nodes, so flush the
	# report and stop.
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(report)
		f.close()
	OS.kill(OS.get_process_id())


## What a typical player saves up for, in order: a cheap colour first, then a
## mix of whatever catches their eye, the big-ticket items last.
func _wish_list() -> Array:
	var items: Array = []
	for kind in ["hero", "hat", "trail", "walls", "lava"]:
		for item in Skins.list(kind):
			if item.price > 0:
				items.append([kind, item])
	# Shuffle, then sort loosely by price so they climb the price ladder with
	# the odd splurge, like a real player browsing the shop.
	var r := RandomNumberGenerator.new()
	r.seed = 99
	items.sort_custom(func(a, b): return a[1].price * r.randf_range(0.6, 1.4) < b[1].price * r.randf_range(0.6, 1.4))
	return items


func _shop() -> void:
	while not wish.is_empty():
		var pick: Array = wish[0]
		if game.owns(pick[1]):
			wish.pop_front()
			continue
		if game.total_coins < game.price(pick[1]):
			return
		_note_income()
		game.buy(pick[0], pick[1])
		last_total = game.total_coins
		timeline.append([play_time / 60.0, pick[1].name, pick[1].price, "bought"])
		wish.pop_front()


## Books coins that turned up since the last check under `source`.
func _note_income(source := "other") -> void:
	var gain: int = game.total_coins - last_total
	if gain != 0:
		earned[source] = earned.get(source, 0) + gain
	last_total = game.total_coins


func _daily_extras() -> void:
	_note_income()
	game.daily_gift.visible = false
	if game.gift_ready():
		var gift: Dictionary = DailyGift.GIFTS[game.gift_day]
		game._claim_gift(gift)
		_finish_chests()
		play_time += 5.0
	_note_income("daily gift")
	# The vault: a casual player opens one or two tumblers.
	game.total_coins += Vault.PRIZES[rng.randi_range(1, 2)]
	play_time += 20.0
	_note_income("vault")
	# The Daily Climb, finished for bronze or silver.
	game.daily_mode = true
	game.reset()
	_climb(true)
	game.daily_mode = false
	game.reset()
	_note_income("daily climb")
	# A couple of handmade levels, each paid once.
	for i in LEVELS_PER_DAY:
		var n: int = day * LEVELS_PER_DAY + i
		if n >= Levels.LEVELS.size():
			break
		var reward: Dictionary = Levels.LEVELS[n].reward
		if reward.has("coins"):
			game.total_coins += reward.coins
		play_time += PER_LEVEL
	_note_income("levels")
	if with_ads:
		for i in game.ad_coins_left():
			game._shop_coins_now()
			play_time += 30.0
		_note_income("ads")


func _play_run() -> void:
	game.test_seed = rng.randi()
	game.reset()
	var before: int = game.total_coins
	_climb(false)
	runs.append(game.run_floor)
	earned["tower runs"] = earned.get("tower runs", 0) + game.run_coins
	last_total += game.run_coins
	_note_income("missions + trophies")
	if with_ads and game.run_coins > 0 and rng.randf() < 0.33:
		game._double_coins_now()
		play_time += 30.0
		_note_income("ads")
	_finish_chests()
	_note_income("chests")
	play_time += BETWEEN_RUNS
	game.reset()
	_note_income("missions + trophies")
	var _unused := before


## Opens every saved chest, as the player taps through them.
func _finish_chests() -> void:
	for guard in 50:
		if game.pending_chests <= 0 and not game.chest_screen.visible:
			return
		if not game.chest_screen.visible:
			game._open_next_chest(game.state if game.state != game.State.CHEST else game.State.DEAD)
		var cs = game.chest_screen
		cs._reveal()
		var reward: Dictionary = cs._reward
		cs.visible = false
		_note_income()
		cs.finished.emit(reward)
		if reward.kind != "coins":
			timeline.append([play_time / 60.0, reward.item.name, reward.item.price, "chest"])
		_note_income("chests")
		play_time += PER_CHEST


## Plays one run until the player dies (or finishes the daily).
func _climb(daily: bool) -> void:
	var wrong: float = lerpf(skill[2], skill[3], clampf(day / 6.0, 0.0, 1.0))
	var plan: Array = []
	var wait: float = skill[0] + skill[1]
	var room := 0
	var detours := 0
	var t := 0.0
	var started := false
	while t < 1800.0:
		if game.state == game.State.DEAD or game.state == game.State.WON:
			break
		if game.state == game.State.CHEST:
			_finish_chests()
		if started:
			t += DT
			play_time += DT
			game._process(DT)
			if game.state != game.State.PLAYING:
				continue
		if not game.is_idle():
			continue
		wait -= DT
		if wait > 0.0:
			continue
		var k: int = game.tower.room_of(game.cell.y)
		if k != room:
			room = k
			detours = 0
			plan.clear()
		var dir := Vector2i.ZERO
		# A wrong swipe, sometimes a deadly one.
		if rng.randf() < wrong:
			mistakes += 1
			var deadly: Array = []
			var other: Array = []
			for d: Vector2i in Solver.DIRS:
				var r: Dictionary = game.tower.simulate_slide(game.cell, d)
				if r.dead:
					deadly.append(d)
				elif r.end != game.cell:
					other.append(d)
			if not deadly.is_empty() and rng.randf() < skill[4]:
				dir = deadly[0]
			elif not other.is_empty():
				dir = other[rng.randi_range(0, other.size() - 1)]
			plan.clear()
		if dir == Vector2i.ZERO and detours < 3 and rng.randf() < skill[5]:
			dir = _coin_detour()
			if dir != Vector2i.ZERO:
				detours += 1
				plan.clear()
		if dir == Vector2i.ZERO:
			if plan.is_empty():
				plan = _plan(daily)
			if plan.is_empty():
				break    # stuck: they give up on this run
			dir = plan.pop_front()
		if not _safe(dir):
			wait = 0.2
			continue
		if not started:
			started = true
		game._on_swipe(dir)
		wait = skill[0]
		if game.tower.room_of(game.tower.simulate_slide(game.cell, dir).end.y) != room:
			wait += skill[1]
	if game.state == game.State.PLAYING:
		game._die("Gave up on floor %d", "lava")


## The shortest route from here to two floors up (or to the daily's top).
func _plan(daily: bool) -> Array:
	var tower = game.tower
	var saved_start: Vector2i = tower.start
	var saved_limit: int = tower.room_limit
	var k: int = tower.room_of(game.cell.y)
	tower.start = game.cell
	if not daily or saved_limit < 0:
		tower.room_limit = k + 2
	else:
		tower.room_limit = mini(k + 2, saved_limit)
	var solver = Solver.new(tower)
	solver.upward_only = true
	solver.max_states = 20000
	solver.run()
	tower.start = saved_start
	tower.room_limit = saved_limit
	return solver.solution.duplicate()


## A slide that picks up a coin and still leaves a way out, if there is one.
func _coin_detour() -> Vector2i:
	var best := Vector2i.ZERO
	var most := 0
	for d: Vector2i in Solver.DIRS:
		var r: Dictionary = game.tower.simulate_slide(game.cell, d)
		if r.dead or r.won or r.end == game.cell:
			continue
		var coins := 0
		var c: Vector2i = game.cell
		while c != r.end:
			c += d
			if game.tower.get_tile(c) == TowerScript.COIN:
				coins += 1
		if coins > most:
			most = coins
			best = d
	if best == Vector2i.ZERO:
		return best
	# Only if they can still get out from where it ends.
	var saved: Vector2i = game.cell
	game.cell = game.tower.simulate_slide(saved, best).end
	var ok := not _plan(false).is_empty()
	game.cell = saved
	return best if ok else Vector2i.ZERO


## Whether a slide is clear of moving blocks, spikes and lasers right now.
func _safe(dir: Vector2i) -> bool:
	var hz = game.hazards
	if hz == null or (hz.movers.is_empty() and hz.traps.is_empty() and hz.lasers.is_empty()):
		return true
	var start: Vector2i = game.cell
	var end: Vector2i = game.tower.simulate_slide(start, dir).end
	if end == start:
		return true
	var length := float((end - start).length())
	var saved: Array = hz.movers.duplicate(true)
	var saved_lasers: Array = hz.lasers.duplicate(true)
	var saved_time: float = hz.time
	var saved_rng: int = hz.rng.state
	var ok := true
	var progress := 0.0
	var entered := 0
	for i in 400:
		progress = minf(progress + game.SLIDE_SPEED * DT, length)
		while entered < floori(progress):
			entered += 1
			var c: Vector2i = start + dir * entered
			if hz.trap_state(c) != 0:
				ok = false
			for l in hz.lasers:
				if hz._in_beam(l, c) and hz.laser_state(l) == 2:
					ok = false
		var resting := progress >= length
		hz.update(DT, end if resting else Vector2i(-1, -1), 0)
		var p := Vector2(start) + Vector2(dir) * progress
		for m in hz.movers:
			var d: Vector2 = (m.pos - p).abs()
			if d.x < hz.HIT_SIZE + 0.3 and d.y < hz.HIT_SIZE + 0.3:
				ok = false
		if not ok or resting:
			break
	hz.movers = saved
	hz.lasers = saved_lasers
	hz.time = saved_time
	hz.rng.state = saved_rng
	return ok


func _report() -> void:
	var mins := play_time / 60.0
	var total := 0
	for v in earned.values():
		total += v
	_out("\nPlayed %.0f min, %d runs, earned %d coins = %.1f coins/min" % [mins, runs.size(), total, total / mins])
	var sorted := runs.duplicate()
	sorted.sort()
	if not sorted.is_empty():
		_out("Floors per run: median %d, best %d, average %.1f" % [sorted[sorted.size() / 2], sorted[-1], _avg(runs)])
	for src in earned:
		_out("  %-20s %6d  (%.0f%%)" % [src, earned[src], 100.0 * earned[src] / maxf(total, 1)])
	var rate := total / mins
	_out("\nMinutes of play to afford:")
	for p in [300, 500, 750, 1000, 1500, 2000, 3000, 4500, 6000]:
		_out("  %5d coins  %5.0f min" % [p, p / rate])
	_out("\nUnlocks (minute, item, price, how):")
	for e in timeline:
		_out("  %6.1f  %-18s %5d  %s" % e)
	var bought := timeline.filter(func(e): return e[3] == "bought")
	_out("Bought %d items, %d more from %d chests" % [bought.size(), timeline.size() - bought.size(), game.stat("chests_opened")])
	if not bought.is_empty():
		_out("Minutes per purchase: %.1f overall, %.1f after the first hour" % [mins / bought.size(),
			(mins - 60.0) / maxf(bought.filter(func(e): return e[0] > 60.0).size(), 1)])
	_out("Minutes per unlock of any kind: %.1f" % (mins / maxf(timeline.size(), 1)))
	_out("Coins left: %d" % game.total_coins)
	var causes := {}
	for id in game.stats:
		if str(id).begins_with("deaths_"):
			causes[id] = game.stats[id]
	_out("Deaths: ", causes, "  wrong swipes: ", mistakes)


func _avg(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(a.size(), 1)


func _out(a = "", b = "", c = "", d = "") -> void:
	var line := str(a) + str(b) + str(c) + str(d)
	print(line)
	report += line + "\n"
