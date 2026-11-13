extends "res://scripts/mission.gd"
## LGS Fen Bilimleri · F.8.5.1.1 basit makinelerin avantajları.

const EXPERIMENT_3D := preload("res://scenes/experiment_3d.tscn")
const MAX_RESCUE_TRIES := 3
const RESCUE_EFFORT_MIN_N := 20.0
const RESCUE_EFFORT_MAX_N := 25.0

enum Phase { CRISIS, TEST, DIAGNOSE, CALIBRATE, RESCUE, SEAL, OUT_OF_TRIES }

var _phase := Phase.CRISIS
var _mode := 1
var _motion_time := 0.0
var _running := true
var _calibrated := false
var _crisis_elapsed := 0.0
var _seal_elapsed := 0.0
var _support_count := 1
var _selected_evidence := -1
var _tries_left := MAX_RESCUE_TRIES
var _test_rope_travel := 0.0
var _test_load_travel := 0.0
var _rescue_rope_travel := 0.0
var _rescue_load_travel := 0.0
var _records: Dictionary = {0: {}, 1: {}}

var _viewport: SubViewport
var _experiment_view: Control
var _world: Node3D
var _camera: Camera3D
var _rig: Node3D
var _load_group: Node3D
var _free_end: Node3D
var _lower_pulley: Node3D
var _upper_pulley: Node3D
var _moving_link: MeshInstance3D
var _rope_segments: Array[MeshInstance3D] = []
var _mode_buttons: Array[Button] = []
var _stage_label: Label
var _directive: Label
var _fault_label: Label
var _measurements: Label
var _feedback: Label
var _interaction_label: Label
var _primary_action: Button
var _exit_button: Button
var _record_buttons: Array[Button] = []
var _calibration_button: Button
var _effort_slider: HSlider
var _effort_label: Label
var _tries_label: Label
var _dragging_rig := false
var _dragging_rope := false
var _last_pointer := Vector2.ZERO


func _ready() -> void:
	_build_interface()
	_build_world()
	_enter_crisis()
	_update_interface()


func _process(delta: float) -> void:
	if _phase == Phase.CRISIS:
		_crisis_elapsed += delta
		if _crisis_elapsed >= 6.0:
			_running = false
			_update_interface()
	elif _phase == Phase.SEAL:
		_seal_elapsed += delta
		if _seal_elapsed >= 2.2:
			_running = false
	if _running:
		_motion_time += delta
		_update_motion()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = UITheme.BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	var kicker := _label("LGS FEN BİLİMLERİ  ·  F.8.5.1.1", 14)
	kicker.theme_type_variation = &"SectionLabel"
	identity.add_child(kicker)
	var title := _label("Palanga Atölyesi", 30)
	title.theme_type_variation = &"HeadlineLabel"
	identity.add_child(title)
	_exit_button = Button.new()
	_exit_button.text = "Kontrol merkezine dön"
	_exit_button.pressed.connect(_request_exit)
	header.add_child(_exit_button)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	layout.add_child(content)
	var visual := VBoxContainer.new()
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual.add_theme_constant_override("separation", 8)
	content.add_child(visual)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	visual.add_child(mode_row)
	_mode_buttons = [_button("Sabit makara", true), _button("Hareketli makara", true)]
	for i in _mode_buttons.size():
		_mode_buttons[i].pressed.connect(_select_mode.bind(i))
		mode_row.add_child(_mode_buttons[i])
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.theme_type_variation = &"GlassPanel"
	visual.add_child(frame)
	_experiment_view = EXPERIMENT_3D.instantiate()
	_experiment_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_experiment_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_experiment_view.gui_input.connect(_on_experiment_gui_input)
	_experiment_view.mouse_default_cursor_shape = Control.CURSOR_MOVE
	frame.add_child(_experiment_view)
	_viewport = _experiment_view.get_node("Viewport") as SubViewport
	_viewport.msaa_3d = Viewport.MSAA_4X
	_world = _experiment_view.get_node("Viewport/World") as Node3D
	_interaction_label = _label("Halat ucunu çekerek ölç · Boş alandan sürükleyerek düzeneği döndür", 14)
	_interaction_label.theme_type_variation = &"MutedLabel"
	visual.add_child(_interaction_label)
	var lesson := PanelContainer.new()
	lesson.custom_minimum_size.x = 360
	lesson.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lesson.theme_type_variation = &"ConsolePanel"
	content.add_child(lesson)
	var panel_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		panel_margin.add_theme_constant_override("margin_" + side, 18)
	lesson.add_child(panel_margin)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 11)
	panel_margin.add_child(panel)
	_stage_label = _label("ADIM 1 / 6  ·  KRİZ", 14)
	_stage_label.theme_type_variation = &"SectionLabel"
	panel.add_child(_stage_label)
	_directive = _label("", 21)
	_directive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_directive)
	var plate_heading := _label("KALİBRASYON PLAKASI", 12)
	plate_heading.theme_type_variation = &"SectionLabel"
	panel.add_child(plate_heading)
	_fault_label = _label("", 16)
	_fault_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_fault_label)
	_measurements = _label("", 16)
	_measurements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_measurements)
	_record_buttons = [_button("Kayıt 1", false), _button("Kayıt 2", false)]
	for button in _record_buttons:
		button.toggle_mode = true
		button.visible = false
		button.pressed.connect(_select_evidence.bind(_record_buttons.find(button)))
		panel.add_child(button)
	_calibration_button = _button("Taşıyıcı ip kolu: 1", false)
	_calibration_button.visible = false
	_calibration_button.pressed.connect(_toggle_support_count)
	panel.add_child(_calibration_button)
	_effort_label = _label("Uygulanan kuvvet  ·  0 N", 16)
	_effort_label.visible = false
	panel.add_child(_effort_label)
	_effort_slider = HSlider.new()
	_effort_slider.min_value = 0
	_effort_slider.max_value = 40
	_effort_slider.step = 5
	_effort_slider.value_changed.connect(_on_effort_changed)
	_effort_slider.visible = false
	panel.add_child(_effort_slider)
	_tries_label = _label("", 14)
	_tries_label.visible = false
	panel.add_child(_tries_label)
	_feedback = _label("", 15)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_feedback)
	_primary_action = Button.new()
	_primary_action.custom_minimum_size.y = 48
	_primary_action.theme_type_variation = &"PrimaryButton"
	_primary_action.pressed.connect(_advance)
	panel.add_child(_primary_action)


