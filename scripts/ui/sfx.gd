extends RefCounted
## Tiny procedural sound kit: every sound is synthesized in code, so there are no audio
## files to license. Replace any of these later with real recordings (see docs/art/ASSETS.md):
## put e.g. res://assets/audio/dice.ogg in place and it will be used instead.
##
## Usage: Sfx.play(any_node, "dice")   Sfx.music(any_node)   (ambient drone loop)

const RATE := 22050
const VOLUME_DB := -6.0

static var _cache := {}
static var muted := false


static func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(0, value)
static var _music_player: AudioStreamPlayer
static var _music_mood := ""
static var _music_cache := {}

## Each place has its own tune: [bpm, root Hz, scale (semitones), instrument, drums, pad, noise]
const MOODS := {
	"town": [70, 110.0, [0, 3, 5, 7, 10], "pluck", false, true, ""],
	"deadwood": [60, 98.0, [0, 2, 3, 7, 8], "bell", false, true, "wind"],
	"swamp": [54, 82.4, [0, 1, 3, 5, 7, 8], "bass", false, true, "bubbles"],
	"deepforest": [84, 130.8, [0, 2, 3, 5, 7, 9, 10], "pluck", false, true, "wind"],
	"coast": [64, 146.8, [0, 2, 3, 5, 7, 8, 10], "bell", false, true, "waves"],
	"snow": [72, 196.0, [0, 2, 4, 6, 7, 9, 11], "bell", false, true, "wind"],
	"volcanic": [92, 73.4, [0, 1, 4, 5, 7, 8], "bass", true, true, "rumble"],
	"wasteland": [50, 61.7, [0, 1, 3, 6, 7, 10], "bell", false, true, "wind"],
	"battle": [120, 110.0, [0, 3, 5, 7, 10], "pluck", true, false, ""],
	"boss": [132, 98.0, [0, 1, 3, 5, 7, 8], "bass", true, true, ""],
}


static func play(node: Node, sound: String, volume_db: float = VOLUME_DB) -> void:
	if node == null or not node.is_inside_tree():
		return
	var stream := _stream(sound)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.autoplay = true
	p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	p.finished.connect(p.queue_free)
	node.get_tree().root.add_child.call_deferred(p)  # deferred: the root may be busy while a scene starts


## Plays the tune for a place (see MOODS), cross-fading from the previous one.
## A real track at res://assets/audio/music_<mood>.ogg replaces the generated one.
static func music(node: Node, mood: String = "town") -> void:
	if node == null or not node.is_inside_tree() or mood == _music_mood:
		return
	_music_mood = mood
	var root := node.get_tree().root
	var old := _music_player
	_music_player = AudioStreamPlayer.new()
	var file := "res://assets/audio/music_%s.ogg" % mood
	if ResourceLoader.exists(file):
		_music_player.stream = load(file)
	else:
		if not _music_cache.has(mood):
			_music_cache[mood] = _compose(mood)
		_music_player.stream = _music_cache[mood]
	_music_player.volume_db = -40.0
	_music_player.autoplay = true
	_music_player.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	root.add_child.call_deferred(_music_player)  # deferred: the root is busy while the first scene starts
	var tw := root.create_tween()
	tw.tween_property(_music_player, "volume_db", -13.0, 1.5)
	if old != null and is_instance_valid(old):
		var tw2 := root.create_tween()
		tw2.tween_property(old, "volume_db", -50.0, 1.5)
		tw2.tween_callback(old.queue_free)


const MUSIC_RATE := 16000


