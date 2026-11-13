class_name PhilosopherActor
extends Control
## Ayakta duran, konuşan filozof. Yalnızca görünüm ve animasyon: diyalog, puan ve ses mantığı dışarıdan sürülür.
##
## Düğümün konumu karakterin AYAK ORTASIDIR. Gövde yukarı doğru çizilir.
## Yüz yamaları (face_*, up_*) gövde (body.png) ile birebir piksel kilitlidir (UV deformasyonu yapılmaz);
## böylece Sokrates ve diğer tüm filozoflarda çift burun/göz veya sakal bozulması asla oluşmaz.

signal reaction_finished(kind: StringName)

const CHARACTERS_DIR := "res://stations/philosophy/assets/characters/"
const DATA_PATH := "res://stations/philosophy/data/characters.json"

const MOUTH_MID_AT := 0.14
const MOUTH_OPEN_AT := 0.44
const FRAME_HOLD := 0.055
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

var _fit: float = 1.0
var _body_size := Vector2.ZERO
var _shown: StringName = &"neutral"
var _shown_up: StringName = &"neutral"
var _shown_pose: StringName = &"neutral"
var _fade: Tween
var _up_fade: Tween
var _pose_fade: Tween
var _tone: float = 0.0       # 0 soluk, 1 canlı
var _posture: float = 1.0    # 1 çökük, 0 dik
var _clock: float = 0.0
var _blink_in: float = 2.0
var _blink_left: float = 0.0
var _pending_double_blink: bool = false
var _frame_age: float = 0.0
var _seq_id: int = 0
var _wobble: float = 0.0
var _jolt_y: float = 0.0
var _exit_offset: Vector2 = Vector2.ZERO
var _exit_alpha: float = 1.0

var _mouth_smooth: float = 0.0
var _nod_offset_y: float = 0.0
var _weight_shift: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	for layer: TextureRect in [_body, _pose_under, _pose_over, _head, _under, _over, _up_under, _up_over, _flush, _blink_layer]:
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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

	_shown = &"neutral"
	_shown_up = &"neutral"
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
	_nod_offset_y = 0.0
	_set_frame(&"neutral", 0.0)
	_set_upper(&"neutral", 0.0)
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
	match kind:
		&"stir":
			_jolt_body(-10.0, 0.50)
			_wobble_body(0.012)
			_trigger_blink(true)
			set_pose(&"pose_hand_chin")
			_mood_sequence(kind, [[&"confused", 0.9], [&"thinking", 1.0]])
		&"glimmer":
			_jolt_body(-6.0, 0.42)
			_trigger_blink(true)
			set_pose(&"pose_hand_chin")
			_mood_sequence(kind, [[&"confused", 0.7], [&"smile", 0.9]])
		&"dawn":
			_jolt_body(-8.0, 0.45)
			_wobble_body(0.010)
			set_pose(&"pose_point_up")
			_mood_sequence(kind, [[&"confused", 0.5], [&"smile", 1.1]])
		&"recalled":
			_jolt_body(-7.0, 0.48)
			set_pose(&"pose_arms_open")
			_mood_sequence(kind, [[&"smile", 2.0]])
		&"wrong":
			_wobble_body(0.014)
			_mood_sequence(kind, [[&"confused", 1.0]])
		&"refuse":
			_jolt_body(5.0, 0.38)
			_wobble_body(0.018)
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
	_frame_age += delta
	_update_frame(delta)
	_update_overlays(delta)
	_layout_body()


func _trigger_blink(double_blink: bool = false) -> void:
	_blink_left = 0.13
	_pending_double_blink = double_blink
	_blink_in = 0.16 if double_blink else randf_range(2.2, 4.4)


func _update_frame(delta: float) -> void:
	var raw_level: float = _mouth_level()
	var follow: float = 28.0 if raw_level > _mouth_smooth else 16.0
	_mouth_smooth = lerpf(_mouth_smooth, raw_level, 1.0 - exp(-delta * follow))
	var level: float = _mouth_smooth

	var base_mood: StringName = _resting_mood()
	var wanted_main: StringName = &"neutral"
	var wanted_up: StringName = &"neutral"

	if speaking and level > MOUTH_MID_AT:
		if level > MOUTH_OPEN_AT:
			wanted_main = _closest_mouth(&"mouth_open")
		else:
			wanted_main = _closest_mouth(&"mouth_mid")
		if _uppers.has(base_mood):
			wanted_up = base_mood
	else:
		if has_expression(base_mood):
			wanted_main = base_mood
		elif _uppers.has(base_mood):
			wanted_up = base_mood

	_blink_in -= delta
	if _blink_left > 0.0:
		_blink_left -= delta
	elif _blink_in <= 0.0:
		if _pending_double_blink:
			_pending_double_blink = false
			_blink_left = 0.11
			_blink_in = randf_range(2.4, 4.8)
		else:
			_blink_left = 0.12
			_pending_double_blink = randf() < 0.25
			_blink_in = 0.14 if _pending_double_blink else randf_range(2.2, 4.6)

	var is_mouth_now: bool = String(_shown).begins_with("mouth")
	var is_mouth_want: bool = String(wanted_main).begins_with("mouth")
	if wanted_main != _shown and (not is_mouth_now or _frame_age >= FRAME_HOLD or not is_mouth_want):
		var ftime: float = 0.045 if (is_mouth_want or is_mouth_now) else 0.18
		_set_frame(wanted_main, ftime)

	if wanted_up != _shown_up:
		_set_upper(wanted_up, 0.18)


