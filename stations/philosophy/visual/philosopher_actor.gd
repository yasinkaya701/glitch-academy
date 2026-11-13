class_name PhilosopherActor
extends Control
## Ayakta duran, konuşan filozof. Yalnızca görünüm ve animasyon: diyalog, puan ve ses mantığı dışarıdan sürülür.
##
## Düğümün konumu karakterin AYAK ORTASIDIR. Gövde yukarı doğru çizilir.
## Canlı animasyon katmanları:
##   1. Gövde shader'ı (body_live.gdshader): nefes alıp verme, omuz hareketi, ağırlık aktarımı ve konuşurken el/önkol jestleri
##   2. Sürekli 60 FPS dudak karıştırıcısı: ses zarfına (_mouth_smooth) göre face_mouth_mid ve face_mouth_open yamalarını
##      her karede kesintisiz harmanlar; konuşma durduğunda dinlenme ifadesine (smile, confused, angry) geçer
##   3. Üst yüz yaması (up_<ifade>.png) ve göz kırpma katmanı (up_eyes_closed.png): konuşurken bile kaş ve göz kırpmayı korur
##   4. Baş/yüz mikro-deformasyon shader'ı (face_live.gdshader): baş eğimi, konuşma onayı (nod), çene esnemesi, kaş/göz hareketi

signal reaction_finished(kind: StringName)

const CHARACTERS_DIR := "res://stations/philosophy/assets/characters/"
const DATA_PATH := "res://stations/philosophy/data/characters.json"
const FACE_SHADER := preload("res://stations/philosophy/visual/face_live.gdshader")
const BODY_SHADER := preload("res://stations/philosophy/visual/body_live.gdshader")

const COLD_TONE := Color(0.88, 0.91, 0.96)
const WARM_TONE := Color(1.0, 0.99, 0.96)
const ANGER_FULL := 0.60

var philosopher_id: StringName = &""
var mood: StringName = &"neutral"
var pose: StringName = &"neutral"
var memory_stage: int = 0
var anger: float = 0.0
var speaking: bool = false
var external_mouth_level: float = -1.0
var auto_react: bool = true

var _expressions: Dictionary = {}  # kare adı -> Texture2D (face_*)
var _uppers: Dictionary = {}       # kare adı -> Texture2D (up_*)
var _poses: Dictionary = {}        # duruş adı -> {tex: Texture2D, rect: Rect2}

var _body := TextureRect.new()
var _pose_under := TextureRect.new()
var _pose_over := TextureRect.new()
var _head := TextureRect.new()
var _under := TextureRect.new()
var _over := TextureRect.new()
var _up_under := TextureRect.new()
var _up_over := TextureRect.new()
var _flush := TextureRect.new()
var _blink_layer := TextureRect.new()
var _face_mat := ShaderMaterial.new()
var _body_mat := ShaderMaterial.new()

var _fit: float = 1.0
var _body_size := Vector2.ZERO
var _shown_pose: StringName = &"neutral"
var _pose_fade: Tween
var _tone: float = 0.0       # 0 soluk, 1 canlı
var _posture: float = 1.0    # 1 çökük, 0 dik
var _clock: float = 0.0
var _blink_in: float = 1.8
var _blink_left: float = 0.0
var _pending_double_blink: bool = false
var _seq_id: int = 0
var _wobble: float = 0.0
var _jolt_y: float = 0.0
var _exit_offset: Vector2 = Vector2.ZERO
var _exit_alpha: float = 1.0

var _mouth_smooth: float = 0.0
var _gesture_smooth: float = 0.0
var _gesture_boost: float = 0.0
var _brow_cur: float = 0.0
var _squint_cur: float = 0.0
var _head_tilt: float = 0.0
var _head_dy: float = 0.0
var _head_dx: float = 0.0
var _nod_phase: float = 0.0
var _weight_shift: float = 0.0
var _gaze_timer: float = 1.2
var _gaze_target := Vector2.ZERO
var _gaze_cur := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_face_mat.shader = FACE_SHADER
	_body_mat.shader = BODY_SHADER
	for layer: TextureRect in [_body, _pose_under, _pose_over, _head, _under, _over, _up_under, _up_over, _flush, _blink_layer]:
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_body.material = _body_mat
	for face_layer: TextureRect in [_head, _under, _over, _up_under, _up_over, _flush, _blink_layer]:
		face_layer.material = _face_mat
	add_child(_body)
	_body.add_child(_pose_under)
	_body.add_child(_pose_over)
	_body.add_child(_head)
	_head.add_child(_under)
	_head.add_child(_over)
	_head.add_child(_up_under)
	_head.add_child(_up_over)
	_head.add_child(_flush)
	_head.add_child(_blink_layer)
	_apply_tone()


