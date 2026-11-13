extends SceneTree
const Photo = preload("res://stations/photoelectric/photo_sim.gd")
var failures := 0

func _near(label: String, got: float, want: float, tolerance: float = 0.002) -> void:
	var ok := absf(got - want) <= tolerance
	print("%s  %s  (beklenen %s, bulunan %s)" % ["ok " if ok else "HATA", label, str(want), str(snappedf(got, 0.0001))])
	if not ok:
		failures += 1

func _init() -> void:
	var cs: float = Photo.METALS[&"cesium"]["phi"]
	_near("sezyum eşik frekansı (×10¹⁴ Hz)", Photo.threshold_frequency(cs) / 1e14, 5.0)
	_near("5·10¹⁴ Hz: K_max", Photo.k_max(5.0e14, cs), 0.0)
	_near("9·10¹⁴ Hz: K_max (eV)", Photo.k_max(9.0e14, cs), 1.656)
	_near("K_max = 1,656 eV için frekans (×10¹⁴)", Photo.frequency_for_kmax(cs, 1.656) / 1e14, 9.0)
	_near("eşik altı, şiddet 1: akım", Photo.photocurrent(4.3e14, 1.0, cs), 0.0)
	_near("bozuk cihaz, eşik altı, şiddet 1: akım", Photo.faulty_current(4.3e14, 1.0, cs), 8.0)
	_near("eşik üstü şiddet iki katı: akım iki katı", Photo.photocurrent(9e14, 1.0, cs) / Photo.photocurrent(9e14, 0.5, cs), 2.0)
	_near("şiddet K_max'ı değiştirmez", Photo.k_max(9e14, cs), Photo.k_max(9e14, cs))
	_near("çinko eşik frekansı (×10¹⁵)", Photo.threshold_frequency(4.30) / 1e15, 1.0386, 0.001)
	_near("9·10¹⁴ Hz dalga boyu (nm)", Photo.wavelength_nm(9e14), 333.3, 0.1)
	# K_max–f doğrusunun eğimi h'dir
	var slope: float = (Photo.k_max(1.2e15, cs) - Photo.k_max(8.0e14, cs)) / (1.2e15 - 8.0e14)
	_near("K_max–f eğimi = h (×10⁻¹⁵ eV·s)", slope * 1e15, 4.14, 0.001)
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