func _enter_crisis() -> void:
	_phase = Phase.CRISIS
	_mode = 1
	_calibrated = false
	_running = true
	_motion_time = 0.0
	_crisis_elapsed = 0.0
	_test_rope_travel = 0.0
	_test_load_travel = 0.0
	_rescue_rope_travel = 0.0
	_rescue_load_travel = 0.0
	_records = {0: {}, 1: {}}
	_update_motion()


func _advance() -> void:
	match _phase:
		Phase.CRISIS:
			_phase = Phase.TEST
			_mode = 0
			_running = false
			_test_rope_travel = 0.0
			_test_load_travel = 0.0
			_update_motion()
			_feedback.text = "İki düzeneği de elle çalıştır. Halat ve yük göstergelerini okuyup kayıt al."
		Phase.TEST:
			_record_test()
		Phase.DIAGNOSE:
			_confirm_diagnosis()
		Phase.CALIBRATE:
			_calibrate()
		Phase.RESCUE:
			_attempt_rescue()
		Phase.SEAL:
			completed.emit()
		Phase.OUT_OF_TRIES:
			_request_exit()
	_update_interface()


func _record_test() -> void:
	if _test_rope_travel < 0.20:
		_feedback.text = "Ölçüm şeridinde okunabilir bir hareket yok. Halat ucunu çekip yeniden dene."
		return
	_records[_mode] = {"rope": _test_rope_travel, "load": _test_load_travel, "effort": _read_effort(_mode)}
	_test_rope_travel = 0.0
	_test_load_travel = 0.0
	if _records[0].is_empty():
		_mode = 1
		_feedback.text = "Sabit makara kaydedildi. Şimdi hareketli düzeneği sına."
		_update_motion()
		return
	if _records[1].is_empty():
		_feedback.text = "Hareketli makara kaydedildi. İki ölçümü yan yana incele."
		return
	_phase = Phase.DIAGNOSE
	_selected_evidence = -1
	_feedback.text = "İki ölçüm de hazır. Bozuk ayarı çürüten kaydı seçip plakaya taşı."


func _select_evidence(index: int) -> void:
	_selected_evidence = index
	for i in _record_buttons.size():
		_record_buttons[i].set_pressed_no_signal(i == index)


func _confirm_diagnosis() -> void:
	if _selected_evidence != 1:
		_feedback.text = "Bu kayıt hareketli makaradaki ayarı açıklamıyor. Ölçüm şeridine yeniden bak."
		return
	_phase = Phase.CALIBRATE
	_support_count = 1
	_feedback.text = "Kanıt plakaya geçti. Mühür açıldı; taşıyıcı ip kolu ayarını düzelt."


func _toggle_support_count() -> void:
	_support_count = 2 if _support_count == 1 else 1
	_calibration_button.text = "Taşıyıcı ip kolu: %d" % _support_count


func _calibrate() -> void:
	if _support_count != 2:
		_feedback.text = "Ayar sağlam ip yoluyla uyuşmuyor. Yükü taşıyan ip kollarını say."
		return
	_calibrated = true
	_phase = Phase.RESCUE
	_mode = 1
	_running = false
	_effort_slider.value = 0
	_rescue_rope_travel = 0.0
	_rescue_load_travel = 0.0
	_motion_time = 0.0
	_update_motion()
	_feedback.text = "Kalibrasyon kaydedildi. Yeni yükü kaldırıp arşiv kilidini aç."