func _update_overlays(delta: float) -> void:
	var blink_active: bool = _blink_left > 0.0 and mood != &"angry"
	var has_blink_tex: bool = _blink_layer.texture != null
	var blink_target: float = 1.0 if (blink_active and has_blink_tex) else 0.0
	_blink_layer.modulate.a = move_toward(_blink_layer.modulate.a, blink_target, delta * 22.0)

	var use_up_angry: bool = _uppers.has(&"angry")
	var open_mouth: bool = String(_shown).begins_with("mouth")
	var flush_ok: bool = use_up_angry or not open_mouth
	var flush_target: float = clampf(anger / ANGER_FULL, 0.0, 1.0) if (flush_ok and _shown != &"angry" and _shown_up != &"angry") else 0.0
	_flush.modulate.a = move_toward(_flush.modulate.a, flush_target, delta * 6.0)

	for layer: TextureRect in [_head, _under, _over, _up_under, _up_over, _flush, _blink_layer, _pose_under, _pose_over]:
		layer.visible = layer.texture != null and layer.modulate.a > 0.002


func _resting_mood() -> StringName:
	if anger >= 0.50:
		return &"angry"
	if memory_stage >= 4 and mood == &"neutral":
		return &"smile"
	return mood


func _closest_mouth(wanted: StringName) -> StringName:
	if has_expression(wanted):
		return wanted
	var alt: StringName = &"mouth_mid" if wanted == &"mouth_open" else &"mouth_open"
	if has_expression(alt):
		return alt
	return &"neutral"


func _mouth_level() -> float:
	if not speaking:
		return 0.0
	if external_mouth_level >= 0.0:
		return clampf(pow(external_mouth_level, 0.72) * 1.25, 0.0, 1.0)
	var syllable: float = pow(absf(sin(_clock * 7.4)), 0.78)
	var stress: float = 0.48 + 0.52 * absf(sin(_clock * 2.0 + 0.6))
	var pause: float = 0.0 if sin(_clock * 0.62 + 0.4) > 0.86 else 1.0
	return syllable * stress * pause


func _set_frame(frame: StringName, fade_time: float) -> void:
	_frame_age = 0.0
	var tex: Texture2D = null if frame == &"neutral" else (_expressions.get(frame) as Texture2D)
	var previous: Texture2D = null if _shown == &"neutral" else (_expressions.get(_shown) as Texture2D)
	_shown = frame
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if fade_time <= 0.0:
		_under.texture = null
		_over.texture = tex
		_over.modulate.a = 1.0
		return
	# Önceki kare tam opak (_under = 1.0) kalırken yeni kare (_over) üstüne biner; böylece alttaki yüz hayalet yapmaz
	_under.texture = previous
	_under.modulate.a = 1.0
	_over.texture = tex
	_over.modulate.a = 0.0
	_fade = create_tween().set_parallel(true)
	if tex != null:
		_fade.tween_property(_over, "modulate:a", 1.0, fade_time)
	else:
		_fade.tween_property(_under, "modulate:a", 0.0, fade_time)
	_fade.finished.connect(func() -> void: _under.texture = null)


func _set_upper(frame: StringName, fade_time: float) -> void:
	var tex: Texture2D = null if frame == &"neutral" else (_uppers.get(frame) as Texture2D)
	var previous: Texture2D = null if _shown_up == &"neutral" else (_uppers.get(_shown_up) as Texture2D)
	_shown_up = frame
	if _up_fade != null and _up_fade.is_valid():
		_up_fade.kill()
	if fade_time <= 0.0:
		_up_under.texture = null
		_up_over.texture = tex
		_up_over.modulate.a = 1.0
		return
	_up_under.texture = previous
	_up_under.modulate.a = 1.0
	_up_over.texture = tex
	_up_over.modulate.a = 0.0
	_up_fade = create_tween().set_parallel(true)
	if tex != null:
		_up_fade.tween_property(_up_over, "modulate:a", 1.0, fade_time)
	else:
		_up_fade.tween_property(_up_under, "modulate:a", 0.0, fade_time)
	_up_fade.finished.connect(func() -> void: _up_under.texture = null)


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
	var breath: float = sin(_clock * 1.75) * 0.0065
	var slump_drop: float = _posture * 0.012 * _body_size.y * _fit
	_weight_shift = sin(_clock * 0.38) * 3.2 + sin(_clock * 0.17 + 1.0) * 2.0
	var shake: float = 0.0
	if anger > 0.65:
		shake = sin(_clock * 54.0) * (anger - 0.65) * 6.0

	# Konuşurken hece vurgusuyla tüm üst gövde hafifçe onaylama (nod) hareketi yapar
	var target_nod: float = maxf(_mouth_smooth - 0.18, 0.0) * sin(_clock * 5.4) * 3.2
	_nod_offset_y = lerpf(_nod_offset_y, target_nod, 1.0 - exp(-delta * 10.0))

	var s: float = _fit * (1.0 - _posture * 0.010)
	_body.scale = Vector2(s, s * (1.0 + breath))
	_body.rotation = sin(_clock * 0.48) * 0.004 + _posture * 0.008 + _wobble * sin(_clock * 32.0)
	_body.position = Vector2(-_body_size.x * 0.5, -_body_size.y) + _exit_offset + Vector2(
		shake + _weight_shift * _fit,
		slump_drop + (_jolt_y + _nod_offset_y) * _fit
	)
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
