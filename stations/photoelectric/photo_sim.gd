extends RefCounted
## Fotoelektrik olay kuralı. Çizimden bağımsız, headless test edilir.
## Foton enerjisi E = h·f. Elektron sökülürse K_max = h·f − φ (eV). Işık şiddeti burada foton sayısıdır (foton/s):
## şiddet akımı (elektron sayısını) belirler, K_max yalnızca frekansa ve metale bağlıdır.

const H_EV := 4.14e-15          ## eV·s (Planck sabiti)
const C := 3.0e8                ## m/s

## Metaller: iş fonksiyonu φ (eV). Eşik frekansı φ/h.
const METALS := {
	&"cesium": {"name": "Sezyum", "phi": 2.07},
	&"sodium": {"name": "Sodyum", "phi": 2.30},
	&"zinc": {"name": "Çinko", "phi": 4.30},
	&"copper": {"name": "Bakır", "phi": 4.70},
}


static func photon_energy(frequency: float) -> float:
	return H_EV * frequency


static func threshold_frequency(phi: float) -> float:
	return phi / H_EV


static func k_max(frequency: float, phi: float) -> float:
	return maxf(0.0, photon_energy(frequency) - phi)


## Fotoakım (µA): eşik üstünde şiddetle orantılı, eşik altında sıfır.
static func photocurrent(frequency: float, intensity: float, phi: float) -> float:
	if photon_energy(frequency) <= phi:
		return 0.0
	return 8.0 * clampf(intensity, 0.0, 1.0)


## Durdurma potansiyeli (V): e·V₀ = K_max.
static func stopping_potential(frequency: float, phi: float) -> float:
	return k_max(frequency, phi)


## Verilen K_max için gereken frekans.
static func frequency_for_kmax(phi: float, k: float) -> float:
	return (phi + k) / H_EV


static func wavelength_nm(frequency: float) -> float:
	return C / frequency * 1e9


## Cihazın bozuk kuralı: eşik altında da şiddet yeter sanır.
static func faulty_current(_frequency: float, intensity: float, _phi: float) -> float:
	return 8.0 * clampf(intensity, 0.0, 1.0)


## Görünür ışık rengi (yaklaşık) dalga boyuna göre; UV ve IR için belirgin tonlar.
static func light_color(frequency: float) -> Color:
	var nm := wavelength_nm(frequency)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	if nm < 380.0:
		return Color(0.62, 0.45, 1.0)
	elif nm < 440.0:
		r = -(nm - 440.0) / 60.0
		b = 1.0
	elif nm < 490.0:
		g = (nm - 440.0) / 50.0
		b = 1.0
	elif nm < 510.0:
		g = 1.0
		b = -(nm - 510.0) / 20.0
	elif nm < 580.0:
		r = (nm - 510.0) / 70.0
		g = 1.0
	elif nm < 645.0:
		r = 1.0
		g = -(nm - 645.0) / 65.0
	elif nm <= 780.0:
		r = 1.0
	else:
		return Color(0.75, 0.25, 0.2)
	return Color(r, g, b)
