extends SceneTree
## Rendering review without TTS/LLM calls. Run with a real rendering driver.
## Godot --path . --script res://stations/history/tools/review_assets.gd

class SilentMission extends "res://stations/history/mission.gd":
	func _speak_stage_line(level: int, custom_line_id: StringName = &"") -> void:
		var id: StringName = ORDER[_index]
		var lid := custom_line_id if custom_line_id != &"" else StringName("stage_%d" % level)
		stage.show_line(NAMES[id], stage.voice.get_line_text(id, lid))

var failures: Array[String] = []
var _completed_count := 0


func _initialize() -> void:
	call_deferred("_review")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _frames() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw


func _review() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var mission := SilentMission.new()
	mission.route = &"ayt"
	mission.completed.connect(func() -> void: _completed_count += 1)
	root.add_child(mission)
	mission.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mission.stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames()
	var stage: Control = mission.stage
	_check(stage.size == Vector2(1280, 720), "stage did not fill target viewport")
	var output := "res://stations/history/review"
	DirAccess.make_dir_recursive_absolute(output)
	for index in mission.ORDER.size():
		mission._pick(index)
		await _frames()
		var id: String = String(mission.ORDER[index])
		var actor: Node2D = stage.actor
		var meta: Dictionary = actor.get_metadata()
		_check(not meta.is_empty(), id + ": missing provenance")
		_check(actor._body.material == null, id + ": artwork must not be faded by shader")
		var bounds := Rect2(actor.position + actor._body.position * actor.scale,
			actor._body_size * actor.scale)
		_check(stage._art_area.grow(1).encloses(bounds), id + ": artwork clipped")
		var original_scale: Vector2 = actor.scale
		stage.set_memory_stage(4, false)
		stage.set_anger(1, false)
		actor.set_speaking(true, 1)
		await _frames()
		_check(actor.modulate == Color.WHITE and actor._body.modulate == Color.WHITE,
			id + ": game state altered artwork colours")
		_check(actor.scale == original_scale, id + ": layout changed after a frame")
		stage.set_memory_stage(0, false)
		stage.set_anger(0, false)
		actor.set_speaking(false)
		stage._inspect_button.pressed.emit()
		_check(stage._viewer.visible, id + ": inspection button did not open viewer")
		_check(stage._viewer_image.texture.get_size() == Vector2(meta["body_size"][0],
			meta["body_size"][1]), id + ": viewer did not load full original")
		stage._viewer.hide()
		await _frames()
		root.get_texture().get_image().save_png(output + "/" + id + ".png")
		print("PASS archive ", id)
	mission._pick(2)
	mission.stage._inspect_button.pressed.emit()
	await _frames()
	root.get_texture().get_image().save_png(output + "/fatih-inspection.png")
	stage._viewer.hide()
	# Exercise real decision data and retry without network-backed speech.
	mission._pick(2)
	var choices: Array = stage.voice.get_choices(&"fatih")
	for choice: Dictionary in choices:
		if not choice.get("correct", false):
			var wrong: Dictionary = choice.duplicate()
			wrong.erase("reply")
			mission._on_card_selected(wrong)
			break
	_check(mission._stage_level == 0 and mission._anger > 0, "wrong decision advanced progress")
	for level in 4:
		for choice: Dictionary in choices:
			if choice.get("correct", false) and int(choice.get("stage", -1)) in [-1, level]:
				var correct: Dictionary = choice.duplicate()
				correct.erase("reply")
				mission._on_card_selected(correct)
				break
	_check(mission._stage_level == 4 and _completed_count == 1, "correct decisions did not complete once")
	mission._on_action_pressed()
	_check(mission._stage_level == 0 and mission._anger == 0, "retry did not reset decision state")
	await _frames()
	# Verify failure/retry reset and resized layout after both column modes.
	await stage.actor.exit_angry(0.01).finished
	mission._pick(2)
	_check(stage.actor.modulate == Color.WHITE, "retry kept faded-out artwork")
	stage.actor.exit_angry(1.4)
	mission._on_action_pressed()
	await _frames()
	_check(stage.actor.modulate == Color.WHITE, "active exit tween faded artwork after retry")
	root.size = Vector2i(800, 720)
	root.content_scale_size = Vector2i(800, 720)
	await _frames()
	_check(stage._choice_scroll.get_rect().end.x <= 800, "compact controls outside viewport")
	root.get_texture().get_image().save_png(output + "/compact.png")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await _frames()
	_scale_fonts(mission)
	await _frames()
	root.get_texture().get_image().save_png(output + "/fatih-130.png")
	print("HISTORY REVIEW: ", failures.size(), " failure(s)")
	mission.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _scale_fonts(node: Node) -> void:
	if node is Label or node is Button or node is LineEdit:
		node.add_theme_font_size_override("font_size", roundi(node.get_theme_font_size("font_size") * 1.3))
	if node is RichTextLabel:
		for key in ["normal_font_size", "bold_font_size"]:
			node.add_theme_font_size_override(key, roundi(node.get_theme_font_size(key) * 1.3))
	for child in node.get_children():
		_scale_fonts(child)