func load_philosopher(id: StringName) -> bool:
	var meta: Dictionary = _read_meta(id)
	if meta.is_empty():
		push_warning("PhilosopherActor: '%s' için karakter verisi yok." % id)
		return false
	var dir: String = CHARACTERS_DIR + String(id) + "/"
	var body_tex := load(dir + "body.png") as Texture2D
	if body_tex == null:
		push_warning("PhilosopherActor: %sbody.png yüklenemedi." % dir)
		return false
	philosopher_id = id
	_expressions.clear()
	_uppers.clear()
	_poses.clear()
	for e: String in meta.get("expressions", []):
		var t := load(dir + "face_%s.png" % e) as Texture2D
		if t != null:
			_expressions[StringName(e)] = t
	for u: String in meta.get("upper", []):
		var ut := load(dir + "up_%s.png" % u) as Texture2D
		if ut != null:
			_uppers[StringName(u)] = ut
	var poses_dict: Dictionary = meta.get("poses", {})
	for p_name: String in poses_dict.keys():
		var pt := load(dir + "%s.png" % p_name) as Texture2D
		var pr: Array = poses_dict[p_name]
		if pt != null and pr.size() == 4:
			_poses[StringName(p_name)] = {"tex": pt, "rect": Rect2(pr[0], pr[1], pr[2], pr[3])}

	_body_size = body_tex.get_size()
	_body.texture = body_tex
	_body.size = _body_size
	_body.pivot_offset = Vector2(_body_size.x * 0.5, _body_size.y)

	var fr: Array = meta["face_rect"]
	var fsize := Vector2(fr[2], fr[3])
	_head.texture = load(dir + "head.png") as Texture2D
	_head.position = Vector2(fr[0], fr[1])
	_head.size = fsize
	_head.set_meta(&"home", Vector2(fr[0], fr[1]))
	var neck: Array = meta.get("neck", [fr[2] * 0.5, fr[3] * 0.66])
	_head.pivot_offset = Vector2(neck[0], neck[1])

	var mouth_y_px: float = float(meta.get("mouth_y", fr[3] * 0.46))
	_face_mat.set_shader_parameter("mouth_y_uv", clampf(mouth_y_px / maxf(fsize.y, 1.0), 0.32, 0.68))

	for layer: TextureRect in [_under, _over, _up_under, _up_over, _flush, _blink_layer]:
		layer.position = Vector2.ZERO
		layer.size = fsize
		layer.texture = null
	_flush.texture = (_uppers.get(&"angry") if _uppers.has(&"angry") else _expressions.get(&"angry")) as Texture2D
	_flush.modulate.a = 0.0
	_blink_layer.texture = (_uppers.get(&"eyes_closed") if _uppers.has(&"eyes_closed") else _expressions.get(&"eyes_closed")) as Texture2D
	_blink_layer.modulate.a = 0.0

	for pl: TextureRect in [_pose_under, _pose_over]:
		pl.texture = null
		pl.modulate.a = 0.0

	_shown_pose = &"neutral"
	reset_state()
	return true


func fit_to_height(height_px: float) -> void:
	if _body_size.y <= 0.0:
		return
	_fit = height_px / _body_size.y
	_layout_body()


func get_height() -> float:
	return _body_size.y * _fit


func head_offset() -> Vector2:
	return Vector2(0.0, -get_height() * 0.88)


func has_expression(frame: StringName) -> bool:
	return frame == &"neutral" or _expressions.has(frame)


func reset_state() -> void:
	_seq_id += 1
	memory_stage = 0
	anger = 0.0
	speaking = false
	external_mouth_level = -1.0
	mood = &"neutral"
	pose = &"neutral"
	_tone = 0.0
	_posture = 1.0
	_wobble = 0.0
	_jolt_y = 0.0
	_exit_offset = Vector2.ZERO
	_exit_alpha = 1.0
	_mouth_smooth = 0.0
	_gesture_smooth = 0.0
	_gesture_boost = 0.0
	_brow_cur = 0.0
	_squint_cur = 0.0
	_under.texture = null
	_over.texture = null
	_up_under.texture = null
	_up_over.texture = null
	set_pose(&"neutral", 0.0)
	_apply_tone()
	_layout_body()


