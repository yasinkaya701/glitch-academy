extends SceneTree

var output := "/tmp/white-ui-review"
var failures := 0

func _initialize() -> void:
	call_deferred("run_review")

func run_review() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	var center = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	await process_frame
	var intro = center.get_node_or_null("Intro")
	if intro:
		intro.set_process(false)
		intro.elapsed = 7.4
		intro._update_frame()
		await capture("intro")
		intro._finish()
	await capture("main")
	check_buttons(center, "main")
	for definition in center.CATALOG:
		if definition.scene == null: continue
		center.selected_mission = definition
		center._launch_selected_mission()
		await create_timer(0.15).timeout
		await capture(String(definition.id))
		check_buttons(center, String(definition.id))
		center._return_to_hub()
		await process_frame
	center.queue_free()
	await process_frame
	for kind in ["waves", "photoelectric", "yks/play/tyt_math", "yks/three_suns"]:
		var mission = load(("res://stations/%s.tscn" % kind) if "/" in kind else ("res://stations/%s/mission.tscn" % kind)).instantiate()
		root.add_child(mission)
		await create_timer(0.15).timeout
		await capture(kind.replace("/", "-"))
		check_buttons(mission, kind)
		mission.queue_free()
		await process_frame
	print("WHITE UI REVIEW FAILURES: ", failures)
	quit(failures)

func capture(label: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(output + "/" + label + ".png")
	print("REVIEW ", label)

func check_buttons(scene: Node, label: String) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(root.size)).grow(2)
	var buttons: Array[Control] = []
	for button in scene.find_children("*", "Button", true, false):
		if not button.is_visible_in_tree(): continue
		var scroll := false
		var parent: Node = button.get_parent()
		while parent:
			if parent is ScrollContainer: scroll = true
			parent = parent.get_parent()
		if scroll: continue
		buttons.append(button)
		if not bounds.encloses(button.get_global_rect()):
			print("OUTSIDE ", label, " / ", button.text, " ", button.get_global_rect())
			failures += 1
	for a in range(buttons.size()):
		for b in range(a + 1, buttons.size()):
			if buttons[a].get_global_rect().intersection(buttons[b].get_global_rect()).get_area() > 4:
				print("OVERLAP ", label, " / ", buttons[a].text, " / ", buttons[b].text)
				failures += 1