func _attempt_rescue() -> void:
	if _rescue_rope_travel < 0.75 or _rescue_load_travel < 0.34:
		_use_try("Yük emniyet çizgisinin üstüne ulaşmadı. Ölçüm göstergelerini kontrol et.")
		return
	if _effort_slider.value < RESCUE_EFFORT_MIN_N:
		_use_try("Kuvvet göstergesi yükün direncinin altında kaldı; kilit açılmadı.")
		return
	if _effort_slider.value > RESCUE_EFFORT_MAX_N:
		_use_try("Kuvvet göstergesi güvenlik aralığını geçti; kilit kendini kapattı.")
		return
	_phase = Phase.SEAL
	_seal_elapsed = 0.0
	_running = true
	_motion_time = 0.0
	_feedback.text = "Yük emniyet çizgisini geçti. Son hareket doğru düzende yeniden oynuyor."


func _use_try(reason: String) -> void:
	_tries_left -= 1
	_feedback.text = "%s  ·  Kalan hak: %d" % [reason, _tries_left]
	if _tries_left <= 0:
		_phase = Phase.OUT_OF_TRIES
		_feedback.text = "Üç kurtarma hakkı kullanıldı. Yeni deneme için kontrol merkezine dön."
		return
	_rescue_rope_travel = 0.0
	_rescue_load_travel = 0.0
	_motion_time = 0.0
	_update_motion()


func _on_effort_changed(value: float) -> void:
	_effort_label.text = "Uygulanan kuvvet  ·  %.0f N" % value


func _select_mode(mode: int) -> void:
	if _phase != Phase.TEST:
		return
	_mode = mode
	_test_rope_travel = 0.0
	_test_load_travel = 0.0
	_motion_time = 0.0
	_update_motion()
	_update_interface()

func _request_exit() -> void:
	exit_requested.emit()


func _update_interface() -> void:
	var labels := ["KRİZ", "SINA", "TEŞHİS", "DÜZELT", "TOPARLA", "MÜHÜR", "HAK BİTTİ"]
	var display_step := min(_phase, Phase.SEAL) + 1
	_stage_label.text = "ADIM %d / 6  ·  %s" % [display_step, labels[_phase]]
	_directive.text = _phase_directive()
	_fault_label.text = "%s\n%s" % ["DÜZELTİLDİ" if _calibrated else "BOZUK AYAR", "Yükü taşıyan ip kolu: %d" % _support_count if _calibrated else "Hareketli makara yükü, ip ucuyla aynı yolda taşıyor."]
	_measurements.text = "ÖLÇÜM ŞERİDİ\nSabit  ·  %s\nHareketli  ·  %s" % [_record_text(0), _record_text(1)]
	if _phase == Phase.TEST:
		_measurements.text += "\nBu deneme  ·  ip %.2f m  /  yük %.2f m\nKuvvet ölçer  ·  %.0f N" % [_test_rope_travel, _test_load_travel, _read_effort(_mode)]
	elif _phase == Phase.RESCUE:
		_measurements.text += "\nBu deneme  ·  ip %.2f m  /  yük %.2f m" % [_rescue_rope_travel, _rescue_load_travel]
	for i in _mode_buttons.size():
		_mode_buttons[i].button_pressed = i == _mode
		_mode_buttons[i].visible = _phase == Phase.TEST
		_mode_buttons[i].disabled = _phase != Phase.TEST
	for i in _record_buttons.size():
		_record_buttons[i].visible = _phase == Phase.DIAGNOSE and not _records[i].is_empty()
		_record_buttons[i].text = "Kayıt %d  ·  %s" % [i + 1, _record_text(i)] if not _records[i].is_empty() else "Kayıt %d" % (i + 1)
		_record_buttons[i].set_pressed_no_signal(_selected_evidence == i)
	_calibration_button.visible = _phase == Phase.CALIBRATE
	_effort_label.visible = _phase == Phase.RESCUE
	_effort_slider.visible = _phase == Phase.RESCUE
	_tries_label.visible = _phase == Phase.RESCUE
	_tries_label.text = "Kurtarma hakkı  ·  %d / %d" % [_tries_left, MAX_RESCUE_TRIES]
	_primary_action.text = _primary_text()
	_exit_button.text = "Kontrol merkezine dön"
	if _phase == Phase.SEAL:
		_fault_label.text = "MÜHÜRLENDİ\nİdeal düzende kuvvetten kazanç, yoldan kayıpla birlikte gelir."
	if _running:
		_interaction_label.text = "Düzenek çalışıyor · Halat ucunu sürükleyerek durdur ve incele"
	elif _phase in [Phase.TEST, Phase.RESCUE]:
		_interaction_label.text = "Halat ucunu çekerek ölç · Boş alandan sürükleyerek döndür"
	else:
		_interaction_label.text = "3B düzeneği sürükleyerek döndür · Tekerlekle yakınlaş"


