extends "res://scripts/physics/experiment_mission.gd"
## Onarım sözleşmesi: ölçülmüş kanıt, yazılan kural, iki bağımsız uygulama.
## Sayısal sonuçlar istasyon modellerinden gelir; animasyon yalnızca onları gösterir.

const Newton = preload("res://stations/newton/newton_sim.gd")
const Projectile = preload("res://stations/projectile/projectile_sim.gd")
const Collision = preload("res://stations/collision/collision_sim.gd")
const Palette = preload("res://scripts/ui_theme.gd")

enum Phase { CRISIS, TEST, DIAGNOSIS, REPAIR, RECOVERY, SEAL }
var kind := "newton"
var phase := Phase.CRISIS
var records: Array[Dictionary] = []
var recovery_index := 0
var tries_left := 3
var repaired := false
var busy := false
var run_generation := 0
var playback_speed := 1.0
var selected_record := -1
var attached: Array[int] = []
var _elapsed := 0.0
var _case: Dictionary = {}
var _result: Dictionary = {}
var _submitted := NAN
var _run_mode := ""
var _sprite_a: TextureRect
var _sprite_b: TextureRect
var _goal: ColorRect
var _readouts: VBoxContainer
var _plate: Label
var _conditions: Label
var _prediction: Label
var _measurement: Label
var _status: Label
var _evidence_box: VBoxContainer
var _board: PanelContainer

class EvidenceCard extends Button:
	var record_index := -1
	func _get_drag_data(_position: Vector2) -> Variant:
		var preview := Label.new()
		preview.text = text
		set_drag_preview(preview)
		return {"physics_record": record_index}

class PlateTarget extends PanelContainer:
	signal received(index: int)
	func _can_drop_data(_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("physics_record")
	func _drop_data(_position: Vector2, data: Variant) -> void:
		received.emit(int(data.physics_record))

func _make_stage() -> Control:
	return Control.new()

func _begin() -> void:
	step_total = 6
	_build_bench()
	_enter_crisis()

func _build_bench() -> void:
	var paths := {
		"newton": ["rail_bg.png", "sled_heavy.png", "sled_light.png"],
		"projectile": ["range_bg.png", "ball_launch.png", "ball_drop.png"],
		"collision": ["track_bg.png", "cart_a.png", "cart_b.png"]}
	var assets: Array = paths[kind]
	var background := _sprite(String(assets[0]), Vector2.ZERO, Vector2(1280, 720))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sprite_a = _sprite(String(assets[1]), Vector2(140, 300), Vector2(300, 150))
	_sprite_b = _sprite(String(assets[2]), Vector2(500, 300), Vector2(220, 110))
	_goal = ColorRect.new()
	_goal.color = Palette.WARM
	_goal.size = Vector2(4, 145)
	_goal.position = Vector2(760, 310)
	_goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_goal)
	_board = PanelContainer.new()
	_board.position = Vector2(880, 110)
	_board.size = Vector2(372, 0)
	_board.theme_type_variation = "ConsolePanel"
	stage.add_child(_board)
	_readouts = VBoxContainer.new()
	_readouts.add_theme_constant_override("separation", 12)
	_board.add_child(_readouts)
	_plate = _label(_readouts, "", 18)
	_conditions = _label(_readouts, "", 18)
	_prediction = _label(_readouts, "", 19)
	_prediction.add_theme_color_override("font_color", Palette.WARM)
	_measurement = _label(_readouts, "", 22)
	_measurement.add_theme_color_override("font_color", Palette.ACCENT)
	_status = _label(_readouts, "", 16)
	_evidence_box = VBoxContainer.new()
	_evidence_box.add_theme_constant_override("separation", 8)
	_readouts.add_child(_evidence_box)
	resized.connect(_layout_bench)
	_layout_bench()

func _sprite(file: String, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = load("res://stations/%s/assets/%s" % [kind, file])
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.position = pos
	sprite.size = dimensions
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sprite)
	return sprite

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _layout_bench() -> void:
	_board.position = Vector2(size.x - 400, 112)
	_board.size.x = 372

