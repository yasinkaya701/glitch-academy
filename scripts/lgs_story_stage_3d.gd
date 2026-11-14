extends "res://scripts/lgs_stage_3d.gd"
## The lesson state drives physical doors, shipments and support deliveries.

@export var mission_id: StringName = &"turkish"
var lesson_phase := 0
var solved := false
var fault_visible := true
var _hinge: Node3D
var _delivery: Node3D
var _signal: MeshInstance3D
var _state_label: Label
var _item_label: Label
var _opening := 0.0
var _delivery_progress := 0.0


func set_lesson_state(phase: int, repaired: bool, fault := false, _focus := -1, _proof := false) -> void:
	lesson_phase = phase
	solved = repaired
	fault_visible = fault


func _build_model() -> void:
	camera_target = Vector3(0, 1.25, 0)
	view_size = 6.5
	_readout.position = Vector2(22, 20)
	_readout.add_theme_font_size_override("font_size", 16)
	match mission_id:
		&"turkish": _build_exit()
		&"english": _build_dispatch()
		&"religion": _build_support()


func _build_exit() -> void:
	box("CorridorFloor", Vector3(0, 0.02, 0.4), Vector3(4.6, 0.16, 4.0), UITheme.EDGE)
	for x in [-1.35, 1.35]:
		box("Wall", Vector3(x, 1.35, -0.6), Vector3(1.3, 2.7, 0.28), UITheme.PANEL_RAISED)
	for x in [-0.72, 0.72]:
		box("DoorPost", Vector3(x, 1.35, -0.4), Vector3(0.12, 2.7, 0.18), UITheme.INK)
	box("Lintel", Vector3(0, 2.72, -0.4), Vector3(1.55, 0.12, 0.18), UITheme.INK)
	_hinge = Node3D.new()
	_hinge.name = "DoorHinge"
	_hinge.position = Vector3(-0.65, 0.05, -0.36)
	model.add_child(_hinge)
	box("DoorLeaf", Vector3(0.65, 1.3, 0), Vector3(1.3, 2.6, 0.10), UITheme.EDGE_STRONG, _hinge)
	box("PushBar", Vector3(0.65, 1.25, 0.1), Vector3(1.0, 0.08, 0.12), UITheme.INK, _hinge)
	_signal = box("ExitSignal", Vector3(0, 3.0, -0.4), Vector3(1.7, 0.35, 0.16), UITheme.DANGER)
	_state_label = annotate(_signal, "Çıkış kapalı", Vector3(0, 0, 0.15))
	for i in range(4):
		box("WayMark", Vector3(0, 0.12, 0.3 + i * 0.45), Vector3(0.35, 0.02, 0.10), UITheme.ACCENT)


func _build_dispatch() -> void:
	box("DispatchBench", Vector3(0, 0.4, 0), Vector3(4.3, 0.18, 2.1), UITheme.EDGE)
	cylinder("CleanWaterTank", Vector3(-1.2, 1.18, -0.3), 0.55, 1.4, UITheme.EDGE_STRONG)
	cylinder("TankLid", Vector3(-1.2, 1.92, -0.3), 0.59, 0.08, UITheme.INK)
	box("Radio", Vector3(1.1, 0.98, -0.45), Vector3(1.3, 0.8, 0.65), UITheme.PANEL_RAISED)
	_signal = box("RadioDisplay", Vector3(1.1, 1.1, -0.10), Vector3(0.9, 0.3, 0.03), UITheme.DANGER)
	beam("Antenna", Vector3(1.55, 1.4, -0.45), Vector3(1.7, 2.4, -0.45), 0.025, UITheme.INK)
	_state_label = annotate(model, "Telsiz yanıt bekliyor", Vector3(0.5, 2.6, 0))
	_delivery = Node3D.new()
	_delivery.name = "Shipment"
	model.add_child(_delivery)
	box("SupplyCrate", Vector3.ZERO, Vector3(0.7, 0.52, 0.65), UITheme.WARM, _delivery)
	box("PackingBand", Vector3(0, 0.01, 0), Vector3(0.09, 0.56, 0.68), UITheme.INK, _delivery)
	_item_label = annotate(_delivery, "", Vector3(0, 0.6, 0))
	box("ReceivingBay", Vector3(-0.6, 0.52, 0.5), Vector3(1.0, 0.03, 1.0), UITheme.ACCENT.darkened(0.5))


func _build_support() -> void:
	box("SupportTable", Vector3(0, 0.65, 0), Vector3(4.3, 0.18, 2.3), UITheme.EDGE_STRONG)
	for x in [-1.7, 1.7]:
		for z in [-0.8, 0.8]:
			box("Leg", Vector3(x, 0.25, z), Vector3(0.12, 0.7, 0.12), UITheme.MUTED)
	var needs := box("NeedsRecord", Vector3(-1.4, 1.5, -0.6), Vector3(1.0, 1.3, 0.12), UITheme.PANEL_RAISED)
	annotate(needs, "İhtiyaç kaydı", Vector3(0, 0.85, 0))
	for i in range(3):
		box("RecordLine", Vector3(-1.4, 1.75 - i * 0.25, -0.52), Vector3(0.7, 0.04, 0.02), UITheme.INK)
	_signal = box("ReceivingTray", Vector3(-0.9, 0.78, 0.35), Vector3(1.3, 0.08, 0.9), UITheme.DANGER)
	_delivery = Node3D.new()
	_delivery.name = "SupportDelivery"
	model.add_child(_delivery)
	box("MealPackage", Vector3.ZERO, Vector3(0.7, 0.38, 0.65), UITheme.WARM, _delivery)
	box("PackageBand", Vector3(0, 0.01, 0), Vector3(0.08, 0.42, 0.68), UITheme.INK, _delivery)
	_item_label = annotate(_delivery, "Destek paketi", Vector3(0, 0.45, 0))
	_state_label = annotate(model, "İhtiyaç karşılanmadı", Vector3(0.6, 2.4, 0))
	box("WrongAddress", Vector3(1.35, 0.78, 0.75), Vector3(1.1, 0.04, 0.9), UITheme.DANGER.darkened(0.5))


func _sync_model(delta: float) -> void:
	var repaired := solved and not fault_visible
	var target := 1.0 if repaired else 0.0
	_opening = move_toward(_opening, target, delta * 1.5)
	_delivery_progress = move_toward(_delivery_progress, target, delta * 1.2)
	(_signal.material_override as StandardMaterial3D).albedo_color = UITheme.ACCENT if repaired else UITheme.DANGER
	match mission_id:
		&"turkish":
			_hinge.rotation.y = -_opening * PI * 0.52
			_state_label.text = "Çıkış açık" if repaired else "Çıkış kapalı"
			_readout.text = "Güvenlik kapısı"
		&"english":
			_delivery.position = Vector3(1.35, 0.85, 0.8).lerp(Vector3(-0.6, 0.85, 0.5), _delivery_progress)
			_item_label.text = "A map" if lesson_phase >= 4 else "Clean water"
			_state_label.text = "Doğru sevkiyat" if repaired else "Yanlış sevkiyat"
			_readout.text = "Yardım istasyonu"
		&"religion":
			_delivery.position = Vector3(1.35, 1.0, 0.75).lerp(Vector3(-0.9, 1.0, 0.35), _delivery_progress)
			_item_label.text = "Sıcak yemek" if lesson_phase >= 4 else "Destek paketi"
			_state_label.text = "Destek ulaştı" if repaired else "İhtiyaç karşılanmadı"
			_readout.text = "Dayanışma masası"
