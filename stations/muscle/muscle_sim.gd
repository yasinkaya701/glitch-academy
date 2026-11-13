extends RefCounted
## İzole kas (miyograf) deneyi benzetimi. Çizimden bağımsız.
## Kaynak fikir: kayan iplik modeli. Kuvvet, aktin–miyozin örtüşmesine (sarkomer uzunluğu), kalsiyuma
## (troponin–tropomiyozin) ve ATP'ye (çapraz köprü ayrılması) bağlıdır.

const THICK_LENGTH := 1.6      ## µm, A bandı sabit
const THIN_LENGTH := 1.0       ## µm, her Z çizgisinden uzanan aktin
const MIN_LENGTH := 1.3
const MAX_LENGTH := 3.6
const OPTIMUM_LOW := 2.0
const OPTIMUM_HIGH := 2.25
const MAX_FORCE := 8.0         ## N, en uygun uzunlukta kenetlenmiş tetanoz
const CA_TAU := 0.045          ## s, kalsiyum geçici yükselişinin sönümü
const FORCE_TAU := 0.085       ## s, kuvvetin aktivasyonu izleme gecikmesi
const ATP_COST := 0.035        ## 1 s tam aktivasyonda azalan ATP oranı

## Girdiler (oyuncu ayarlar)
var rest_length := 2.2         ## µm, dinlenim sarkomer uzunluğu (mikrometre)
var frequency := 1.0           ## Hz
var stimulating := false
var atp := 1.0                 ## 0–1
var ca_blocked := false

## Durum
var calcium := 0.0             ## 0–1
var activation := 0.0
var force := 0.0               ## N
var sarcomere := 2.2           ## µm
var rigor := false
var time := 0.0
var _pulse_clock := 0.0
var _rigor_length := 0.0


## Uzunluk–kuvvet eğrisi (0–1).
static func length_factor(length: float) -> float:
	if length <= 1.27 or length >= 3.65:
		return 0.0
	if length < 1.67:
		return 0.84 * (length - 1.27) / 0.40
	if length < OPTIMUM_LOW:
		return 0.84 + 0.16 * (length - 1.67) / (OPTIMUM_LOW - 1.67)
	if length <= OPTIMUM_HIGH:
		return 1.0
	return 1.0 - (length - OPTIMUM_HIGH) / (3.65 - OPTIMUM_HIGH)


## Örtüşme (aktin–miyozin), görsellik ve açıklama için: A bandı sabit, H bölgesi ve I bandı değişir.
static func bands(length: float) -> Dictionary:
	var a_band := THICK_LENGTH
	var h_zone := maxf(length - 2.0 * THIN_LENGTH, 0.0)
	var i_band := maxf(length - THICK_LENGTH, 0.0)
	return {"A": a_band, "H": h_zone, "I": i_band}


func reset() -> void:
	calcium = 0.0
	activation = 0.0
	force = 0.0
	rigor = false
	time = 0.0
	_pulse_clock = 0.0
	sarcomere = rest_length


func pulse() -> void:
	## Tek uyarı: sarkoplazmik retikulumdan kalsiyum salınır.
	if ca_blocked:
		return
	calcium = minf(calcium + 0.55, 1.0)


func step(delta: float) -> void:
	time += delta
	if stimulating:
		_pulse_clock += delta
		var period := 1.0 / maxf(frequency, 0.1)
		while _pulse_clock >= period:
			_pulse_clock -= period
			pulse()
	calcium = maxf(calcium - delta * calcium / CA_TAU * (1.0 if atp > 0.02 else 0.0), 0.0)
	# Hill tipi aktivasyon
	var target_activation := pow(calcium, 2.0) / (pow(calcium, 2.0) + pow(0.30, 2.0)) if not ca_blocked else 0.0
	if atp <= 0.02:
		# ATP yok: çapraz köprüler ayrılamaz. Sertleşme (rigor): uzunluk ve kuvvet donar.
		if not rigor:
			rigor = true
			_rigor_length = sarcomere
		sarcomere = _rigor_length
		force = maxf(force, 0.0)
		return
	rigor = false
	activation = move_toward(activation, target_activation, delta / FORCE_TAU)
	# İzometrik düzenek: kuvvet dinlenim uzunluğuna göre, görsel kısalma küçüktür.
	var factor := length_factor(rest_length)
	var target_force := MAX_FORCE * factor * activation
	force = move_toward(force, target_force, delta * MAX_FORCE / FORCE_TAU * 2.0)
	var target_length := clampf(rest_length - 0.3 * activation, MIN_LENGTH, MAX_LENGTH)
	sarcomere = move_toward(sarcomere, target_length, delta * 4.0)
	# ATP harcanır
	atp = maxf(atp - delta * ATP_COST * activation, 0.0)


## Kalıcı (kenetlenmiş) tetanoz kuvveti: tanı ve kabul ölçütleri için.
static func tetanic_force(length: float) -> float:
	return MAX_FORCE * length_factor(length)
