extends RefCounted
## Kalbin basitleştirilmiş basınç modeli. Görselden bağımsız; görev kuralları ve akış animasyonu aynı veriyi kullanır.
## Kaynak: HEART.md. Kapaklar basınç farkıyla açılır, tek yönlü akışı tutar.

enum Phase { FILLING, PRESSURE_RISE, EJECTION, PRESSURE_FALL }
enum Valve { TRICUSPID, PULMONARY, MITRAL, AORTIC }

const PHASE_NAMES := {
	Phase.FILLING: "Dolum",
	Phase.PRESSURE_RISE: "Basınç yükselişi",
	Phase.EJECTION: "Atım",
	Phase.PRESSURE_FALL: "Basınç düşüşü",
}
const VALVE_NAMES := {
	Valve.TRICUSPID: "Triküspit kapak",
	Valve.PULMONARY: "Pulmoner kapak",
	Valve.MITRAL: "Mitral kapak",
	Valve.AORTIC: "Aort kapağı",
}
## Her kapağın doğru konumu: yukarı akış odası → aşağı akış odası/damarı.
const SLOT_OF := {
	Valve.TRICUSPID: [&"right_atrium", &"right_ventricle"],
	Valve.PULMONARY: [&"right_ventricle", &"pulmonary_artery"],
	Valve.MITRAL: [&"left_atrium", &"left_ventricle"],
	Valve.AORTIC: [&"left_ventricle", &"aorta"],
}
const SLOT_NAMES := {
	&"right_atrium": "sağ kulakçık", &"right_ventricle": "sağ karıncık",
	&"left_atrium": "sol kulakçık", &"left_ventricle": "sol karıncık",
	&"pulmonary_artery": "akciğer atardamarı", &"aorta": "aort",
}
## Kanın izlediği tam yol ve her bölümdeki oksijen düzeyi (true = oksijence zengin).
const CIRCUIT: Array[Array] = [
	[&"vena_cava", false],
	[&"right_atrium", false],
	[&"right_ventricle", false],
	[&"pulmonary_artery", false],
	[&"lungs", true],
	[&"pulmonary_veins", true],
	[&"left_atrium", true],
	[&"left_ventricle", true],
	[&"aorta", true],
	[&"body", false],
]

## Kapağın bir fazda açık olup olmadığı, doğru yerleştirilmişse. Yön değil basınç belirler.
static func is_open(valve: Valve, phase: Phase) -> bool:
	match valve:
		Valve.TRICUSPID, Valve.MITRAL:
			return phase == Phase.FILLING
		_:
			return phase == Phase.EJECTION


## `placement`: kapak → yuva (SLOT_OF'taki bir yuva çifti ya da null). `defects`: kapak → &"stuck_open" | &"leaky".
## Dönen değer: faz için sorun listesi. Boşsa akış doğru ve tek yönlü.
static func problems(placement: Dictionary, defects: Dictionary, phase: Phase) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for valve in SLOT_OF:
		var slot = placement.get(valve)
		if slot == null:
			found.append({"valve": valve, "kind": &"missing", "phase": phase})
			continue
		if slot != SLOT_OF[valve]:
			found.append({"valve": valve, "kind": &"wrong_slot", "phase": phase})
			continue
		var defect: StringName = defects.get(valve, &"")
		var should_be_open := is_open(valve, phase)
		if defect == &"stuck_open" and not should_be_open:
			found.append({"valve": valve, "kind": &"backflow", "phase": phase})
		elif defect == &"leaky" and not should_be_open and phase in [Phase.EJECTION, Phase.PRESSURE_RISE, Phase.PRESSURE_FALL]:
			found.append({"valve": valve, "kind": &"backflow", "phase": phase})
	return found


static func all_problems(placement: Dictionary, defects: Dictionary) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for phase in [Phase.FILLING, Phase.PRESSURE_RISE, Phase.EJECTION, Phase.PRESSURE_FALL]:
		found.append_array(problems(placement, defects, phase))
	return found


## Geri kaçışın yönünü ve evresini açıklayan Türkçe cümle.
static func describe(problem: Dictionary) -> String:
	var valve: Valve = problem["valve"]
	var name: String = VALVE_NAMES[valve]
	match problem["kind"]:
		&"missing":
			return "%s yok. Kan tek yönlü tutulamıyor." % name
		&"wrong_slot":
			return "%s yanlış yerde. Akışı doğru odayı ayıran yuvaya taşı." % name
		&"backflow":
			var from: String = SLOT_NAMES[SLOT_OF[valve][1]]
			var to: String = SLOT_NAMES[SLOT_OF[valve][0]]
			return "%s: %s sırasında kan %s → %s geri kaçıyor." % [name, PHASE_NAMES[problem["phase"]].to_lower(), from, to]
	return ""


## Tam tur: 10 bölüm sırayla bağlı mı ve kapaklar doğru mu? Oksijen iletimi buna bağlı.
static func circuit_complete(placement: Dictionary, defects: Dictionary, connections: Array) -> bool:
	if not all_problems(placement, defects).is_empty():
		return false
	if connections.size() != CIRCUIT.size() - 1:
		return false
	for i in connections.size():
		if connections[i] != [CIRCUIT[i][0], CIRCUIT[i + 1][0]]:
			return false
	return true


static func oxygenated(segment: StringName) -> bool:
	for entry in CIRCUIT:
		if entry[0] == segment:
			return entry[1]
	return false