func _primary_text() -> String:
	match _phase:
		Phase.CRISIS: return "ÖLÇÜME BAŞLA  →"
		Phase.TEST: return "ÖLÇÜMÜ KAYDA AL  →"
		Phase.DIAGNOSE: return "KANITI PLAKAYA YERLEŞTİR  →"
		Phase.CALIBRATE: return "KALİBRASYONU MÜHÜRLE  →"
		Phase.RESCUE: return "KİLİDİ AÇ  →"
		Phase.SEAL: return "KAMPANYA KAYDINI GÖNDER  →"
		_: return "KONTROL MERKEZİNE DÖN"


func _phase_directive() -> String:
	match _phase:
		Phase.CRISIS: return "Yük emniyet çizgisinin altında kaldı. MERİDYEN'in ayarını incele."
		Phase.TEST: return "İki düzeneği elle çalıştır; halat ve yük ölçüm çizgilerini kaydet."
		Phase.DIAGNOSE: return "Bozuk satırı çürüten ölçüm kaydını seçip kalibrasyon plakasına taşı."
		Phase.CALIBRATE: return "Sahnedeki yükü taşıyan ip kollarına göre plaka ayarını düzelt."
		Phase.RESCUE: return "40 N yükü emniyet çizgisinin üstüne çıkarıp kilidi aç."
		Phase.SEAL: return "Son hareketi izle; doğru düzenek arşiv kilidini açtı."
		_: return "Kurtarma hakkı bitti. Merkeze dönüp yeni deneme başlat."


func _read_effort(mode: int) -> float:
	var supporting_strands := 1 if mode == 0 or not _calibrated else 2
	return 20.0 / float(supporting_strands)


func _record_text(mode: int) -> String:
	var record: Dictionary = _records[mode]
	if record.is_empty():
		return "bekliyor"
	return "ip %.2f m  ·  yük %.2f m  ·  kuvvet %.0f N" % [record.rope, record.load, record.effort]


func _label(value: String, size: int) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", size)
	return item


func _button(value: String, toggle: bool) -> Button:
	var item := Button.new()
	item.text = value
	item.toggle_mode = toggle
	item.custom_minimum_size = Vector2(0, 42)
	return item


func _build_world() -> void:
	var environment := _world.get_node("WorldEnvironment") as WorldEnvironment
	var env := environment.environment.duplicate(true) as Environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = UITheme.BG
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = UITheme.BG
	sky_material.sky_horizon_color = UITheme.PANEL
	sky_material.ground_bottom_color = UITheme.BG
	sky_material.ground_horizon_color = UITheme.PANEL
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a9c5d0")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.18
	environment.environment = env
	_camera = _world.get_node("Camera3D") as Camera3D
	_camera.position = Vector3(4.8, 3.8, 8.6)
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 38
	_camera.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
	_camera.current = true
	_build_workshop_environment()
	_rig = Node3D.new()
	_rig.name = "PalangaRig"
	_world.get_node("Model").add_child(_rig)
	_build_rig()


