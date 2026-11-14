extends RefCounted
## Kapalı dolaşım modeli: dört kalp odacığı, dört kapak, küçük ve büyük dolaşım. PhysioNetwork üstüne kurulur.
## Oyuncu kapak, damar, septum ve pompa ayarlarına müdahale eder; basınç, debi ve oksijen buradan okunur.
## Kas ve organ görevleri `add_bed()` ile aynı ağa yatak ekler.

const Net = preload("res://scripts/physio/physio_network.gd")

signal beat_finished(stats: Dictionary)

const VC := &"vc"
const RA := &"ra"
const RV := &"rv"
const PA := &"pa"
const PV := &"pv"
const LA := &"la"
const LV := &"lv"
const AO := &"ao"

const TRICUSPID := &"tricuspid"
const PULMONARY := &"pulmonary"
const MITRAL := &"mitral"
const AORTIC := &"aortic"
const LUNGS := &"lungs"
const BODY := &"body"
const CAVAL := &"caval"
const PULM_VEIN := &"pulm_vein"
const VSD := &"vsd"
const ASD := &"asd"

const VALVES: Array[StringName] = [TRICUSPID, PULMONARY, MITRAL, AORTIC]
const VESSELS: Array[StringName] = [CAVAL, LUNGS, PULM_VEIN, BODY]

const REST_RATE := 72.0
const VENOUS_RETURN := 160.0  ## mL, ihtiyaç iki katına çıkınca toplardamarlardan kalbe katılan ek hacim
const REST_VO2 := 20.0        ## doygunluk·mL/s, dinlenik doku oksijen tüketimi (tüm vücut)

var net: Net = Net.new()

## Oyuncunun ayarları
var heart_rate := REST_RATE
var contractility := 1.0      ## 1 = sağlıklı
var systemic_tone := 1.0      ## büyük dolaşım direnç çarpanı
var lung_function := 1.0      ## gaz alışverişi verimi
var demand := 1.0             ## doku oksijen ihtiyacı çarpanı (1 = dinlenik)
var running := true

## Durum
var cycle_time := 0.0          ## s, atım içinde
var beats := 0
var last_beat: Dictionary = {}
var _end_diastolic := 0.0
var _end_systolic := 0.0
var _min_lv := 1e9
var _max_lv := 0.0
var _sbp := 0.0
var _dbp := 999.0
var _o2_sum := 0.0
var _o2_samples := 0

var _bed_ids: Array[StringName] = []


func _init() -> void:
	_build()
	stabilize()


func _build() -> void:
	#              id  hacim  gerilmemiş  E_min  E_max
	net.add_node(VC, 3200.0, 2900.0, 0.0167)
	net.add_node(RA, 20.0, 8.0, 0.15, 0.45)
	net.add_node(RV, 100.0, 10.0, 0.05, 0.70)
	net.add_node(PA, 110.0, 60.0, 0.29)
	net.add_node(PV, 480.0, 380.0, 0.083)
	net.add_node(LA, 25.0, 8.0, 0.20, 0.55)
	net.add_node(LV, 120.0, 5.0, 0.08, 2.6)
	net.add_node(AO, 900.0, 740.0, 0.57)
	net.add_link(CAVAL, VC, RA, 0.008)
	net.add_link(TRICUSPID, RA, RV, 0.005, true)
	net.add_link(PULMONARY, RV, PA, 0.006, true)
	var lungs := net.add_link(LUNGS, PA, PV, 0.085)
	lungs.exchange_to = 0.98
	net.add_link(PULM_VEIN, PV, LA, 0.008)
	net.add_link(MITRAL, LA, LV, 0.005, true)
	net.add_link(AORTIC, LV, AO, 0.0055, true)
	var body := net.add_link(BODY, AO, VC, 1.05)
	body.uptake = REST_VO2
	var vsd := net.add_link(VSD, LV, RV, 0.12)
	vsd.opening = 0.0
	var asd := net.add_link(ASD, LA, RA, 0.12)
	asd.opening = 0.0
	for id in [VC, RA, RV, PV, LA, LV]:
		(net.nodes[id] as Net.Compartment).o2 = 0.65 if id in [VC, RA, RV] else 0.98
	(net.nodes[PA] as Net.Compartment).o2 = 0.65
	(net.nodes[AO] as Net.Compartment).o2 = 0.98


## Başlangıç durumuna oturtmak için gizli bir kaç saniye çalıştırır.
func stabilize(seconds: float = 12.0) -> void:
	var was_running := running
	running = true
	var t := 0.0
	while t < seconds:
		advance(0.01)
		t += 0.01
	net.reset_counters()
	beats = 0
	running = was_running


# --- Müdahaleler ---------------------------------------------------------