## Composes a short looping tune: a pad on the root, a wandering melody in the mood's scale,
## optional drums and an ambient texture (wind, waves, bubbles, rumble).
static func _compose(mood: String) -> AudioStreamWAV:
	var m: Array = MOODS.get(mood, MOODS["town"])
	var bpm: float = m[0]
	var root_hz: float = m[1]
	var scale: Array = m[2]
	var beat := 60.0 / bpm
	var beats := 16
	var n := int(MUSIC_RATE * beat * beats)
	var buf := PackedFloat32Array()
	buf.resize(n)
	buf.fill(0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mood)
	# Pad: root and fifth, slowly breathing.
	if m[5]:
		for i in n:
			var t := float(i) / MUSIC_RATE
			var swell := 0.55 + 0.45 * sin(TAU * t / (beat * beats))
			buf[i] += (sin(TAU * root_hz * 0.5 * t) * 0.16 + sin(TAU * root_hz * 0.75 * t) * 0.07) * swell
	# Melody: a random walk through the scale, with rests.
	var degree := 0
	var step_beats := 1.0 if bpm < 80 else 0.5
	var steps := int(beats / step_beats)
	for k in steps:
		if rng.randf() < 0.28:
			continue
		degree = clamp(degree + rng.randi_range(-2, 2), -2, scale.size() + 2)
		var octave := 1 + int(floor(float(degree) / scale.size()))
		var semis: int = scale[posmod(degree, scale.size())] + 12 * octave
		var f := root_hz * pow(2.0, semis / 12.0)
		var start := int(k * step_beats * beat * MUSIC_RATE)
		var length := int(min(beat * 1.6, beat * step_beats * 2.5) * MUSIC_RATE)
		var amp := 0.22 if m[3] == "bass" else 0.16
		var decay := 3.0 if m[3] == "bell" else (6.0 if m[3] == "pluck" else 2.0)
		for j in length:
			var idx := (start + j) % n  # wrap so the loop is seamless
			var t := float(j) / MUSIC_RATE
			var v := sin(TAU * f * t)
			if m[3] == "bell":
				v += 0.4 * sin(TAU * f * 2.76 * t)
			elif m[3] == "bass":
				v = sin(TAU * f * 0.5 * t) + 0.3 * sin(TAU * f * t)
			buf[idx] += v * amp * exp(-decay * t)
	# Drums: kick on the beat, a softer hit off the beat.
	if m[4]:
		for b in beats:
			var start := int(b * beat * MUSIC_RATE)
			for j in int(0.25 * MUSIC_RATE):
				var t := float(j) / MUSIC_RATE
				var f := 90.0 * exp(-12.0 * t) + 40.0
				buf[(start + j) % n] += sin(TAU * f * t) * 0.45 * exp(-14.0 * t)
			if b % 2 == 1:
				for j in int(0.08 * MUSIC_RATE):
					buf[(start + j) % n] += rng.randf_range(-1, 1) * 0.12 * exp(-50.0 * float(j) / MUSIC_RATE)
	# Ambient texture.
	var tex: String = m[6]
	if tex != "":
		var prev := 0.0
		for i in n:
			var t := float(i) / MUSIC_RATE
			var noise := rng.randf_range(-1, 1)
			prev = prev * 0.97 + noise * 0.03  # low-passed noise
			match tex:
				"wind":
					buf[i] += prev * 0.5 * (0.6 + 0.4 * sin(TAU * t / 5.0))
				"waves":
					buf[i] += prev * 0.9 * pow(0.5 + 0.5 * sin(TAU * t / (beat * 4)), 2)
				"rumble":
					buf[i] += prev * 0.9
				"bubbles":
					if rng.randf() < 0.0004:
						var f := rng.randf_range(300, 700)
						for j in int(0.06 * MUSIC_RATE):
							buf[(i + j) % n] += sin(TAU * (f + j * 4.0) * float(j) / MUSIC_RATE) * 0.12 * exp(-40.0 * float(j) / MUSIC_RATE)
	# Touch silence for 10 ms at both ends, so the loop point never clicks.
	var fade := int(0.01 * MUSIC_RATE)
	for j in fade:
		var k := float(j) / fade
		buf[j] *= k
		buf[n - 1 - j] *= k
	# Gentle limiter.
	for i in n:
		buf[i] = tanh(buf[i] * 1.2) * 0.8
	var w := _to_wav(buf, true)
	w.mix_rate = MUSIC_RATE
	return w