func _build_workshop_environment() -> void:
	var wall := _material(UITheme.PANEL, 0.02, 0.92)
	var wall_panel := _material(UITheme.PANEL_RAISED, 0.04, 0.78)
	var dark_panel := _material(UITheme.BG, 0.16, 0.66)
	var warm_trim := _material(UITheme.WARM, 0.62, 0.36)
	var bench_top := _material(UITheme.PANEL, 0.08, 0.72)
	var bench_edge := _material(UITheme.EDGE, 0.48, 0.48)
	var soft_light := _material(UITheme.WARM, 0.0, 0.4)
	soft_light.emission_enabled = true
	soft_light.emission = UITheme.WARM
	soft_light.emission_energy_multiplier = 1.35
	var ground := _material(UITheme.BG, 0.08, 0.9)

	# A continuous work surface carries the model plinth; the legs and drawer fronts
	# extend below it so the apparatus reads as part of a real laboratory bench.
	_add_box(_world, Vector3(0.0, -0.33, -0.15), Vector3(7.5, 0.28, 6.0), bench_top)
	_add_box(_world, Vector3(0.0, -0.50, 2.68), Vector3(7.18, 0.08, 0.16), bench_edge)
	_add_box(_world, Vector3(0.0, -0.50, -2.98), Vector3(7.18, 0.08, 0.16), bench_edge)
	for x in [-3.38, 3.38]:
		for z in [-2.66, 2.48]:
			_add_box(_world, Vector3(x, -1.22, z), Vector3(0.17, 1.44, 0.17), bench_edge)
			_add_box(_world, Vector3(x, -1.84, z), Vector3(0.25, 0.10, 0.25), warm_trim)
	for x in [-2.15, 0.0, 2.15]:
		_add_box(_world, Vector3(x, -0.88, 2.58), Vector3(1.86, 0.48, 0.07), dark_panel)
		_add_box(_world, Vector3(x, -0.77, 2.535), Vector3(0.52, 0.045, 0.035), warm_trim)
		_add_cylinder(_world, Vector3(x, -0.77, 2.50), 0.035, 0.06, warm_trim, Vector3(90, 0, 0), 20)
	var floor := _add_box(_world, Vector3(0.0, -1.93, 0.0), Vector3(36.0, 0.12, 36.0), ground)
	floor.name = "WorkshopFloor"

	# The back wall, tool boards, and lighting stay fixed as the pulley rig rotates.
	_add_box(_world, Vector3(0.0, 2.03, -3.56), Vector3(24.0, 7.8, 0.24), wall)
	_add_box(_world, Vector3(0.0, 2.03, -3.76), Vector3(40.0, 10.0, 0.18), wall)
	_add_box(_world, Vector3(0.0, 4.70, -3.40), Vector3(8.8, 0.12, 0.18), bench_edge)
	for side in [-1.0, 1.0]:
		var board_x: float = side * 3.05
		_add_box(_world, Vector3(board_x, 2.45, -3.405), Vector3(1.62, 3.7, 0.08), wall_panel)
		for row in range(9):
			for column in range(4):
				_add_sphere(_world, Vector3(board_x - 0.48 + column * 0.32, 0.95 + row * 0.36, -3.345), 0.026, dark_panel)
		for rail_y in [0.62, 4.28]:
			_add_box(_world, Vector3(board_x, rail_y, -3.34), Vector3(1.72, 0.055, 0.07), warm_trim)
	# Slim utility shelves and a warm task light tie the background to the bench.
	for side in [-1.0, 1.0]:
		_add_box(_world, Vector3(side * 3.25, 4.02, -3.02), Vector3(1.75, 0.09, 0.62), bench_edge)
		_add_box(_world, Vector3(side * 3.25, 3.94, -2.74), Vector3(1.48, 0.035, 0.035), warm_trim)
	_add_box(_world, Vector3(0.0, 4.58, -3.25), Vector3(4.8, 0.055, 0.075), soft_light)
	var task_light := OmniLight3D.new()
	task_light.position = Vector3(0.0, 4.45, -2.85)
	task_light.light_color = UITheme.WARM
	task_light.light_energy = 1.3
	task_light.omni_range = 9.0
	_world.add_child(task_light)
	var key := SpotLight3D.new()
	key.position = Vector3(-0.5, 5.8, 3.6)
	key.light_color = UITheme.INK
	key.light_energy = 2.2
	key.spot_range = 11.0
	key.spot_angle = 48.0
	key.shadow_enabled = true
	_world.add_child(key)
	key.look_at(Vector3(0.0, 1.5, 0.0), Vector3.UP)


func _build_rig() -> void:
	for child in _rig.get_children():
		child.queue_free()
	_rope_segments.clear()
	var steel := _material(Color("#81939d"), 0.82, 0.26)
	var dark_steel := _material(Color("#293b49"), 0.86, 0.31)
	var blue := _material(Color("#2c7890"), 0.78, 0.24)
	var brass := _material(Color("#d2a256"), 0.8, 0.23)
	var rope_mat := _material(Color("#d6d2c2"), 0.86, 0.12)
	var rubber := _material(Color("#17222b"), 0.15, 0.58)
	_add_box(_rig, Vector3(0, 3.92, 0), Vector3(3.25, 0.16, 0.28), steel)
	_add_box(_rig, Vector3(-1.48, 2.0, 0), Vector3(0.16, 4.0, 0.28), dark_steel)
	_add_box(_rig, Vector3(1.48, 2.0, 0), Vector3(0.16, 4.0, 0.28), dark_steel)
	_add_box(_rig, Vector3(0, 0.12, 0), Vector3(3.3, 0.18, 0.36), steel)
	for x in [-1.48, 1.48]:
		for y in [0.28, 3.72]:
			_add_cylinder(_rig, Vector3(x, y, 0.18), 0.055, 0.035, brass, Vector3(90, 0, 0))
	_add_box(_rig, Vector3(0, 3.78, 0), Vector3(0.92, 0.20, 0.22), blue)
	_add_box(_rig, Vector3(0, 3.61, 0), Vector3(0.22, 0.16, 0.18), brass)
	_add_box(_rig, Vector3(0, 0.27, 0), Vector3(1.04, 0.09, 0.40), rubber)

	_upper_pulley = Node3D.new()
	_upper_pulley.position = Vector3(0.18, 3.28, 0)
	_rig.add_child(_upper_pulley)
	_add_sheave(_upper_pulley, blue, steel, brass)
	for z in [-0.24, 0.24]:
		_rig.add_child(_beam(Vector3(-0.03, 3.78, z), Vector3(0.18, 3.38, z), 0.035, Color("#aebdc0")))
		_rig.add_child(_beam(Vector3(0.39, 3.78, z), Vector3(0.18, 3.38, z), 0.035, Color("#aebdc0")))
	_lower_pulley = Node3D.new()
	_lower_pulley.position = Vector3(-0.35, 1.72, 0.04)
	_rig.add_child(_lower_pulley)
	_add_sheave(_lower_pulley, blue, steel, brass)
	for z in [-0.25, 0.25]:
		_lower_pulley.add_child(_beam(Vector3(0.0, 0.42, z), Vector3(0.0, -0.48, z), 0.028, Color("#c0c9c3")))
		_add_cylinder(_lower_pulley, Vector3(0.0, 0.44, z), 0.045, 0.035, brass, Vector3(90, 0, 0), 20)
		_add_cylinder(_lower_pulley, Vector3(0.0, -0.48, z), 0.045, 0.035, brass, Vector3(90, 0, 0), 20)

	_load_group = Node3D.new()
	_load_group.name = "LoadAndHook"
	_rig.add_child(_load_group)
	_add_load(_load_group, rubber, brass, steel)
	_free_end = Node3D.new()
	_free_end.name = "FreeEndWeight"
	_rig.add_child(_free_end)
	_add_cylinder(_free_end, Vector3.ZERO, 0.085, 0.24, brass)
	_add_cylinder(_free_end, Vector3(0, -0.16, 0), 0.05, 0.10, steel)
	_add_torus(_free_end, Vector3(0, -0.28, 0), 0.09, 0.02, brass)
	_moving_link = MeshInstance3D.new()
	_moving_link.name = "MovingPulleyLink"
	var link_mesh := CylinderMesh.new()
	link_mesh.top_radius = 0.035
	link_mesh.bottom_radius = 0.035
	link_mesh.height = 1.0
	_moving_link.mesh = link_mesh
	_moving_link.material_override = steel
	_rig.add_child(_moving_link)
	for i in range(4):
		var segment := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.025
		mesh.bottom_radius = 0.025
		mesh.height = 1.0
		mesh.radial_segments = 12
		segment.mesh = mesh
		segment.material_override = rope_mat
		_rig.add_child(segment)
		_rope_segments.append(segment)
	_add_measurement_marks(steel, brass)
	_update_motion()