## Kapak durumu: {present, reversed, stenosis 0–1, leak 0–1, stuck_open}.
func set_valve(valve: StringName, present: bool = true, reversed: bool = false, stenosis: float = 0.0, leak: float = 0.0, stuck_open: bool = false) -> void:
	var link: Net.Conduit = net.links[valve]
	link.valve = present
	link.reversed = reversed
	link.opening = clampf(1.0 - stenosis, 0.0, 1.0)
	link.leak = leak
	link.stuck_open = stuck_open


func repair_valve(valve: StringName) -> void:
	set_valve(valve)


## Damar kelepçesi: 0 açık, 1 tam kapalı.
func set_clamp(vessel: StringName, amount: float) -> void:
	(net.links[vessel] as Net.Conduit).opening = clampf(1.0 - amount, 0.0, 1.0)


## Septum kusuru: 0 kapalı, 1 geniş delik. VSD karıncıklar, ASD kulakçıklar arasında.
func set_septal_defect(kind: StringName, size: float) -> void:
	(net.links[kind] as Net.Conduit).opening = clampf(size, 0.0, 1.0)


## Kan hacmi ekle (damar içi sıvı) ya da çıkar (kanama). mL.
func add_blood(milliliters: float) -> void:
	(net.nodes[VC] as Net.Compartment).volume += milliliters


func link(id: StringName) -> Net.Conduit:
	return net.links[id]


func node(id: StringName) -> Net.Compartment:
	return net.nodes[id]


## Dışarıdan bir doku yatağı ekle (kas, böbrek...). Aort → yatak → ana toplardamar, büyük dolaşıma paralel.
func add_bed(id: StringName, resistance: float, vo2: float) -> Net.Conduit:
	var bed := net.add_link(id, AO, VC, resistance)
	bed.uptake = vo2
	_bed_ids.append(id)
	return bed


# --- Zaman ---------------------------------------------------------------

func period() -> float:
	return 60.0 / maxf(heart_rate, 20.0)


func advance(delta: float) -> void:
	if not running:
		return
	var remaining := delta
	while remaining > 0.0:
		var dt := minf(remaining, 0.005)
		_apply_activation()
		net.step(dt)
		cycle_time += dt
		_sample()
		if cycle_time >= period():
			cycle_time -= period()
			_finish_beat()
		remaining -= dt


func _apply_activation() -> void:
	var scale := sqrt(period() / (60.0 / REST_RATE))
	var atrial_end := 0.11 * scale
	var vent_start := 0.14 * scale
	var vent_time := 0.32 * scale
	var t := cycle_time
	var atrial := 0.0
	if t < atrial_end:
		atrial = pow(sin(t / atrial_end * PI), 2.0)
	var ventricular := 0.0
	if t >= vent_start and t < vent_start + vent_time:
		ventricular = pow(sin((t - vent_start) / vent_time * PI), 1.6)
	var left: Net.Compartment = net.nodes[LV]
	var right: Net.Compartment = net.nodes[RV]
	left.activation = ventricular
	right.activation = ventricular
	left.e_max = 2.6 * contractility
	right.e_max = 0.70 * (0.5 + 0.5 * contractility)
	(net.nodes[RA] as Net.Compartment).activation = atrial
	(net.nodes[LA] as Net.Compartment).activation = atrial
	# Çalışan vücutta toplardamarlar daralır, kalbe dönen kan artar: atım hacmi hızla birlikte düşmez.
	(net.nodes[VC] as Net.Compartment).unstressed = 2900.0 - VENOUS_RETURN * (demand - 1.0)
	left.e_max *= 1.0 + 0.25 * (demand - 1.0)
	(net.links[BODY] as Net.Conduit).resistance = 1.05 * systemic_tone / demand_vasodilation()
	(net.links[BODY] as Net.Conduit).uptake = REST_VO2 * demand
	(net.links[LUNGS] as Net.Conduit).exchange_k = lung_function


func demand_vasodilation() -> float:
	## Çalışan doku damarını genişletir: ihtiyaç arttıkça direnç düşer (yerel metabolik denetim).
	return 1.0 + 0.55 * (demand - 1.0)


func _sample() -> void:
	var lv: Net.Compartment = net.nodes[LV]
	var ao: Net.Compartment = net.nodes[AO]
	_max_lv = maxf(_max_lv, lv.volume)
	_min_lv = minf(_min_lv, lv.volume)
	_sbp = maxf(_sbp, ao.pressure)
	_dbp = minf(_dbp, ao.pressure)
	_o2_sum += (net.nodes[AO] as Net.Compartment).o2
	_o2_samples += 1