func _fault() -> String:
	return {"newton": "İvme hesabı: kütleyi yok say", "projectile": "Düşüş süresi: yatay hıza bağlı", "collision": "Momentum: yönleri yok say"}[kind]

func _test_case(index: int) -> Dictionary:
	match kind:
		"newton": return {"force": 8.0, "mass": 1.0 if index == 0 else 4.0, "distance": 40.0}
		"projectile": return {"height": 45.0, "speed": 10.0 if index == 0 else 20.0, "target": 60.0}
		_: return {"m1": 3.0, "v1": 2.0, "m2": 2.0, "v2": -1.0 if index == 0 else -2.0}

func _recovery_case(index: int) -> Dictionary:
	match kind:
		"newton": return {"mass": 6.0, "distance": 40.0, "deadline": 4.0} if index == 0 else {"mass": 3.0, "distance": 18.0, "deadline": 3.0}
		"projectile": return {"height": 80.0, "target": 64.0} if index == 0 else {"height": 20.0, "target": 30.0}
		_: return {"m1": 2.0, "v1": 3.0, "m2": 4.0, "v2": -1.5} if index == 0 else {"m1": 2.0, "v1": 2.0, "m2": 3.0, "v2": -3.0}

func _solve(data: Dictionary) -> Dictionary:
	match kind:
		"newton":
			var acceleration := Newton.acceleration(data.force, data.mass)
			return {"time": Newton.time_to_cover(data.distance, acceleration), "acceleration": acceleration}
		"projectile":
			return {"time": Projectile.fall_time(data.height), "range": Projectile.range_for(data.height, data.speed)}
		_:
			return {"speed": Collision.stick_speed(data.m1, data.v1, data.m2, data.v2)}

func _correct_value(data: Dictionary) -> float:
	match kind:
		"newton": return Newton.required_force(data.distance, data.deadline, data.mass)
		"projectile": return Projectile.speed_for_range(data.height, data.target)
		_: return Collision.stick_speed(data.m1, data.v1, data.m2, data.v2)

func _conditions_text(data: Dictionary) -> String:
	match kind:
		"newton": return "Kütle  %s kg\nYol  %s m\n%s" % [_n(data.mass), _n(data.distance), "Kapı  %s s sonra açılır" % _n(data.deadline) if data.has("deadline") else "İtiş  %s N" % _n(data.force)]
		"projectile": return "Yükseklik  %s m\nHedef  %s m\ng = 10 m/s²; hava yok" % [_n(data.height), _n(data.target)]
		_: return "Sağ yön pozitif\nA  %s kg; %s m/s\nB  %s kg; %s m/s\nArabalar yapışır; dış kuvvet yok" % [_n(data.m1), _n(data.v1), _n(data.m2), _n(data.v2)]

func _prediction_text(data: Dictionary) -> String:
	match kind:
		"newton": return "MERİDYEN tahmini\nVarış  %s s" % _n(Newton.time_to_cover(data.distance, Newton.faulty_acceleration(data.force, data.mass)))
		"projectile": return "MERİDYEN tahmini\nDüşüş  %s s" % _n(Projectile.faulty_fall_time(data.height, data.speed))
		_: return "MERİDYEN tahmini\nOrtak hız  %s m/s" % _n((data.m1 * absf(data.v1) + data.m2 * absf(data.v2)) / (data.m1 + data.m2))

func _measurement_text(data: Dictionary) -> String:
	match kind:
		"newton": return "Ölçülen\n%s s; %s m/s²" % [_n(data.time), _n(data.acceleration)]
		"projectile": return "Ölçülen\n%s s; %s m" % [_n(data.time), _n(data.range)]
		_: return "Ölçülen\nOrtak hız  %s m/s" % _n(data.speed)

func _clear_evidence() -> void:
	for child in _evidence_box.get_children():
		_evidence_box.remove_child(child)
		child.queue_free()