func _add_sheave(parent: Node3D, face: Material, rim: Material, hub: Material) -> void:
	_add_cylinder(parent, Vector3.ZERO, 0.42, 0.16, face, Vector3(90, 0, 0), 64)
	_add_torus(parent, Vector3(0, 0, 0.094), 0.36, 0.045, rim)
	_add_torus(parent, Vector3(0, 0, -0.094), 0.36, 0.045, rim)
	var groove := _material(Color("#18252c"), 0.62, 0.42)
	_add_torus(parent, Vector3.ZERO, 0.355, 0.018, groove)
	var face_trim := _material(Color("#bbc3bd"), 0.44, 0.48)
	_add_torus(parent, Vector3(0, 0, 0.09), 0.285, 0.014, face_trim)
	_add_torus(parent, Vector3(0, 0, -0.09), 0.285, 0.014, face_trim)
	var spoke_material := _material(Color("#c9d1cb"), 0.48, 0.42)
	for z in [-0.091, 0.091]:
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var spoke := _add_box(parent, Vector3(cos(angle) * 0.205, sin(angle) * 0.205, z), Vector3(0.26, 0.038, 0.025), spoke_material)
			spoke.rotation.z = angle
	_add_cylinder(parent, Vector3(0, 0, 0.12), 0.125, 0.10, hub, Vector3(90, 0, 0), 48)
	_add_cylinder(parent, Vector3(0, 0, -0.12), 0.125, 0.10, hub, Vector3(90, 0, 0), 48)
	_add_torus(parent, Vector3(0, 0, 0.177), 0.105, 0.015, face_trim)
	_add_torus(parent, Vector3(0, 0, -0.177), 0.105, 0.015, face_trim)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		for side in [-1.0, 1.0]:
			_add_cylinder(parent, Vector3(cos(angle) * 0.25, sin(angle) * 0.25, side * 0.112), 0.022, 0.028, hub, Vector3(90, 0, 0), 16)


func _on_experiment_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.double_click:
				_rig.rotation = Vector3.ZERO
				_dragging_rig = false
				_dragging_rope = false
				return
			if mouse_button.pressed:
				_begin_pointer_interaction(mouse_button.position)
			else:
				_dragging_rig = false
				_dragging_rope = false
			_last_pointer = mouse_button.position
			return
		if mouse_button.pressed and mouse_button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_camera.fov = clampf(_camera.fov + (-2.0 if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP else 2.0), 28.0, 50.0)
			return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if not _dragging_rig and not _dragging_rope:
			_experiment_view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _pointer_hits_rope_end(motion.position) else Control.CURSOR_MOVE
			return
		var pointer_delta := motion.position - _last_pointer
		_last_pointer = motion.position
		if _dragging_rope:
			_pull_rope(pointer_delta)
		else:
			_rig.rotation.y -= pointer_delta.x * 0.009
			_rig.rotation.x = clampf(_rig.rotation.x - pointer_delta.y * 0.006, -0.75, 0.75)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_pointer_interaction(touch.position)
		else:
			_dragging_rig = false
			_dragging_rope = false
		_last_pointer = touch.position
	if event is InputEventScreenDrag and _dragging_rig:
		var drag := event as InputEventScreenDrag
		_rig.rotation.y -= drag.relative.x * 0.009
		_rig.rotation.x = clampf(_rig.rotation.x - drag.relative.y * 0.006, -0.75, 0.75)
	if event is InputEventScreenDrag and _dragging_rope:
		var drag := event as InputEventScreenDrag
		_pull_rope(drag.relative)


