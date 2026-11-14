extends SceneTree
var failures := 0
var output := OS.get_environment("LGS_3D_REVIEW_DIR")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720)
	var center = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	await process_frame
	var intro = center.get_node_or_null("Intro")
	if intro != null: intro.queue_free()
	center._select_route(&"lgs")
	for definition in center.visible_missions:
		center.selected_mission = definition
		center._launch_selected_mission()
		await process_frame
		var m = center.active_mission
		var id: String = String(definition.id)
		await inspect(m,id + "-start")
		if id in ["turkish","english","religion"]:
			m._begin_test()
			m._advance_phase()
			await inspect(m,id + "-evidence")
			var data: Dictionary = m.PACK[id]
			m._choose_evidence(int(data.steps[0].answer),0)
			await inspect(m,id + "-evidence2")
			m._choose_evidence(int(data.steps[1].answer),1)
			await inspect(m,id + "-repair")
			m._choose_repair(int(data.steps[2].answer))
			await inspect(m,id + "-rescue")
		elif id == "pulley":
			m._advance()
			m._pull_rope(Vector2(0,120))
			m._advance()
			m._select_mode(1)
			m._pull_rope(Vector2(0,120))
			m._advance()
			await inspect(m,id + "-evidence")
			m._select_evidence(1)
			m._advance()
			await inspect(m,id + "-repair")
			m._toggle_support_count()
			m._advance()
			await inspect(m,id + "-rescue")
		elif id == "history":
			for level in range(4):
				for card in m.stage.voice.get_choices(&"ataturk"):
					if bool(card.get("correct",false)) and int(card.get("stage",-1)) == level:
						m._on_card_selected(card)
						break
				await inspect(m,id + "-record%d" % (level+1))
		elif id == "genetics":
			m._select_example(0)
			m._select_example(1)
			await inspect(m,id + "-experiment")
			m._enter_prediction()
			await inspect(m,id + "-prediction")
			m._prediction.text = "50"
			m._submit_prediction()
			await inspect(m,id + "-repaired")
		elif id in ["bridge","pressure","indicator"]:
			m._skip_intro()
			await inspect(m,id + "-experiment")
		elif id == "seasons":
			m._show_experiment()
			await inspect(m,id + "-experiment")
		center._return_to_hub()
		await process_frame
	center.queue_free()
	await process_frame
	print("LAYOUT FAILURES: ",failures)
	quit(failures)
func inspect(m: Control, label: String) -> void:
	enlarge_fonts(m)
	await process_frame
	await process_frame
	var bounds := m.get_global_rect().grow(2)
	var buttons: Array = []
	for button in m.find_children("*","Button",true,false):
		if not button.is_visible_in_tree(): continue
		var visible_rect := _visible_rect(button)
		if visible_rect.get_area() <= 0: continue
		buttons.append(button)
		if not bounds.encloses(visible_rect):
			print("OUTSIDE ",label," ",button.text," ",button.get_global_rect()," / ",bounds)
			failures += 1
	for a in range(buttons.size()):
		for b in range(a+1,buttons.size()):
			if _visible_rect(buttons[a]).intersection(_visible_rect(buttons[b])).get_area() > 4:
				print("OVERLAP ",label," ",buttons[a].text," / ",buttons[b].text)
				failures += 1
	if not output.is_empty() and DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(output + "/" + label + "-hub-130.png")
	print("LAYOUT ",label)
func enlarge_fonts(node: Node) -> void:
	if node is Label or node is BaseButton or node is LineEdit:
		var original: int = node.get_meta("qa_font",node.get_theme_font_size("font_size"))
		node.set_meta("qa_font",original)
		node.add_theme_font_size_override("font_size",roundi(original*1.3))
	for child in node.get_children(): enlarge_fonts(child)

func _visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var parent := control.get_parent()
	while parent:
		if parent is Control and parent.clip_contents:
			rect = rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return rect