func _enter_crisis() -> void:
	run_generation += 1
	busy = false
	phase = Phase.CRISIS
	repaired = false
	records.clear()
	attached.clear()
	recovery_index = 0
	tries_left = 3
	_clear_evidence()
	_plate.text = "MERİDYEN ayarı bozuk\n" + _fault()
	_plate.add_theme_color_override("font_color", Palette.DANGER)
	_status.text = {"newton": "Kargo, kapı kapandıktan sonra geliyor.", "projectile": "Kapsül hedef halkasına ulaşamıyor.", "collision": "Yakalayıcı yanlış yöne gidiyor; yük rayda kaldı."}[kind]
	screen(0, "Kriz", "MERİDYEN'in bozduğu ayarı ölçerek bul; kargoyu kurtar.", "", "Kontrolcünün tahminini gerçek hareketle karşılaştır. Ölçüm kuralını kur, sonra yeni kargoyu taşı.")
	hud.skip.text = "Geç"
	hud.skip.show()
	_start_run(_test_case(1), "crisis")

func _enter_test() -> void:
	phase = Phase.TEST
	_clear_evidence()
	_status.text = "İki koşuda yalnız bir değişken değişir."
	screen(1, "Sına", "İki koşuyu çalıştır; cihazın tahminiyle ölçümü karşılaştır.", "İlk ölçümü çalıştır")
	_add_playback_tools()
	_prepare_case(_test_case(0))

func _add_playback_tools() -> void:
	add_power("Sar", "Aynı koşuyu başa alır; harcanan hak geri gelmez.", _rewind_run)
	add_power("Yavaşlat", "Ölçüm aynı kalır; hareket dört kat yavaş gösterilir.", func(on: bool) -> void: playback_speed = 0.25 if on else 1.0, true)

func _prepare_case(data: Dictionary) -> void:
	_case = data.duplicate()
	_conditions.text = _conditions_text(data)
	_prediction.text = _prediction_text(data) if data.has("force") or data.has("speed") or kind == "collision" else "Hedefi cihazdan oku; ayarı kendin hesapla."
	_measurement.text = "Ölçülen\nHenüz çalıştırılmadı"
	_sprite_a.position = Vector2(130, 300)
	_sprite_b.position = Vector2(560, 300)
	_sprite_a.size = Vector2(260, 130)
	_sprite_b.size = Vector2(220, 110)
	_sprite_b.visible = kind != "newton"
	if kind == "projectile":
		_sprite_a.size = Vector2(30, 30)
		_sprite_b.size = Vector2(30, 30)
		_sprite_a.position = Vector2(180, 170)
		_sprite_b.position = Vector2(240, 170)
	_goal.position = Vector2(770, 280)
	_goal.size = Vector2(4, 160)
	_goal.color = Palette.WARM

func _start_run(data: Dictionary, mode: String, submitted: float = NAN) -> void:
	if busy:
		return
	busy = true
	_run_mode = mode
	_submitted = submitted
	_elapsed = 0.0
	_prepare_case(data)
	_result = _solve(data)
	if mode == "recovery":
		_prediction.text = "Senin ayarın\n" + _n(submitted) + (" N" if kind == "newton" else " m/s")
	elif mode == "repair":
		_prediction.text = _measurement_text(_result).replace("Ölçülen", "Onarılan kontrolcünün tahmini")
	hud.set_action("Çalışıyor", false)
	for child in tools.get_children():
		if child is LineEdit:
			child.editable = false

func _process(delta: float) -> void:
	if not busy:
		return
	_elapsed = minf(_elapsed + delta * playback_speed, 2.8)
	var progress := _elapsed / 2.8
	match kind:
		"newton":
			_sprite_a.position.x = lerpf(130, 650, progress * progress)
		"projectile":
			var displayed_range := minf(float(_result.range) / maxf(float(_case.target), 1.0), 1.3)
			_sprite_a.position = Vector2(180 + 580 * progress * displayed_range, 170 + 340 * progress * progress)
			_sprite_b.position = Vector2(240, 170 + 340 * progress * progress)
			_goal.position = Vector2(760, 500)
			_goal.size = Vector2(8, 45)
		"collision":
			if progress < 0.5:
				_sprite_a.position.x = lerpf(130, 310, progress * 2)
				_sprite_b.position.x = lerpf(560, 500, progress * 2)
			else:
				var drift := float(_result.speed) * (progress - 0.5) * 180
				_sprite_a.position.x = 310 + drift
				_sprite_b.position.x = 500 + drift
			if _run_mode == "recovery":
				_goal.position.x = 500 + _submitted * maxf(progress - 0.5, 0) * 180
	if kind != "collision":
		_measurement.text = "Kronometre\n%s s" % _n(float(_result.time) * progress)
	else:
		_measurement.text = "Çarpışma ölçülüyor" if progress < 0.5 else _measurement_text(_result)
	if progress >= 1.0:
		_finish_run()