func _begin_pointer_interaction(pointer: Vector2) -> void:
	_dragging_rope = _phase in [Phase.TEST, Phase.RESCUE] and _pointer_hits_rope_end(pointer)
	_dragging_rig = not _dragging_rope
	_last_pointer = pointer
	if _dragging_rope:
		_running = false
		_interaction_label.text = "Halat çekiliyor · Yükün hareketini gözlemle"

func _viewport_pointer(pointer: Vector2) -> Vector2:
	var view_size := _experiment_view.size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return Vector2.ZERO
	return pointer * Vector2(_viewport.size) / view_size


func _pointer_hits_rope_end(pointer: Vector2) -> bool:
	if not is_instance_valid(_free_end) or not is_instance_valid(_camera):
		return false
	var endpoint := _free_end.global_position
	if _camera.is_position_behind(endpoint):
		return false
	var endpoint_screen := _camera.unproject_position(endpoint)
	var pointer_screen := _viewport_pointer(pointer)
	return pointer_screen.distance_to(endpoint_screen) <= 34.0


func _pull_rope(pointer_delta: Vector2) -> void:
	var viewport_delta := pointer_delta * Vector2(_viewport.size) / _experiment_view.size
	var depth := _camera.global_position.distance_to(_free_end.global_position)
	var world_per_pixel := 2.0 * depth * tan(deg_to_rad(_camera.fov * 0.5)) / float(_viewport.size.y)
	var screen_up_alignment := _camera.global_transform.basis.y.normalized().dot(_rig.global_transform.basis.y.normalized())
	if absf(screen_up_alignment) < 0.25:
		return
	var requested_delta := -viewport_delta.y * world_per_pixel * screen_up_alignment
	var load_y := _load_group.position.y
	var free_y := _free_end.position.y
	var ratio := _load_ratio()
	var free_min := 0.92 if _mode == 0 else 1.20
	var free_max := 1.56 if _mode == 0 else 2.28
	var load_min := 0.92
	var load_max := 1.56 if _mode == 0 or not _calibrated else 1.46
	var delta_min := free_min - free_y
	var delta_max := free_max - free_y
	if ratio > 0.0:
		delta_min = maxf(delta_min, (load_y - load_max) / ratio)
		delta_max = minf(delta_max, (load_y - load_min) / ratio)
	var actual_delta := clampf(requested_delta, delta_min, delta_max)
	if is_zero_approx(actual_delta):
		return
	_free_end.position.y += actual_delta
	_load_group.position.y -= actual_delta * ratio
	if _phase == Phase.TEST:
		_test_rope_travel += absf(actual_delta)
		_test_load_travel += absf(actual_delta * ratio)
	elif _phase == Phase.RESCUE:
		_rescue_rope_travel += absf(actual_delta)
		_rescue_load_travel += absf(actual_delta * ratio)
	if _mode == 0:
		_upper_pulley.rotation.z -= actual_delta / 0.36
	else:
		_lower_pulley.position.y = _load_group.position.y + 0.20
		_moving_link.position = Vector3(-0.35, _load_group.position.y + 0.04, 0.05)
		_lower_pulley.rotation.z += actual_delta / 0.72
		_upper_pulley.rotation.z -= actual_delta / 0.36
	_sync_mechanism_geometry()
	_update_interface()

func _load_ratio() -> float:
	if _mode == 0:
		return 1.0
	if not _calibrated:
		return 1.0
	if _phase == Phase.RESCUE and _effort_slider.value < RESCUE_EFFORT_MIN_N:
		return 0.0
	return 0.5


func _sync_mechanism_geometry() -> void:
	var load_y := _load_group.position.y
	var end_y := _free_end.position.y
	if _mode == 0:
		_upper_pulley.position = Vector3(0.0, 3.18, 0.0)
		_set_rope_segment(0, Vector3(-0.80, end_y + 0.24, 0.0), Vector3(-0.36, 3.18, 0.0))
		_set_rope_segment(1, Vector3(0.36, 3.18, 0.0), Vector3(0.80, load_y + 0.08, 0.0))
	else:
		_lower_pulley.position = Vector3(-0.35, load_y + 0.20, 0.04)
		_upper_pulley.position = Vector3(0.30, 3.30, 0.0)
		_moving_link.scale.y = 0.30
		_set_rope_segment(0, Vector3(-0.74, 3.72, 0.04), Vector3(-0.74, load_y + 0.20, 0.04))
		_set_rope_segment(1, Vector3(0.04, load_y + 0.20, 0.04), Vector3(-0.12, 3.30, 0.04))
		_set_rope_segment(2, Vector3(0.72, 3.30, 0.04), Vector3(0.80, end_y + 0.24, 0.04))


