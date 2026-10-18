extends SceneTree
## Writes the background music loop, sounds/music.wav: 16 seconds of
## chiptune in A minor at 120 BPM (bass, lead, drums), made from code like
## the sound effects. Change the notes below and rerun to make a new tune.
## Run: godot --headless --path . --script res://tools/make_music.gd

const RATE := 22050
const STEP := 0.125                  # one sixteenth note at 120 BPM
const STEPS_PER_BAR := 16
## One chord root per bar, as MIDI notes (A2 = 45).
const ROOTS := [45, 41, 48, 43, 45, 41, 43, 40]
## The lead: one note per eighth (8 per bar), 0 = rest. A minor pentatonic.
const LEAD := [
	69, 0, 72, 74, 76, 0, 74, 72,
	69, 0, 72, 0, 77, 76, 74, 72,
	72, 0, 76, 79, 81, 0, 79, 76,
	74, 0, 79, 0, 74, 72, 71, 74,
	69, 0, 72, 74, 76, 0, 79, 76,
	77, 0, 76, 74, 72, 0, 69, 72,
	74, 0, 71, 74, 79, 0, 77, 74,
	76, 0, 75, 76, 71, 0, 68, 0,
]


func _initialize() -> void:
	var bars := ROOTS.size()
	var count := int(bars * STEPS_PER_BAR * STEP * RATE)
	var mix := PackedFloat32Array()
	mix.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for step in bars * STEPS_PER_BAR:
		var bar := step / STEPS_PER_BAR
		var in_bar := step % STEPS_PER_BAR
		var at := int(step * STEP * RATE)
		# Bass: eighth notes, jumping an octave on the off-beats.
		if in_bar % 2 == 0:
			var note: int = ROOTS[bar] + (12 if in_bar % 4 == 2 else 0)
			_tone(mix, at, STEP * 1.8, _freq(note), 0.16, "pulse")
		# Lead.
		if in_bar % 2 == 0:
			var lead: int = LEAD[bar * 8 + in_bar / 2]
			if lead > 0:
				_tone(mix, at, STEP * 1.9, _freq(lead), 0.09, "square")
		# Drums: kick on 1 and 3, snare on 2 and 4, hats on the eighths.
		if in_bar % 8 == 0:
			_kick(mix, at)
		if in_bar % 8 == 4:
			_noise(mix, at, 0.12, 0.22, rng)
		if in_bar % 2 == 0:
			_noise(mix, at, 0.03, 0.06, rng)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.save_to_wav("res://sounds/music.wav")
	print("saved sounds/music.wav, %.1f s" % (float(count) / RATE))
	quit()


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


func _tone(mix: PackedFloat32Array, at: int, length: float, freq: float, volume: float, shape: String) -> void:
	var n := int(length * RATE)
	for i in n:
		if at + i >= mix.size():
			return
		var t := float(i) / RATE
		var phase := fmod(t * freq, 1.0)
		var duty := 0.25 if shape == "pulse" else 0.5
		var v := 1.0 if phase < duty else -1.0
		var env := minf(t / 0.005, 1.0) * pow(1.0 - float(i) / n, 1.5)
		mix[at + i] += v * volume * env


func _kick(mix: PackedFloat32Array, at: int) -> void:
	var n := int(0.15 * RATE)
	var phase := 0.0
	for i in n:
		if at + i >= mix.size():
			return
		var t := float(i) / RATE
		phase += lerpf(150.0, 45.0, t / 0.15) / RATE
		mix[at + i] += sin(TAU * phase) * 0.45 * (1.0 - t / 0.15)


func _noise(mix: PackedFloat32Array, at: int, length: float, volume: float, rng: RandomNumberGenerator) -> void:
	var n := int(length * RATE)
	for i in n:
		if at + i >= mix.size():
			return
		mix[at + i] += (rng.randf() * 2.0 - 1.0) * volume * pow(1.0 - float(i) / n, 2.0)
