extends RefCounted
## Çarpışma Hattı kuralı. Tek boyut, momentum korunumu. Yönler işaretle (sağ +, sol −). Çizimden bağımsız.
## Kayma: cihaz momentumu yönsüz (büyüklük olarak) topluyor.


## Toplam momentum (işaretli).
static func momentum(m1: float, v1: float, m2: float, v2: float) -> float:
	return m1 * v1 + m2 * v2


## Esnek olmayan (yapışan) çarpışma sonrası ortak hız.
static func stick_speed(m1: float, v1: float, m2: float, v2: float) -> float:
	return momentum(m1, v1, m2, v2) / (m1 + m2)


## Cihazın bozuk sonucu: momentumların büyüklüklerini toplar.
static func faulty_stick_speed(m1: float, v1: float, m2: float, v2: float) -> float:
	return (absf(m1 * v1) + absf(m2 * v2)) / (m1 + m2)


## Tam esnek çarpışma sonrası hızlar.
static func elastic(m1: float, v1: float, m2: float, v2: float) -> Vector2:
	var total := m1 + m2
	var a := ((m1 - m2) * v1 + 2.0 * m2 * v2) / total
	var b := ((m2 - m1) * v2 + 2.0 * m1 * v1) / total
	return Vector2(a, b)


## Çarpışma sonrası ortak hızın sıfır olması için ikinci arabanın hızı (birinci sabit).
static func speed_to_stop(m1: float, v1: float, m2: float) -> float:
	return -m1 * v1 / m2


## Kinetik enerji (J).
static func kinetic(m: float, v: float) -> float:
	return 0.5 * m * v * v
