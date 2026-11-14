extends Node
## Ortak ses efektleri. Örnekler kodla üretilir (dosya yok): kalp atışı, tık, hata, başarı, kıvılcım.
## Kullanım: Sfx.play(&"lub")

const RATE := 22050
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_streams[&"lub"] = _thump(70.0, 0.22, 0.9)
	_streams[&"dub"] = _thump(95.0, 0.15, 0.7)
	_streams[&"click"] = _click(1800.0, 0.05)
	_streams[&"snap"] = _click(900.0, 0.08)
	_streams[&"buzz"] = _buzz(130.0, 0.28)
	_streams[&"chime"] = _chime([523.25, 659.25, 783.99], 0.9)
	_streams[&"spark"] = _noise_burst(0.07)
	for i in 6:
		var player := AudioStreamPlayer.new()
		player.volume_db = -10.0
		add_child(player)
		_players.append(player)


## Üretilmiş basit sesler yerine gerçek ses varlıkları (assets/audio) çalar. Kalp atışı üretilmiş kalır (hız ve evreye bağlı).
const FILE_SOUNDS := {
	&"click": &"select",
	&"snap": &"snap",
	&"chime": &"correct",
	&"buzz": &"retry",
}


func play(id: StringName, volume_db: float = -10.0) -> void:
	if FILE_SOUNDS.has(id):
		Audio.play_ui(FILE_SOUNDS[id], volume_db - 4.0)
		return
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return


func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var value := clampi(int(samples[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _thump(frequency: float, length: float, gain: float) -> AudioStreamWAV:
	var n := int(RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var envelope := exp(-t * 22.0) * (1.0 - exp(-t * 400.0))
		var sweep := frequency * (1.0 - 0.35 * t / length)
		samples[i] = sin(TAU * sweep * t) * envelope * gain
	return _make(samples)


func _click(frequency: float, length: float) -> AudioStreamWAV:
	var n := int(RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		samples[i] = (sin(TAU * frequency * t) * 0.6 + sin(TAU * frequency * 2.3 * t) * 0.3) * exp(-t * 90.0)
	return _make(samples)


func _buzz(frequency: float, length: float) -> AudioStreamWAV:
	var n := int(RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var saw := fposmod(t * frequency, 1.0) * 2.0 - 1.0
		samples[i] = saw * 0.35 * exp(-t * 7.0)
	return _make(samples)


func _chime(notes: Array, length: float) -> AudioStreamWAV:
	var n := int(RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for k in notes.size():
		var start := int(RATE * 0.11 * k)
		for i in range(start, n):
			var t := float(i - start) / RATE
			samples[i] += sin(TAU * float(notes[k]) * t) * 0.28 * exp(-t * 4.5)
	return _make(samples)


func _noise_burst(length: float) -> AudioStreamWAV:
	var n := int(RATE * length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		samples[i] = (rng.randf() * 2.0 - 1.0) * 0.4 * exp(-t * 60.0)
	return _make(samples)