static func _stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var file := "res://assets/audio/%s.ogg" % sound
	var s: AudioStream = load(file) if ResourceLoader.exists(file) else _synth(sound)
	_cache[sound] = s
	return s


# ---------------------------------------------------------------- synthesis

static func _synth(sound: String) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound)
	match sound:
		"click":
			samples = _tone(1200.0, 0.03, 0.4, 60.0)
		"dice":
			# Bone dice clattering: a handful of sharp noisy clicks.
			samples = _silence(0.45)
			for i in 7:
				var at := int(RATE * (0.02 + i * 0.055 + rng.randf() * 0.02))
				_mix(samples, _noise_click(rng, 0.025, 0.7 - i * 0.07), at)
		"hit":
			samples = _tone(90.0, 0.18, 0.9, 18.0)
			_mix(samples, _noise_click(rng, 0.06, 0.6), 0)
		"fate":
			samples = _silence(0.5)
			_mix(samples, _tone(660.0, 0.35, 0.35, 6.0), 0)
			_mix(samples, _tone(990.0, 0.35, 0.3, 6.0), int(RATE * 0.08))
		"triple":
			samples = _silence(0.8)
			var notes := [523.0, 659.0, 784.0, 1047.0]
			for i in notes.size():
				_mix(samples, _tone(notes[i], 0.4, 0.3, 5.0), int(RATE * 0.07 * i))
		"skill":
			samples = _tone(220.0, 1.0, 0.5, 2.5)
			_mix(samples, _tone(330.0, 0.9, 0.3, 3.0), 0)
			_mix(samples, _tone(1320.0, 0.6, 0.15, 4.0), int(RATE * 0.05))
		"phase":
			samples = _tone(55.0, 1.6, 0.9, 1.2)
			_mix(samples, _tone(58.0, 1.6, 0.6, 1.2), 0)
		"victory":
			samples = _silence(1.2)
			for n in [392.0, 494.0, 587.0]:
				_mix(samples, _tone(n, 1.1, 0.25, 2.5), 0)
		"defeat":
			samples = _silence(1.6)
			var notes := [220.0, 196.0, 174.6, 146.8]
			for i in notes.size():
				_mix(samples, _tone(notes[i], 0.6, 0.35, 3.0), int(RATE * 0.3 * i))
		"drone":
			return _drone()
		_:
			return null
	return _to_wav(samples, false)


static func _silence(seconds: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(int(RATE * seconds))
	a.fill(0.0)
	return a


static func _tone(freq: float, seconds: float, amp: float, decay: float) -> PackedFloat32Array:
	var a := _silence(seconds)
	for i in a.size():
		var t := float(i) / RATE
		a[i] = sin(TAU * freq * t) * amp * exp(-decay * t)
	return a


static func _noise_click(rng: RandomNumberGenerator, seconds: float, amp: float) -> PackedFloat32Array:
	var a := _silence(seconds)
	for i in a.size():
		var t := float(i) / RATE
		a[i] = rng.randf_range(-1.0, 1.0) * amp * exp(-90.0 * t)
	return a


static func _mix(into: PackedFloat32Array, add: PackedFloat32Array, offset: int) -> void:
	for i in add.size():
		var j := offset + i
		if j >= into.size():
			return
		into[j] = clamp(into[j] + add[i], -1.0, 1.0)


static func _drone() -> AudioStreamWAV:
	# 8-second seamless loop: two detuned low voices and a slow swell.
	var seconds := 8.0
	var a := _silence(seconds)
	for i in a.size():
		var t := float(i) / RATE
		var swell := 0.6 + 0.4 * sin(TAU * t / seconds)
		a[i] = (sin(TAU * 55.0 * t) * 0.25 + sin(TAU * 82.5 * t) * 0.12 + sin(TAU * 110.0 * t + sin(TAU * 0.25 * t)) * 0.06) * swell
	return _to_wav(a, true)


static func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clamp(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w
