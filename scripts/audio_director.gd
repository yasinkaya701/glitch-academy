extends Node
## Ses yönetmeni (autoload `Audio`): Music, Ambience, SFX ve UI bus'ları, müzik geçişi, ortam katmanı ve ortak arayüz sesleri.
## Dosyalar res://assets/audio/ altında, kimlikleri manifest.json'da. Ses hiçbir zaman tek başına doğru cevabı taşımaz.
## Kullanım: Audio.enter_hub(), Audio.enter_mission(subject), Audio.play_ui(&"confirm"), Audio.play_sfx("heart_valve_seat")

const ROOT := "res://assets/audio/"
const BUSES := ["Music", "Ambience", "SFX", "UI", "Voice"]
const MUSIC_DB := -18.0
const AMBIENCE_DB := -26.0
const FADE := 1.2

const UI_FILES := {
	&"select": "ui/ui_select.mp3",
	&"confirm": "ui/ui_confirm_action.mp3",
	&"correct": "ui/ui_correct_observation.mp3",
	&"retry": "ui/ui_retry_hint.mp3",
	&"snap": "ui/ui_component_snap.mp3",
	&"pickup": "ui/ui_drag_pickup.mp3",
	&"focus": "ui/ui_focus_tick.mp3",
	&"transition": "ui/ui_scene_transition.mp3",
	&"repaired": "ui/ui_station_repaired.mp3",
}
const AMBIENCE_BY_SUBJECT := {
	"Fizik": "ambience/ambience_physics_lab_loop.mp3",
	"Matematik": "ambience/ambience_physics_lab_loop.mp3",
	"Kimya": "ambience/ambience_chemistry_lab_loop.mp3",
	"Fen Bilimleri": "ambience/ambience_chemistry_lab_loop.mp3",
	"Biyoloji": "ambience/ambience_biology_lab_loop.mp3",
	"Coğrafya": "ambience/ambience_weather_garden_loop.mp3",
	"Tarih": "ambience/ambience_archive_room_loop.mp3",
	"İnkılap Tarihi": "ambience/ambience_archive_room_loop.mp3",
	"Felsefe": "ambience/ambience_archive_room_loop.mp3",
}
const ARCHIVE_SUBJECTS := ["Türkçe", "İngilizce", "Din Kültürü", "Edebiyat"]

var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _one_shots: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _music_path := ""
var _ambience_path := ""
var _tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	_music = _player("Music")
	_ambience = _player("Ambience")
	for i in 6:
		_one_shots.append(_player("UI"))
	get_tree().node_added.connect(_on_node_added)


func _player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


func _stream(relative: String, loop: bool = false) -> AudioStream:
	if _cache.has(relative):
		return _cache[relative]
	var path := ROOT + relative
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	_cache[relative] = stream
	return stream


## Müzik ya da ortam katmanını yumuşak geçişle değiştirir. Aynı parça çalıyorsa dokunmaz.
func _crossfade(player: AudioStreamPlayer, current: String, relative: String, target_db: float, loop: bool) -> String:
	if relative == current and player.playing:
		return current
	var stream := _stream(relative, loop) if relative != "" else null
	if _tweens.has(player):
		(_tweens[player] as Tween).kill()
	var tween := create_tween()
	_tweens[player] = tween
	if player.playing:
		tween.tween_property(player, "volume_db", -60.0, FADE * 0.5)
	if stream == null:
		tween.tween_callback(player.stop)
		return ""
	tween.tween_callback(func() -> void:
		player.stream = stream
		player.volume_db = -60.0
		player.play())
	tween.tween_property(player, "volume_db", target_db, FADE)
	return relative


func play_music(relative: String) -> void:
	_music_path = _crossfade(_music, _music_path, relative, MUSIC_DB, true)


func play_ambience(relative: String) -> void:
	_ambience_path = _crossfade(_ambience, _ambience_path, relative, AMBIENCE_DB, true)


func enter_hub() -> void:
	play_music("music/01_hub_curiosity_loop.mp3")
	play_ambience("ambience/ambience_hub_observatory_loop.mp3")


func enter_mission(subject: String) -> void:
	play_music("music/02_experiment_focus_loop.mp3")
	var key: String = AMBIENCE_BY_SUBJECT.get(subject, "")
	if key == "" and subject in ARCHIVE_SUBJECTS:
		key = "ambience/ambience_archive_room_loop.mp3"
	play_ambience(key)


func mission_repaired() -> void:
	play_music("music/03_repair_resolve_loop.mp3")
	play_ui(&"repaired", -8.0)


func malfunction_intro() -> void:
	play_ambience("")
	play_music("")
	var stream := _stream("music/04_malfunction_intro_sting.mp3")
	if stream != null:
		_one_shot(stream, "Music", -12.0)


func play_ui(id: StringName, volume_db: float = -10.0) -> void:
	var file: String = UI_FILES.get(id, "")
	if file == "":
		return
	var stream := _stream(file)
	if stream != null:
		_one_shot(stream, "UI", volume_db)


## Bilim ve etkileşim sesleri: `relative` science/, interaction/ ya da world/ altındaki dosya adıdır (uzantısız).
func play_sfx(sound_name: String, volume_db: float = -10.0) -> void:
	for folder in ["science", "interaction", "world"]:
		var stream := _stream("%s/%s.mp3" % [folder, sound_name])
		if stream != null:
			_one_shot(stream, "SFX", volume_db)
			return


func _one_shot(stream: AudioStream, bus_name: String, volume_db: float) -> void:
	for player in _one_shots:
		if not player.playing:
			player.bus = bus_name
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return


## Ortak düğme sesi: her düğme basıldığında kısa seçim sesi. Sessiz olması gereken düğme `silent` meta'sı taşır.
func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta(&"silent"):
		(node as BaseButton).pressed.connect(func() -> void: play_ui(&"select", -16.0))


## Konuşma sırasında müzik ve ortam kısılır; konuşma bitince geri gelir.
func duck(on: bool) -> void:
	for bus_name in ["Music", "Ambience"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var tween := create_tween()
			tween.tween_method(func(db: float) -> void: AudioServer.set_bus_volume_db(index, db), AudioServer.get_bus_volume_db(index), -9.0 if on else 0.0, 0.4)


func set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(index, linear <= 0.001)
