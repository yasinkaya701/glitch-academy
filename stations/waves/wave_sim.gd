extends RefCounted
## Dalga girişimi kuralı. İki eş fazlı noktasal kaynak, aynı frekans ve genlik. Çizimden bağımsız, headless test edilir.
## Bir noktadaki bileşke genlik: A = 2·|cos(π·Δ/λ)|, Δ = yol farkı. Δ = n·λ → yapıcı (A = 2), Δ = (n+½)·λ → yıkıcı (A = 0).

const SPEED := 12.0              ## cm/s, havuzdaki dalga hızı
const S1 := Vector2(6.0, 8.0)    ## cm
const S2 := Vector2(6.0, 20.0)
const SENSOR_A := Vector2(17.7134, 10.625)   ## |AS1| = 12, |AS2| = 15  → Δ = 3 cm  (hassas sensör)
const SENSOR_B := Vector2(25.8466, 10.5)     ## |BS1| = 20, |BS2| = 22  → Δ = 2 cm  (veri alıcısı)
const FREQ_MIN := 1.0
const FREQ_MAX := 8.0


static func wavelength(frequency: float) -> float:
	return SPEED / frequency


static func path_difference(point: Vector2) -> float:
	return absf(point.distance_to(S2) - point.distance_to(S1))


## Yol farkı / dalga boyu.
static func path_ratio(point: Vector2, frequency: float) -> float:
	return path_difference(point) / wavelength(frequency)


## Bileşke genlik (0–2). `two_sources` false ise tek kaynağın genliği (1).
static func amplitude(point: Vector2, frequency: float, two_sources: bool = true) -> float:
	if not two_sources:
		return 1.0
	return 2.0 * absf(cos(PI * path_ratio(point, frequency)))


## Cihazın bozuk kuralı: genlikleri yönsüz (mutlak) toplar, her yerde 2.
static func faulty_amplitude(_point: Vector2, _frequency: float) -> float:
	return 2.0
