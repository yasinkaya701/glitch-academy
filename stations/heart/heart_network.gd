extends RefCounted
## Oyuncunun kurduğu düzenin sonucunu hesaplar: kapak yerleşimi ve yönü, dış damar bağlantıları.
## Çizimden bağımsız. Kapak kuralları heart_model.gd'den gelir.

const Model = preload("res://stations/heart/heart_model.gd")

## Dış damar uçları. Çıkış kan bırakır, giriş kan alır.
const OUT_PORTS: Array[StringName] = [&"body_out", &"pa_out", &"lungs_out", &"aorta_out"]
const IN_PORTS: Array[StringName] = [&"svc_in", &"lungs_in", &"pv_in", &"body_in"]
const CORRECT_LINKS := {&"body_out": &"svc_in", &"pa_out": &"lungs_in", &"lungs_out": &"pv_in", &"aorta_out": &"body_in"}


## Bir damarı boş girişe bağlar veya mevcut bağlantısını atomik olarak değiştirir.
## Dolu girişe ikinci kaynak bağlanmasını reddeder; özgün sözlük değiştirilmez.
static func replace_link(links: Dictionary, from_port: StringName, to_port: StringName) -> Dictionary:
	var unchanged := links.duplicate()
	if not OUT_PORTS.has(from_port) or not IN_PORTS.has(to_port):
		return {"ok": false, "links": unchanged, "reason": &"invalid_port"}
	for existing_source in links:
		if existing_source != from_port and links[existing_source] == to_port:
			return {"ok": false, "links": unchanged, "reason": &"occupied", "source": existing_source}
	var updated := links.duplicate()
	updated[from_port] = to_port
	return {"ok": true, "links": updated, "reason": &""}


## Bir kapağın bir evredeki durumu.
## `slots[slot]` = {piece:int, flipped:bool} ya da boş. `defects[slot]` = &"stuck_open" | &"leaky".
## Dönüş: {forward: bool, back: bool}  forward = ileri akışa izin veriyor, back = geri akış var.
static func valve_flow(slot: int, slots: Dictionary, defects: Dictionary, phase: int) -> Dictionary:
	var open_phase := Model.is_open(slot, phase)
	var placed = slots.get(slot)
	if placed == null:
		# Kapak yok: açık evrede ileri akar, kapalı evrede geri de akar.
		return {"forward": open_phase, "back": not open_phase}
	var correct: bool = placed["piece"] == slot
	var flipped: bool = placed["flipped"]
	var defect: StringName = defects.get(slot, &"")
	if not correct:
		# Boyutu uymayan kapak yuvasında sızdırır.
		return {"forward": open_phase, "back": not open_phase}
	if flipped:
		# Ters takılı kapak ileri akışı engeller, geri akışı serbest bırakır.
		return {"forward": false, "back": not open_phase}
	if defect == &"stuck_open":
		return {"forward": open_phase, "back": not open_phase}
	if defect == &"leaky":
		return {"forward": open_phase, "back": phase != Model.Phase.FILLING and not open_phase}
	return {"forward": open_phase, "back": false}


## Kapak sağlığı: bir tam turda ileri akışın ne kadarı geçiyor, geri kaçış var mı. 0–1.
static func valve_health(slot: int, slots: Dictionary, defects: Dictionary) -> float:
	var forward := 0
	var back := 0
	for phase in [Model.Phase.FILLING, Model.Phase.PRESSURE_RISE, Model.Phase.EJECTION, Model.Phase.PRESSURE_FALL]:
		var flow := valve_flow(slot, slots, defects, phase)
		if Model.is_open(slot, phase) and flow["forward"]:
			forward += 1
		if flow["back"]:
			back += 1
	var health := float(forward) / 1.0
	return clampf(health - 0.2 * float(back), 0.0, 1.0)


static func _feeder(links: Dictionary, port: StringName) -> Variant:
	for from_port in links:
		if links[from_port] == port:
			return from_port
	return null


## Bir çıkıştan çıkan kanın oksijen içeriği: 0 oksijensiz, 1 oksijenli, -1 kan yok.
static func _content(links: Dictionary, from_port: StringName, depth: int = 0) -> float:
	if depth > 6:
		return -1.0
	match from_port:
		&"body_out":
			return 0.0
		&"lungs_out":
			# Akciğer, kendisine bağlanan kanı oksijenler.
			var source = _feeder(links, &"lungs_in")
			return 1.0 if source != null and _content(links, source, depth + 1) >= 0.0 else -1.0
		&"pa_out":
			var right_source = _feeder(links, &"svc_in")
			return -1.0 if right_source == null else _content(links, right_source, depth + 1)
		&"aorta_out":
			var left_source = _feeder(links, &"pv_in")
			return -1.0 if left_source == null else _content(links, left_source, depth + 1)
	return -1.0


## Dış bağlantılardan vücuda ulaşan oksijeni hesaplar.
## Dönüş: {body_oxygen: 0–1, arriving: gelen kanın oksijeni (-1 yok), issues, health}
static func evaluate(links: Dictionary, slots: Dictionary, defects: Dictionary) -> Dictionary:
	var issues: Array[String] = []
	var health := {}
	for slot in Model.VALVE_NAMES:
		health[slot] = valve_health(slot, slots, defects)
	var arriving := -1.0
	var body_source = _feeder(links, &"body_in")
	if body_source != null:
		arriving = _content(links, body_source)
	for port in OUT_PORTS:
		if not links.has(port):
			issues.append("%s bağlı değil." % port)
	for port in IN_PORTS:
		if _feeder(links, port) == null:
			issues.append("%s boş." % port)
	var oxygen := 0.0
	if arriving >= 0.0:
		oxygen = arriving * minf(health[Model.Valve.AORTIC], health[Model.Valve.MITRAL])
	return {"body_oxygen": oxygen, "arriving": arriving, "issues": issues, "health": health}


## Düzen tamamen doğru mu (tüm bağlantılar ve kapaklar)?
static func is_correct(links: Dictionary, slots: Dictionary, defects: Dictionary) -> bool:
	for port in CORRECT_LINKS:
		if links.get(port) != CORRECT_LINKS[port]:
			return false
	for slot in Model.VALVE_NAMES:
		if valve_health(slot, slots, defects) < 0.99:
			return false
	return true
