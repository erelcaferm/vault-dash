extends Node
## Sound effects, made from code at startup so the game needs no audio files.
## Swap any of them for a real recording later by loading it into `sounds`.
## Also plays the background music loop (sounds/music.wav, written by
## tools/make_music.gd), which has its own on/off switch. Both have a
## volume slider in Settings, from 0 to 1.

const RATE := 22050

var enabled := true
var music_enabled := true
var music: AudioStreamPlayer
var volume := 1.0                    # sound effects
var music_volume := 1.0
const MUSIC_DB := -11.0
const MUSIC_QUIET_DB := -20.0        # while paused or in a menu screen
var sounds := {}
var _players: Array = []
var _next := 0


func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.stream = load("res://sounds/music.wav")
	music.volume_db = MUSIC_DB
	add_child(music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	sounds = {
		"swipe": _make(0.09, func(t, n): return _noise(n) * 0.35 * _fade(t, 0.09) * (1.0 - t / 0.09)),
		"stop": _make(0.07, func(t, _n): return sin(TAU * 110.0 * t) * 0.6 * _fade(t, 0.07)),
		"coin": _make(0.16, func(t, _n):
			var f := 988.0 if t < 0.05 else 1319.0
			return _square(f, t) * 0.18 * _fade(t, 0.16)),
		"break": _make(0.2, func(t, n): return (_noise(n) * 0.5 + sin(TAU * 70.0 * t) * 0.5) * _fade(t, 0.2)),
		"death": _make(0.55, func(t, _n):
			var f := lerpf(420.0, 70.0, t / 0.55)
			return _square(f, t) * 0.22 * _fade(t, 0.55)),
		"tick": _make(0.025, func(t, _n): return sin(TAU * 2200.0 * t) * 0.35 * _fade(t, 0.025)),
		"reward": _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.09),
		"trophy": _arpeggio([783.99, 987.77, 1174.66, 1567.98], 0.07),
		"heartbeat": _make(0.32, func(t, _n):
			var beat: float = t if t < 0.12 else t - 0.17
			var env: float = maxf(0.0, 1.0 - beat / 0.1) if beat >= 0.0 else 0.0
			return sin(TAU * 55.0 * t) * 0.7 * env),
		"trap": _make(0.4, func(t, _n): return sin(TAU * (220.0 + 30.0 * sin(TAU * 6.0 * t)) * t) * 0.3 * _fade(t, 0.4)),
		# Menus and buttons.
		"click": _make(0.035, func(t, _n): return sin(TAU * lerpf(1400.0, 900.0, t / 0.035) * t) * 0.3 * _fade(t, 0.035)),
		"buy": _arpeggio([1318.5, 1760.0, 2093.0], 0.05),
		"error": _make(0.22, func(t, _n):
			var f := 180.0 if t < 0.1 else 140.0
			return _square(f, t) * 0.14 * _fade(t, 0.22)),
		"open": _make(0.12, func(t, n): return (_noise(n) * 0.15 + sin(TAU * lerpf(300.0, 700.0, t / 0.12) * t) * 0.25) * _fade(t, 0.12)),
		# Levels.
		"countdown": _make(0.08, func(t, _n): return sin(TAU * 1760.0 * t) * 0.3 * _fade(t, 0.08)),
		"time_up": _make(0.6, func(t, _n): return (_square(110.0, t) * 0.5 + _square(116.5, t) * 0.5) * 0.18 * _fade(t, 0.6)),
		"level_clear": _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98, 2093.0], 0.075),
		"start": _arpeggio([392.0, 523.25], 0.07),
		# The level editor.
		"paint": _make(0.03, func(t, _n): return _square(660.0, t) * 0.08 * _fade(t, 0.03)),
		"erase": _make(0.04, func(t, n): return _noise(n) * 0.18 * _fade(t, 0.04)),
	}


## Starts or stops the music to match `music_enabled`.
func update_music() -> void:
	if music_enabled and not music.playing:
		music.play()
	elif not music_enabled and music.playing:
		music.stop()


## `speed` 1.0 is normal; above it the music plays faster (and a little
## higher), to build tension. `quiet` turns it down behind menus.
func set_music_mood(speed: float, quiet: bool) -> void:
	music.pitch_scale = move_toward(music.pitch_scale, speed, 0.01)
	var target := (MUSIC_QUIET_DB if quiet else MUSIC_DB) + _db(music_volume)
	music.volume_db = move_toward(music.volume_db, target, 0.5)


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	for p: AudioStreamPlayer in _players:
		p.volume_db = _db(volume)


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	music.volume_db = MUSIC_DB + _db(music_volume)


## Slider position to decibels. Squared, so the slider feels even to the ear.
static func _db(v: float) -> float:
	return maxf(linear_to_db(v * v), -60.0) if v > 0.0 else -80.0


func play(id: String, pitch := 1.0) -> void:
	if not enabled or volume <= 0.0 or not sounds.has(id):
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = sounds[id]
	p.pitch_scale = pitch
	p.play()


func _make(length: float, wave: Callable) -> AudioStreamWAV:
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		var v: float = wave.call(float(i) / RATE, rng.randf())
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream


func _arpeggio(notes: Array, step: float) -> AudioStreamWAV:
	var length := step * notes.size() + 0.15
	return _make(length, func(t, _n):
		var i := mini(floori(t / step), notes.size() - 1)
		return _square(notes[i], t) * 0.16 * _fade(t, length))


static func _square(freq: float, t: float) -> float:
	return 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0


static func _noise(n: float) -> float:
	return n * 2.0 - 1.0


## A quick attack and a smooth release, so sounds don't click.
static func _fade(t: float, length: float) -> float:
	return minf(t / 0.004, 1.0) * clampf((length - t) / (length * 0.6), 0.0, 1.0)