func _finish_beat() -> void:
	var aortic: Net.Conduit = net.links[AORTIC]
	var mitral: Net.Conduit = net.links[MITRAL]
	var stroke := aortic.volume_moved - aortic.volume_back
	var rate := heart_rate
	var cardiac_output := stroke * rate / 1000.0
	var arterial_o2 := _o2_sum / maxf(float(_o2_samples), 1.0)
	var delivery := cardiac_output * 1000.0 / 60.0 * arterial_o2
	var body_demand := REST_VO2 * demand
	last_beat = {
		"stroke_volume": stroke,
		"cardiac_output": cardiac_output,
		"edv": _max_lv,
		"esv": _min_lv,
		"ef": (_max_lv - _min_lv) / maxf(_max_lv, 1.0),
		"sbp": _sbp,
		"dbp": _dbp,
		"map": _dbp + (_sbp - _dbp) / 3.0,
		"o2_arterial": arterial_o2,
		"o2_venous": (net.nodes[VC] as Net.Compartment).o2,
		"delivery": delivery,
		"tissue": clampf(delivery / (body_demand * 2.5), 0.0, 1.0),
		"cvp": (net.nodes[VC] as Net.Compartment).pressure,
		"pap": (net.nodes[PA] as Net.Compartment).pressure,
		"regurgitation": {
			TRICUSPID: _fraction(net.links[TRICUSPID]),
			PULMONARY: _fraction(net.links[PULMONARY]),
			MITRAL: _fraction(mitral),
			AORTIC: _fraction(aortic),
		},
		"shunt_vsd": (net.links[VSD] as Net.Conduit).volume_moved - (net.links[VSD] as Net.Conduit).volume_back,
		"shunt_asd": (net.links[ASD] as Net.Conduit).volume_moved - (net.links[ASD] as Net.Conduit).volume_back,
	}
	net.reset_counters()
	_max_lv = 0.0
	_min_lv = 1e9
	_sbp = 0.0
	_dbp = 999.0
	_o2_sum = 0.0
	_o2_samples = 0
	beats += 1
	beat_finished.emit(last_beat)


func _fraction(link: Net.Conduit) -> float:
	return link.volume_back / maxf(link.volume_moved, 1.0)


# --- Okuma ---------------------------------------------------------------

func pressure(id: StringName) -> float:
	return (net.nodes[id] as Net.Compartment).pressure


func volume(id: StringName) -> float:
	return (net.nodes[id] as Net.Compartment).volume


func oxygen(id: StringName) -> float:
	return (net.nodes[id] as Net.Compartment).o2


func flow(id: StringName) -> float:
	return (net.links[id] as Net.Conduit).flow


## Kapağın anlık durumu: 0 kapalı, 1 tam açık. Çizim için.
func valve_opening(valve: StringName) -> float:
	var link: Net.Conduit = net.links[valve]
	var forward := -link.flow if link.reversed else link.flow
	return clampf(forward / 400.0, 0.0, 1.0)


## Odacık hacminin sağlıklı gevşek ile kasılmış hacim arasındaki konumu: 0 boş, 1 dolu. Çizimde şişme için.
func fullness(id: StringName) -> float:
	var node: Net.Compartment = net.nodes[id]
	var span := {RA: [10.0, 40.0], RV: [40.0, 120.0], LA: [10.0, 45.0], LV: [45.0, 125.0]}
	if not span.has(id):
		return 0.5
	return clampf(inverse_lerp(span[id][0], span[id][1], node.volume), 0.0, 1.0)


## Tanı: son atımdan çıkan bulgular. Her bulgu {kind, valve|vessel, severity 0–1}.
func findings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if last_beat.is_empty():
		return result
	for valve in VALVES:
		var back: float = last_beat["regurgitation"][valve]
		if back > 0.12:
			result.append({"kind": &"regurgitation", "valve": valve, "severity": clampf(back, 0.0, 1.0)})
		var link: Net.Conduit = net.links[valve]
		if link.opening < 0.6 and link.valve:
			result.append({"kind": &"stenosis", "valve": valve, "severity": 1.0 - link.opening})
	for vessel in VESSELS:
		var opening: float = (net.links[vessel] as Net.Conduit).opening
		if opening < 0.6:
			result.append({"kind": &"occlusion", "vessel": vessel, "severity": 1.0 - opening})
	for kind in [VSD, ASD]:
		if absf((net.links[kind] as Net.Conduit).opening) > 0.05:
			result.append({"kind": &"shunt", "vessel": kind, "severity": (net.links[kind] as Net.Conduit).opening})
	return result


## Sistem sağlıklı mı? Görev başarı ölçütü: debi, basınç, oksijen ve yetersizlik.
func is_healthy() -> bool:
	if last_beat.is_empty():
		return false
	if last_beat["tissue"] < 0.97:
		return false
	if last_beat["map"] < 70.0 or last_beat["map"] > 110.0:
		return false
	return findings().is_empty()