func set_speaking(on: bool, level: float = -1.0) -> void:
	speaking = on
	external_mouth_level = level


func feed_mouth_level(level: float) -> void:
	external_mouth_level = clampf(level, 0.0, 1.0)


func set_mood(new_mood: StringName) -> void:
	mood = new_mood


func set_pose(new_pose: StringName, fade_time: float = 0.32) -> void:
	pose = new_pose
	var target_name: StringName = new_pose if _poses.has(new_pose) else &"neutral"
	if target_name == _shown_pose and fade_time > 0.0:
		return
	var prev_info: Dictionary = _poses.get(_shown_pose, {})
	var next_info: Dictionary = _poses.get(target_name, {})
	_shown_pose = target_name
	if _pose_fade != null and _pose_fade.is_valid():
		_pose_fade.kill()
	if fade_time <= 0.0:
		_pose_under.texture = null
		if next_info.is_empty():
			_pose_over.texture = null
		else:
			_pose_over.texture = next_info["tex"]
			_pose_over.position = (next_info["rect"] as Rect2).position
			_pose_over.size = (next_info["rect"] as Rect2).size
			_pose_over.modulate.a = 1.0
		return
	if not prev_info.is_empty():
		_pose_under.texture = prev_info["tex"]
		_pose_under.position = (prev_info["rect"] as Rect2).position
		_pose_under.size = (prev_info["rect"] as Rect2).size
		_pose_under.modulate.a = 1.0
	else:
		_pose_under.texture = null
	if not next_info.is_empty():
		_pose_over.texture = next_info["tex"]
		_pose_over.position = (next_info["rect"] as Rect2).position
		_pose_over.size = (next_info["rect"] as Rect2).size
		_pose_over.modulate.a = 0.0
	else:
		_pose_over.texture = null
	_pose_fade = create_tween().set_parallel(true)
	if _pose_over.texture != null:
		_pose_fade.tween_property(_pose_over, "modulate:a", 1.0, fade_time)
	if _pose_under.texture != null:
		_pose_fade.tween_property(_pose_under, "modulate:a", 0.0, fade_time)
	_pose_fade.finished.connect(func() -> void: _pose_under.texture = null)


func set_memory_stage(stage: int, animate: bool = true) -> void:
	var s: int = clampi(stage, 0, 4)
	var rising: bool = s > memory_stage
	memory_stage = s
	var target_tone: float = float(s) / 4.0
	var target_posture: float = 1.0 - target_tone
	if animate:
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_method(_set_tone, _tone, target_tone, 1.2)
		tw.tween_method(_set_posture, _posture, target_posture, 1.2)
	else:
		_set_tone(target_tone)
		_set_posture(target_posture)
	if animate and auto_react and rising:
		match s:
			1: play_reaction(&"stir")
			2: play_reaction(&"glimmer")
			3: play_reaction(&"dawn")
			4: play_reaction(&"recalled")


func set_anger(value: float, animate: bool = true) -> void:
	var target: float = clampf(value, 0.0, 1.0)
	if animate:
		create_tween().tween_method(_set_anger_value, anger, target, 0.35)
	else:
		_set_anger_value(target)


func play_reaction(kind: StringName) -> void:
	_pulse_gesture(1.0, 1.4)
	match kind:
		&"stir":
			_jolt_body(-12.0, 0.55)
			_wobble_body(0.018)
			_trigger_blink(true)
			set_pose(&"pose_hand_chin")
			_mood_sequence(kind, [[&"confused", 0.9], [&"thinking", 1.0]])
		&"glimmer":
			_jolt_body(-8.0, 0.45)
			_trigger_blink(true)
			set_pose(&"pose_hand_chin")
			_mood_sequence(kind, [[&"confused", 0.7], [&"smile", 0.9]])
		&"dawn":
			_jolt_body(-10.0, 0.45)
			_wobble_body(0.014)
			set_pose(&"pose_point_up")
			_mood_sequence(kind, [[&"confused", 0.5], [&"smile", 1.1]])
		&"recalled":
			_jolt_body(-9.0, 0.50)
			set_pose(&"pose_arms_open")
			_mood_sequence(kind, [[&"smile", 2.0]])
		&"wrong":
			_wobble_body(0.020)
			_mood_sequence(kind, [[&"confused", 1.0]])
		&"refuse":
			_jolt_body(6.0, 0.40)
			_wobble_body(0.026)
			set_pose(&"pose_dismiss")
			_mood_sequence(kind, [[&"angry", 1.4]])
		_:
			push_warning("PhilosopherActor: bilinmeyen tepki '%s'." % kind)


