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


static func play(node: Node, sound: String, volume_db: float = VOLUME_DB) -> void:
	if node == null or not node.is_inside_tree():
		return
	var stream := _stream(sound)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	node.get_tree().root.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## A low ambient drone that loops forever (one instance for the whole game).
static func music(node: Node) -> void:
	if node == null or not node.is_inside_tree():
		return
	if _music_player != null and is_instance_valid(_music_player):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _stream("drone")
	_music_player.volume_db = -14.0
	node.get_tree().root.add_child(_music_player)
	_music_player.play()


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