func _add_load(parent: Node3D, body: Material, trim: Material, steel: Material) -> void:
	_add_torus(parent, Vector3(0, 0.05, 0), 0.11, 0.025, trim)
	_add_cylinder(parent, Vector3(0, -0.08, 0), 0.045, 0.23, steel)
	_add_box(parent, Vector3(0, -0.50, 0), Vector3(0.76, 0.64, 0.60), body)
	_add_box(parent, Vector3(0, -0.18, 0), Vector3(0.80, 0.07, 0.64), trim)
	_add_box(parent, Vector3(0, -0.82, 0), Vector3(0.86, 0.08, 0.68), steel)
	for x in [-0.30, 0.30]:
		for z in [-0.25, 0.25]:
			_add_cylinder(parent, Vector3(x, -0.48, z), 0.032, 0.025, trim, Vector3(90, 0, 0), 16)


func _add_measurement_marks(steel: Material, brass: Material) -> void:
	for i in range(9):
		var y := 0.62 + float(i) * 0.34
		_add_box(_rig, Vector3(-1.30, y, 0.19), Vector3(0.12 if i % 2 == 0 else 0.07, 0.018, 0.025), brass if i % 2 == 0 else steel)
	var floor_ring := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 1.22
	ring.outer_radius = 1.235
	ring.rings = 12
	ring.ring_segments = 96
	floor_ring.mesh = ring
	floor_ring.position = Vector3(0, 0.05, 0)
	floor_ring.material_override = _material(Color("#315263"), 0.48, 0.4)
	_rig.add_child(floor_ring)


func _update_motion() -> void:
	if not is_instance_valid(_rig):
		return
	var phase := (sin(_motion_time * TAU / 3.8 - PI / 2.0) + 1.0) * 0.5 if _running else (0.0 if _phase in [Phase.TEST, Phase.RESCUE] else 0.5)
	if _mode == 0:
		var load_y := lerpf(0.92, 1.56, phase)
		var end_y := lerpf(1.56, 0.92, phase)
		_load_group.position = Vector3(0.80, load_y, 0)
		_free_end.position = Vector3(-0.80, end_y, 0)
		_upper_pulley.position = Vector3(0, 3.18, 0)
		_lower_pulley.hide()
		_moving_link.hide()
		_set_rope_segment(0, Vector3(-0.80, end_y + 0.24, 0), Vector3(-0.36, 3.18, 0))
		_set_rope_segment(1, Vector3(0.36, 3.18, 0), Vector3(0.80, load_y + 0.08, 0))
		_rope_segments[2].hide()
		_rope_segments[3].hide()
		_upper_pulley.rotation.z = (phase - 0.5) * 1.5
	else:
		var load_ratio := _load_ratio()
		var end_y := lerpf(2.28, 1.20, phase)
		var travel_from_start := 2.28 - end_y
		var load_y := minf(0.92 + travel_from_start * load_ratio, 1.56) if load_ratio > 0.0 else 0.92
		_load_group.position = Vector3(-0.35, load_y, 0)
		_free_end.position = Vector3(0.80, end_y, 0)
		_lower_pulley.position = Vector3(-0.35, load_y + 0.20, 0.04)
		_upper_pulley.position = Vector3(0.30, 3.30, 0)
		_lower_pulley.show()
		_moving_link.show()
		_moving_link.position = Vector3(-0.35, load_y + 0.04, 0.05)
		_moving_link.scale.y = 0.30
		_set_rope_segment(0, Vector3(-0.74, 3.72, 0.04), Vector3(-0.74, load_y + 0.20, 0.04))
		_set_rope_segment(1, Vector3(0.04, load_y + 0.20, 0.04), Vector3(-0.12, 3.30, 0.04))
		_set_rope_segment(2, Vector3(0.72, 3.30, 0.04), Vector3(0.80, end_y + 0.24, 0.04))
		_rope_segments[3].hide()
		_lower_pulley.rotation.z = (phase - 0.5) * 1.7
		_upper_pulley.rotation.z = (phase - 0.5) * 0.85

func _set_rope_segment(index: int, from: Vector3, to: Vector3) -> void:
	var segment := _rope_segments[index]
	segment.show()
	var direction := to - from
	segment.position = (from + to) * 0.5
	segment.scale.y = direction.length()
	segment.quaternion = Quaternion(Vector3.UP, direction.normalized())


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = material
	parent.add_child(item)
	return item


func _add_sphere(parent: Node3D, pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	item.mesh = mesh
	item.position = pos
	item.material_override = material
	parent.add_child(item)
	return item


func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, rotation := Vector3.ZERO, sides := 32) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	item.mesh = mesh
	item.position = pos
	item.rotation_degrees = rotation
	item.material_override = material
	parent.add_child(item)
	return item


func _add_torus(parent: Node3D, pos: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 24
	mesh.ring_segments = 64
	item.mesh = mesh
	item.position = pos
	item.rotation_degrees.x = 90
	item.material_override = material
	parent.add_child(item)
	return item


func _beam(from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 24
	beam.mesh = mesh
	beam.material_override = _material(color, 0.42, 0.34)
	beam.position = (from + to) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return beam