func _finish_run() -> void:
	busy = false
	_measurement.text = _measurement_text(_result)
	match _run_mode:
		"crisis":
			hud.set_action("Nedenini bul", true)
		"test":
			records.append({"conditions": _case.duplicate(), "result": _result.duplicate()})
			_status.text = "Ölçüm %d kaydedildi." % records.size()
			hud.set_action("İkinci ölçümü çalıştır" if records.size() == 1 else "Kanıtları incele", true)
		"repair":
			repaired = true
			_plate.text = "Kontrol kuralı onarıldı"
			_plate.add_theme_color_override("font_color", Palette.ACCENT)
			_status.text = "Aynı düzenekte tahmin ve ölçüm örtüştü."
			hud.set_action("Kargoyu kurtar", true)
		"recovery":
			var truth := _correct_value(_recovery_case(recovery_index))
			if absf(_submitted - truth) <= 0.05:
				_goal.color = Palette.ACCENT
				recovery_index += 1
				_status.text = "Kargo kurtarıldı. %d / 2" % recovery_index
				if recovery_index == 2:
					phase = Phase.SEAL
					screen(5, "Mühür", "İki kargo kurtarıldı; onarılan düzeni kayda geçir.", "Mühürle")
				else:
					hud.set_action("Yeni kargoyu getir", true)
			else:
				tries_left -= 1
				_goal.color = Palette.DANGER
				_status.text = "Hedef kaçtı. Kalan hak: %d" % tries_left
				say("Ölçümle hedefi karşılaştır; ayarı yeniden hesapla.", BAD)
				if tries_left == 0:
					_status.text = "Kargolar tükendi. Krizi yeniden ölçmen gerekiyor."
					clear_tools()
					hud.set_action("Krize sar", true)
				else:
					entry.editable = true
					hud.set_action("Ayarı uygula", true)

func _enter_diagnosis() -> void:
	if records.size() < 2:
		return
	phase = Phase.DIAGNOSIS
	_clear_evidence()
	screen(2, "Teşhis", "İki ölçüm fişini çeliştiği MERİDYEN ayarına bırak.", "")
	for index in records.size():
		var card := EvidenceCard.new()
		card.record_index = index
		card.text = "Kayıt %d: %s" % [index + 1, _measurement_text(records[index].result).replace("Ölçülen\n", "")]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.custom_minimum_size.y = 44
		card.pressed.connect(func() -> void:
			selected_record = index
			_status.text = "Kayıt %d seçili. Kanıtı uygula." % (index + 1))
		_evidence_box.add_child(card)
	var target := PlateTarget.new()
	target.theme_type_variation = "ConsolePanel"
	target.received.connect(_attach_evidence)
	_evidence_box.add_child(target)
	_label(target, "Bozuk satır\n" + _fault() + "\nKanıtı buraya bırak", 17)
	add_power("Kanıtı uygula", "Seçilen fişi bozuk satıra bırakmanın klavye karşılığı.", func() -> void: _attach_evidence(selected_record))
	_status.text = "Fişe tıkla, sonra Kanıtı uygula; ya da sürükle."

func _attach_evidence(index: int) -> void:
	if phase != Phase.DIAGNOSIS or index < 0 or index >= records.size() or attached.has(index):
		return
	attached.append(index)
	_status.text = "%d / 2 kanıt plakaya bağlandı." % attached.size()
	if attached.size() == 2:
		_enter_repair()

