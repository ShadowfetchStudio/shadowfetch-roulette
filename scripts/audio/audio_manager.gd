extends Node

var _players: Dictionary = {}
var _streams: Dictionary = {}
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer


func _ready() -> void:
	_streams["ui"] = _tone(880, 0.045, 0.14, 0.25)
	_streams["chip"] = _tone(420, 0.06, 0.22, 1.1)
	_streams["clear"] = _tone(210, 0.09, 0.18, 1.8)
	_streams["spin"] = _noise(0.35, 0.12)
	_streams["ball"] = _tone(980, 0.08, 0.16, 2.2)
	_streams["tick"] = _tone(740, 0.03, 0.10, 0.4)
	_streams["win"] = _chord([523, 659, 784], 0.55, 0.26)
	_streams["lose"] = _tone(160, 0.28, 0.22, 1.4)
	_streams["zero"] = _chord([392, 494, 740], 0.62, 0.24)
	for key in _streams:
		var p := AudioStreamPlayer.new()
		p.stream = _streams[key]
		p.bus = "SFX"
		add_child(p)
		_players[key] = p
	_music = AudioStreamPlayer.new()
	_music.stream = _pad()
	_music.bus = "Music"
	add_child(_music)
	_ambient = AudioStreamPlayer.new()
	_ambient.stream = _room()
	_ambient.bus = "Ambient"
	add_child(_ambient)
	SettingsStore.settings_changed.connect(_on_settings)
	_on_settings()


func play(kind: String) -> void:
	if SettingsStore.sfx_volume <= 0.001:
		return
	if _players.has(kind):
		_players[kind].play()


func _on_settings() -> void:
	SettingsStore.apply_audio()
	if _music:
		if SettingsStore.music_volume > 0.02 and not _music.playing:
			_music.play()
		elif SettingsStore.music_volume <= 0.02:
			_music.stop()
	if _ambient:
		if SettingsStore.ambient_volume > 0.02 and not _ambient.playing:
			_ambient.play()
		elif SettingsStore.ambient_volume <= 0.02:
			_ambient.stop()


func _tone(freq: float, seconds: float, vol: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-t * (6.0 + decay * 8.0)) * (1.0 - t / seconds)
		var s := int(sin(t * TAU * freq) * 32767.0 * vol * env)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _chord(freqs: Array, seconds: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-t * 3.6) * (1.0 - t / seconds)
		var sample := 0.0
		for f in freqs:
			sample += sin(t * TAU * float(f))
		sample /= float(freqs.size())
		var s := int(sample * 32767.0 * vol * env)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _noise(seconds: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in n:
		var t := float(i) / float(rate)
		var env := sin(t / seconds * PI) * exp(-t * 2.2)
		var sample := (rng.randf() * 2.0 - 1.0) * 0.55 + 0.25 * sin(t * TAU * 90.0)
		var s := int(sample * 32767.0 * vol * env)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _pad() -> AudioStreamWAV:
	var rate := 22050
	var seconds := 10.0
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.10 * sin(t * TAU * 55.0) + 0.07 * sin(t * TAU * 82.4) + 0.04 * sin(t * TAU * 110.0)
		sample += 0.025 * sin(t * TAU * 164.8 + sin(t * 0.7))
		sample *= 0.58 + 0.42 * sin(t * TAU * 0.09)
		var s := int(sample * 32767.0)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


func _room() -> AudioStreamWAV:
	var rate := 22050
	var seconds := 6.0
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.04 * sin(t * TAU * 48.0) + (rng.randf() * 2.0 - 1.0) * 0.012
		sample *= 0.7 + 0.3 * sin(t * TAU * 0.15)
		var s := int(sample * 32767.0)
		s = clampi(s, -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	return s
