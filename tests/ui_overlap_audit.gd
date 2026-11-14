extends Node
## Her görev sahnesini iki boyutta açar ve görünür yazı, düğme ve panel dikdörtgenlerinin üst üste binmesini raporlar.
## Kullanım: godot --path . tests/ui_overlap_audit.tscn -- <rota> [istasyon,istasyon]   (rota: ayt, tyt, lgs ...)
## Boyutlar: 1280x720 (%100) ve 900x600 (%130). Çıkış kodu = bulunan çakışma sayısı.

const MIN_AREA := 120.0
const SIZES := [Vector2(1280, 720), Vector2(900, 600)]
const SCALES := [1.0, 1.3]

var total := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var route: String = args[0] if args.size() > 0 else "ayt"
	var only: PackedStringArray = (args[1] as String).split(",") if args.size() > 1 else PackedStringArray()
	get_window().size = Vector2i(1280, 720)
	var missions := _missions(route, only)
	if only.has("hub"):
		missions = [{"id": "hub", "scene": load("res://scenes/control_center.tscn")}]
	for mission in missions:
		for index in SIZES.size():
			await _audit(mission, SIZES[index], SCALES[index])
	print("TOPLAM ÇAKIŞMA: %d" % total)
	get_tree().quit(mini(total, 100))


func _missions(route: String, only: PackedStringArray) -> Array:
	var result: Array = []
	var paths: Array[String] = []
	var dir := DirAccess.open("res://stations")
	for name in dir.get_directories():
		paths.append("res://stations/%s/mission.tres" % name)
	paths.append("res://stations/yks/three_suns.tres")
	var definitions := DirAccess.open("res://stations/yks/definitions")
	if definitions != null:
		for file in definitions.get_files():
			if file.ends_with(".tres"):
				paths.append("res://stations/yks/definitions/" + file)
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
		var definition: Resource = load(path)
		if definition == null or definition.get("scene") == null:
			continue
		var id := String(definition.get("id"))
		if only.size() > 0 and not only.has(id):
			continue
		if not (definition.get("routes") as PackedStringArray).has(route):
			continue
		result.append({"id": id, "scene": definition.get("scene")})
	return result


func _audit(mission: Dictionary, size: Vector2, scale: float) -> void:
	var host := Control.new()
	host.theme = get_tree().root.theme
	host.scale = Vector2(scale, scale)
	host.size = size / scale
	host.clip_contents = true
	add_child(host)
	var scene: Control = mission["scene"].instantiate()
	host.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(2.6).timeout
	if mission["id"] == "hub":
		# Açılış sahnesini geç, rota panosunu aç.
		var intro := scene.get_child(scene.get_child_count() - 1)
		if intro.has_signal("finished"):
			intro.emit_signal("finished")
		await get_tree().create_timer(1.2).timeout
	var boxes: Array = []
	_collect(host, host, boxes, size)
	var found: Array[String] = []
	for first in boxes.size():
		for second in range(first + 1, boxes.size()):
			var a: Dictionary = boxes[first]
			var b: Dictionary = boxes[second]
			if _related(a["node"], b["node"]):
				continue
			var overlap: Rect2 = (a["rect"] as Rect2).intersection(b["rect"])
			if overlap.get_area() > MIN_AREA and overlap.size.x > 8.0 and overlap.size.y > 8.0:
				found.append("    %s «%s»  ×  %s «%s»  (%d×%d px)" % [a["kind"], a["text"], b["kind"], b["text"], overlap.size.x, overlap.size.y])
	var label := "%s @ %dx%d" % [mission["id"], size.x, size.y]
	if found.is_empty():
		print("ok   %s  (%d öğe denetlendi)" % [label, boxes.size()])
	else:
		print("ÇAKIŞMA  %s  (%d)" % [label, found.size()])
		for line in found.slice(0, 8):
			print(line)
		total += found.size()
	host.queue_free()
	await get_tree().process_frame


func _collect(node: Node, host: Control, boxes: Array, view: Vector2) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		var kind := ""
		var text := ""
		if control is Label and (control as Label).text.strip_edges() != "":
			kind = "Label"
			text = (control as Label).text
		elif control is Button and (control as Button).text.strip_edges() != "":
			kind = "Button"
			text = (control as Button).text
		elif control is LineEdit:
			kind = "Giriş"
			text = (control as LineEdit).placeholder_text
		if kind != "" and control.modulate.a > 0.2 and control.get_global_rect().size.x > 4.0:
			var rect := _clipped_rect(control, host)
			# Tam ekran arka plan ve ekran dışı öğeler sayılmaz.
			if rect.size.x > 4.0 and rect.size.y > 4.0 and rect.size.x < view.x * 0.92 and rect.intersects(Rect2(Vector2.ZERO, view)):
				boxes.append({"node": control, "rect": rect.intersection(Rect2(Vector2.ZERO, view)), "kind": kind, "text": text.substr(0, 28).replace("\n", " ")})
	for child in node.get_children():
		_collect(child, host, boxes, view)


## Kaydırma alanı ve clip_contents olan atalar dışarıda kalan parçayı gizler; çakışma yalnız görünen kısımdan sayılır.
func _clipped_rect(control: Control, host: Control) -> Rect2:
	var rect := _screen_rect(control, host)
	var parent := control.get_parent()
	while parent != null and parent != host.get_parent():
		if parent is Control and (parent is ScrollContainer or (parent as Control).clip_contents):
			rect = rect.intersection(_screen_rect(parent as Control, host))
		parent = parent.get_parent()
	return rect


func _screen_rect(control: Control, host: Control) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var rect := Rect2(transform.origin, control.size * transform.get_scale())
	return rect


func _related(a: Node, b: Node) -> bool:
	return a.is_ancestor_of(b) or b.is_ancestor_of(a)