func _enter_repair() -> void:
	phase = Phase.REPAIR
	_clear_evidence()
	var prompt: String = {"newton": "F ve m ile doğru ivme kuralını yaz.", "projectile": "Düşüş süresinin h ve g ile kuralını yaz.", "collision": "m1, v1, m2, v2 ile toplam momentum kuralını yaz."}[kind]
	screen(3, "Düzelt", prompt, "Kuralı dene", "Çarpma için * veya ·, kare için ^2 veya ² kullanabilirsin. Karekök için sqrt yazabilirsin.")
	add_entry("Doğru kural")
	entry.custom_minimum_size.x = 420
	_status.text = "Kuralı ölçümünden çıkar; kontrolcüye sen yaz."

func _rule_valid(value: String) -> bool:
	var normalized := value.to_lower().replace(" ", "").replace("·", "*").replace("×", "*").replace("²", "^2").replace("₁", "1").replace("₂", "2")
	if "=" in normalized:
		normalized = normalized.get_slice("=", 1)
	match kind:
		"newton": return normalized in ["f/m", "f÷m"]
		"projectile": return normalized in ["sqrt(2*h/g)", "sqrt(2h/g)", "√(2*h/g)", "√(2h/g)"]
		_: return normalized in ["m1*v1+m2*v2", "m1v1+m2v2", "m2*v2+m1*v1", "m2v2+m1v1"]

func _enter_recovery() -> void:
	phase = Phase.RECOVERY
	var data := _recovery_case(recovery_index)
	var instruction: String = {"newton": "Kargo kapı açıldığı anda varmalı. İtişi N olarak hesapla.", "projectile": "Yeni yükseklikte hedefi vuracak yatay hızı hesapla.", "collision": "Yakalayıcıyı birleşen arabaların hızına kur; yönü işaretle."}[kind]
	screen(4, "Toparla", instruction, "Ayarı uygula")
	add_entry("Kuvvet (N)" if kind == "newton" else "Hız (m/s)")
	_conditions.text = _conditions_text(data)
	_prediction.text = "Yeni kargo %d / 2" % (recovery_index + 1)
	_measurement.text = "Ölçüm, gönderdiğin ayardan sonra görünür."
	_status.text = "Kalan hak: %d / 3" % tries_left

func _on_skip() -> void:
	if phase == Phase.CRISIS:
		busy = false
		_enter_test()

func _rewind_run() -> void:
	if not busy:
		return
	_elapsed = 0.0
	# Kaydı ve hakkı değiştirmeden aynı koşu tekrar oynatılır.

func _on_action() -> void:
	if busy or _sealed:
		return
	match phase:
		Phase.CRISIS: _enter_test()
		Phase.TEST:
			if records.size() == 2:
				_enter_diagnosis()
			else:
				_start_run(_test_case(records.size()), "test")
		Phase.REPAIR:
			if repaired:
				_enter_recovery()
			elif _rule_valid(entry.text):
				_start_run(_test_case(1), "repair")
			else:
				say("Yazdığın kural iki ölçümle örtüşmüyor.", BAD)
		Phase.RECOVERY:
			if tries_left == 0:
				_enter_crisis()
			elif hud.action.text == "Yeni kargoyu getir":
				_enter_recovery()
			else:
				var value := read_number()
				if not is_finite(value):
					say("Ayarı sayı olarak gir; birimi kutuya yazma.", BAD)
					return
				if (kind == "newton" and (value <= 0 or value > 100)) or (kind == "projectile" and (value <= 0 or value > 100)) or (kind == "collision" and absf(value) > 10):
					say("Ayar cihazın aralığı dışında.", BAD)
					return
				var data := _recovery_case(recovery_index)
				if kind == "newton": data.force = value
				elif kind == "projectile": data.speed = value
				_start_run(data, "recovery", value)
		Phase.SEAL:
			seal("MERİDYEN'in ayarı ölçümle düzeltildi; iki yeni kargo kurtarıldı.", "Düzen onarıldı.")

func _n(value: float) -> String:
	return ("%.2f" % value).replace(".", ",")