func exit_angry(duration: float = 1.1) -> void:
	_seq_id += 1
	speaking = false
	mood = &"angry"
	_set_anger_value(1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_method(_set_exit_alpha, _exit_alpha, 0.0, duration).set_delay(0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_exit_offset", Vector2(get_height() * 0.28, 0.0), duration).set_delay(0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func() -> void: reaction_finished.emit(&"exit_angry"))


func slump_defeated(duration: float = 1.2) -> void:
	_seq_id += 1
	speaking = false
	mood = &"confused"
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_method(_set_tone, _tone, 0.0, duration)
	tw.tween_method(_set_posture, _posture, 1.0, duration)
	tw.finished.connect(func() -> void: reaction_finished.emit(&"slump_defeated"))


func _process(delta: float) -> void:
	if _body.texture == null:
		return
	_clock += delta
	_update_gaze(delta)
	_update_continuous_face(delta)
	_update_shader_and_overlays(delta)
	_layout_body()


func _update_gaze(delta: float) -> void:
	_gaze_timer -= delta
	if _gaze_timer <= 0.0:
		_gaze_timer = randf_range(0.9, 2.2)
		var spread: float = 2.4 if (speaking or mood == &"thinking" or mood == &"confused") else 1.2
		_gaze_target = Vector2(randf_range(-spread, spread), randf_range(-spread * 0.7, spread * 0.7))
	_gaze_cur = _gaze_cur.lerp(_gaze_target, 1.0 - exp(-delta * 7.5))


func _trigger_blink(double_blink: bool = false) -> void:
	_blink_left = 0.13
	_pending_double_blink = double_blink
	_blink_in = 0.16 if double_blink else randf_range(2.0, 4.2)


func _update_continuous_face(delta: float) -> void:
	var raw_level: float = _mouth_level()
	var follow: float = 32.0 if raw_level > _mouth_smooth else 18.0
	_mouth_smooth = lerpf(_mouth_smooth, raw_level, 1.0 - exp(-delta * follow))

	# Doğal göz kırpma
	_blink_in -= delta
	if _blink_left > 0.0:
		_blink_left -= delta
	elif _blink_in <= 0.0:
		if _pending_double_blink:
			_pending_double_blink = false
			_blink_left = 0.12
			_blink_in = randf_range(2.2, 4.5)
		else:
			_blink_left = 0.13
			_pending_double_blink = randf() < 0.28
			_blink_in = 0.15 if _pending_double_blink else randf_range(2.0, 4.2)

	var base_mood: StringName = _resting_mood()
	var mid_tex: Texture2D = _expressions.get(&"mouth_mid") as Texture2D
	var open_tex: Texture2D = _expressions.get(&"mouth_open") as Texture2D

	if speaking or _mouth_smooth > 0.04:
		# Konuşurken 60 FPS kesintisiz ağız açıklığı harmanlaması
		_under.texture = mid_tex if mid_tex != null else open_tex
		_under.modulate.a = clampf(_mouth_smooth * 2.4, 0.0, 1.0)
		_over.texture = open_tex
		_over.modulate.a = clampf((_mouth_smooth - 0.26) * 1.65, 0.0, 1.0)

		# Üst yüz ifadesi konuşurken ayrı katmanda korunur
		var up_tex: Texture2D = _uppers.get(base_mood) as Texture2D
		_up_over.texture = up_tex
		_up_over.modulate.a = move_toward(_up_over.modulate.a, 1.0 if up_tex != null else 0.0, delta * 6.0)
	else:
		# Dinlenirken tam yüz ifadesi (smile, confused, angry)
		_under.modulate.a = move_toward(_under.modulate.a, 0.0, delta * 10.0)
		if _under.modulate.a <= 0.01:
			_under.texture = null
		var mood_tex: Texture2D = _expressions.get(base_mood) as Texture2D
		if mood_tex != null:
			_over.texture = mood_tex
			_over.modulate.a = move_toward(_over.modulate.a, 1.0, delta * 5.0)
		else:
			_over.modulate.a = move_toward(_over.modulate.a, 0.0, delta * 6.0)
			if _over.modulate.a <= 0.01:
				_over.texture = null
		_up_over.modulate.a = move_toward(_up_over.modulate.a, 0.0, delta * 6.0)
		if _up_over.modulate.a <= 0.01:
			_up_over.texture = null


func _update_shader_and_overlays(delta: float) -> void:
	# 1. Göz kırpma katmanı
	var blink_active: bool = _blink_left > 0.0 and mood != &"angry"
	var has_blink_tex: bool = _blink_layer.texture != null
	var blink_target: float = 1.0 if (blink_active and has_blink_tex) else 0.0
	_blink_layer.modulate.a = move_toward(_blink_layer.modulate.a, blink_target, delta * 22.0)

	# 2. Kızgınlık / kızarma üst yüz yaması
	var flush_target: float = clampf(anger / ANGER_FULL, 0.0, 1.0)
	_flush.modulate.a = move_toward(_flush.modulate.a, flush_target, delta * 6.0)

	# 3. Canlı mikro-deformasyon shader parametreleri
	var brow_t: float = 0.0
	var squint_t: float = 0.0
	match _resting_mood():
		&"confused":
			brow_t = 0.85
			squint_t = 0.15
		&"thinking":
			brow_t = -0.48
			squint_t = 0.48
		&"angry":
			brow_t = -0.95
			squint_t = 0.60
		&"smile":
			brow_t = 0.35
			squint_t = 0.35
		_:
			brow_t = -0.15 * _posture
			squint_t = 0.10 * _posture

	brow_t += maxf(_mouth_smooth - 0.20, 0.0) * 0.55
	brow_t -= anger * 0.70
	if blink_active and not has_blink_tex:
		squint_t = 1.0

	_brow_cur = lerpf(_brow_cur, clampf(brow_t, -1.0, 1.0), 1.0 - exp(-delta * 12.0))
	_squint_cur = lerpf(_squint_cur, clampf(squint_t, 0.0, 1.0), 1.0 - exp(-delta * 15.0))

	_face_mat.set_shader_parameter("jaw_open", clampf(_mouth_smooth * 0.85, 0.0, 1.0))
	_face_mat.set_shader_parameter("brow_lift", _brow_cur)
	_face_mat.set_shader_parameter("eye_squint", _squint_cur)
	_face_mat.set_shader_parameter("cheek_blush", clampf(anger, 0.0, 1.0))

	# 4. Gövde nefes ve el/kol jestleri (body_live.gdshader)
	var want_gesture: float = clampf((0.65 if speaking else 0.0) + _mouth_smooth * 0.55 + _gesture_boost, 0.0, 1.0)
	_gesture_smooth = lerpf(_gesture_smooth, want_gesture, 1.0 - exp(-delta * 6.5))
	_body_mat.set_shader_parameter("breath", sin(_clock * 1.85))
	_body_mat.set_shader_parameter("speak_gesture", _gesture_smooth)
	_body_mat.set_shader_parameter("gesture_phase", fmod(_clock * 3.4, TAU))
	_body_mat.set_shader_parameter("lean_x", sin(_clock * 0.55) * 0.35 + (_gaze_cur.x * 0.18))
	_body_mat.set_shader_parameter("slump", _posture * 0.65)

	for layer: TextureRect in [_head, _under, _over, _up_under, _up_over, _flush, _blink_layer, _pose_under, _pose_over]:
		layer.visible = layer.texture != null and layer.modulate.a > 0.002


func _resting_mood() -> StringName:
	if anger >= 0.50:
		return &"angry"
	if memory_stage >= 4 and mood == &"neutral":
		return &"smile"
	return mood


func _mouth_level() -> float:
	if not speaking:
		return 0.0
	if external_mouth_level >= 0.0:
		# Gerçek ses zarfına canlı hece kontrastı ekle (ağzın açılıp kapanması net görünsün)
		return clampf(pow(external_mouth_level, 0.72) * 1.25, 0.0, 1.0)
	var syllable: float = pow(absf(sin(_clock * 7.5)), 0.75)
	var stress: float = 0.50 + 0.50 * absf(sin(_clock * 2.1 + 0.6))
	var pause: float = 0.0 if sin(_clock * 0.65 + 0.4) > 0.85 else 1.0
	return syllable * stress * pause


func _mood_sequence(kind: StringName, steps: Array) -> void:
	_seq_id += 1
	var my_id: int = _seq_id
	for step: Array in steps:
		if my_id != _seq_id:
			return
		mood = step[0]
		await get_tree().create_timer(float(step[1])).timeout
	if my_id != _seq_id:
		return
	mood = &"smile" if memory_stage >= 4 else &"neutral"
	set_pose(&"neutral")
	reaction_finished.emit(kind)


func _pulse_gesture(strength: float, duration: float) -> void:
	create_tween().tween_method(func(v: float) -> void: _gesture_boost = v, strength, 0.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _wobble_body(strength: float) -> void:
	create_tween().tween_method(func(v: float) -> void: _wobble = v, strength, 0.0, 0.85)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _jolt_body(px: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _jolt_y = v, px, 0.0, duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_tone(v: float) -> void:
	_tone = v
	_apply_tone()


func _set_posture(v: float) -> void:
	_posture = v


func _set_anger_value(v: float) -> void:
	anger = v
	_apply_tone()


func _set_exit_alpha(v: float) -> void:
	_exit_alpha = v


func _apply_tone() -> void:
	var c: Color = COLD_TONE.lerp(WARM_TONE, _tone)
	c.a = _exit_alpha
	_body.modulate = c


func _layout_body() -> void:
	if _body.texture == null:
		return
	var delta: float = get_process_delta_time()
	var breath: float = sin(_clock * 1.85) * 0.009
	var slump_drop: float = _posture * 0.015 * _body_size.y * _fit
	_weight_shift = sin(_clock * 0.42) * 4.5 + sin(_clock * 0.19 + 1.0) * 2.8
	var shake: float = 0.0
	if anger > 0.65:
		shake = sin(_clock * 54.0) * (anger - 0.65) * 7.0
	var s: float = _fit * (1.0 - _posture * 0.012)
	_body.scale = Vector2(s, s * (1.0 + breath))
	_body.rotation = sin(_clock * 0.55) * 0.0055 + _posture * 0.010 + _wobble * sin(_clock * 32.0)
	_body.position = Vector2(-_body_size.x * 0.5, -_body_size.y) + _exit_offset + Vector2(shake + _weight_shift * _fit, slump_drop)

	# Baş: ruh haline göre duruş + sakkadik odak + konuşurken belirgin onaylama (nod) ve eğilme
	var tilt_t: float = _gaze_cur.x * 0.014
	var dy_t: float = _gaze_cur.y * 2.8 + _jolt_y
	var dx_t: float = _gaze_cur.x * 3.2
	match _resting_mood():
		&"confused":
			tilt_t += 0.052
			dy_t += -3.5
			dx_t += 4.0
		&"thinking":
			tilt_t += -0.032
			dy_t += 5.0
			dx_t += -3.5
		&"angry":
			tilt_t += -0.024
			dy_t += 4.5
		&"smile":
			tilt_t += 0.018
			dy_t += -3.0
	tilt_t += _posture * 0.028
	dy_t += _posture * 4.8

	var emphasis: float = maxf(_mouth_smooth - 0.15, 0.0)
	_nod_phase = lerpf(_nod_phase, emphasis, 1.0 - exp(-delta * 11.0))
	dy_t += _nod_phase * 8.5 * sin(_clock * 5.2) - sin(_clock * 1.85 - 0.35) * 2.2
	dx_t += _nod_phase * 3.5 * cos(_clock * 2.7)
	tilt_t += _nod_phase * sin(_clock * 3.4) * 0.022

	var k: float = 1.0 - exp(-delta * 7.0)
	_head_tilt = lerpf(_head_tilt, tilt_t, k)
	_head_dy = lerpf(_head_dy, dy_t, k)
	_head_dx = lerpf(_head_dx, dx_t, k)
	_head.rotation = 0.0
	var fr_pos: Vector2 = _head.get_meta(&"home", _head.position)
	_head.position = fr_pos
	var fsize: Vector2 = _head.size.max(Vector2.ONE)
	_face_mat.set_shader_parameter("head_tilt", _head_tilt)
	_face_mat.set_shader_parameter("head_shift", Vector2(_head_dx / fsize.x, _head_dy / fsize.y))
	_apply_alpha_only()


func _apply_alpha_only() -> void:
	if _body.modulate.a != _exit_alpha:
		var c := _body.modulate
		c.a = _exit_alpha
		_body.modulate = c


func _read_meta(id: StringName) -> Dictionary:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has(String(id)):
		return (parsed as Dictionary)[String(id)]
	return {}
