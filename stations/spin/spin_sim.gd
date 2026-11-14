extends RefCounted
## Stern–Gerlach kuralı (spin-½). Çizimden bağımsız, headless test edilir.
## Spin dönen bir küre değildir: seçilen eksende ölçülünce iki sonuçtan biri çıkan bir özelliktir (yukarı ya da aşağı).
## Kazanım sınırı: yalnızca birbirine dik iki eksen (Z ve X). Bir eksende süzülmüş atom, aynı eksende yeniden ölçülünce hep aynı
## sonucu verir; dik eksende ölçülünce %50 – %50 verir ve önceki eksen bilgisi silinir. Süzülmemiş demet her eksende %50 – %50.

const AXES: Array[StringName] = [&"z", &"x"]


## Durum: {"axis": &"z"|&"x"|&"" , "sign": +1|-1|0}. Boş eksen = süzülmemiş (kutuplanmamış).
static func unpolarized() -> Dictionary:
	return {"axis": &"", "sign": 0}


## Verilen durumdaki atomu `axis` ekseninde ölçünce "yukarı" gelme olasılığı.
static func up_probability(state: Dictionary, axis: StringName) -> float:
	if state["axis"] == &"":
		return 0.5
	if state["axis"] == axis:
		return 1.0 if state["sign"] > 0 else 0.0
	return 0.5


## Bir süzgeç: `axis` ekseninde ölçer, yalnız `sign` sonucu geçer. Dönüş: {"pass": geçme olasılığı, "state": geçenin yeni durumu}.
static func filter(state: Dictionary, axis: StringName, sign: int) -> Dictionary:
	var p_up := up_probability(state, axis)
	var p := p_up if sign > 0 else 1.0 - p_up
	return {"pass": p, "state": {"axis": axis, "sign": sign}}


## Üç aşamaya kadar süzgeç ve son dedektör. `stages`: her biri {} (yok) ya da {"axis", "sign"}.
## Dönüş: {"reach": demetin dedektöre ulaşan oranı, "up": dedektörde yukarı oranı (ulaşanlar içinde), "down"}.
static func fractions(stages: Array, detector_axis: StringName) -> Dictionary:
	var state := unpolarized()
	var reach := 1.0
	for stage in stages:
		if stage.is_empty():
			continue
		var result := filter(state, stage["axis"], stage["sign"])
		reach *= result["pass"]
		state = result["state"]
	var up := up_probability(state, detector_axis)
	return {"reach": reach, "up": up, "down": 1.0 - up}


## Tek atomun yolu (rastgele örnekleme). Dönüş: {"absorbed_at": -1 | aşama, "result": +1|-1 (dedektör sonucu)}.
static func sample_atom(rng: RandomNumberGenerator, stages: Array, detector_axis: StringName) -> Dictionary:
	var state := unpolarized()
	for index in stages.size():
		var stage: Dictionary = stages[index]
		if stage.is_empty():
			continue
		var p_up := up_probability(state, stage["axis"])
		var outcome := 1 if rng.randf() < p_up else -1
		if outcome != stage["sign"]:
			return {"absorbed_at": index, "result": 0}
		state = {"axis": stage["axis"], "sign": outcome}
	var detector_up := up_probability(state, detector_axis)
	return {"absorbed_at": -1, "result": 1 if rng.randf() < detector_up else -1}


## Klasik (yanlış) beklenti: atomların yönü sürekli dağılımlı, tek yayılmış leke. Dedektörde iki ayrı iz görülmez.
static func classical_spread(rng: RandomNumberGenerator) -> float:
	return rng.randfn(0.0, 0.5)
