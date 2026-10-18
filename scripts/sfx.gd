extends Node
## Sound effects, made from code at startup so the game needs no audio files.
## Swap any of them for a real recording later by loading it into `sounds`.

const RATE := 22050

var enabled := true
var sounds := {}
var _players: Array = []
var _next := 0


func _ready() -> void:
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
		"trap": _make(0.4, func(t, _n): return sin(TAU * (220.0 + 30.0 * sin(TAU * 6.0 * t)) * t) * 0.3 * _fade(t, 0.4)),
	}


func play(id: String, pitch := 1.0) -> void:
	if not enabled or not sounds.has(id):
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
