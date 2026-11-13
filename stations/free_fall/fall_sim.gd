extends RefCounted
## Düşüş Odası fiziği. Çizimden bağımsız, headless test edilir.
## Hareket denklemi (aşağı yön pozitif): m·dv/dt = m·g − ½·ρ·Cd·A·v². Odanın basıncı havanın yoğunluğunu belirler.
## Vakumda ρ → 0, iki cisim de h = ½·g·t² ile aynı sürede iner.

const G := 10.0                  ## m/s², oyunun ivmesi (MEB sorularındaki g = 10 m/s²).
const AIR_DENSITY := 1.2         ## kg/m³, 101,3 kPa'da
const ATMOSPHERE := 101.325      ## kPa

## Cisimler: kütle (kg), yarıçap (m), sürüklenme katsayısı (küre).
const BODIES := {
	&"steel": {"name": "Çelik küre", "mass": 33.0, "radius": 0.10, "cd": 0.47},
	&"foam": {"name": "Sünger top", "mass": 0.05, "radius": 0.15, "cd": 0.47},
	&"capsule": {"name": "Kargo kapsülü", "mass": 0.6, "radius": 0.12, "cd": 0.47},
}


class State:
	var depth := 0.0     ## m, bırakma noktasından aşağı kat edilen yol
	var speed := 0.0     ## m/s, aşağı
	var time := 0.0


static func density(pressure_kpa: float) -> float:
	return AIR_DENSITY * clampf(pressure_kpa, 0.0, 200.0) / ATMOSPHERE


static func drag_coefficient(body: StringName) -> float:
	## k = ½·Cd·A (ρ ile çarpılınca kuvvet/hız²)
	var data: Dictionary = BODIES[body]
	return 0.5 * data["cd"] * PI * data["radius"] * data["radius"]


static func acceleration(body: StringName, speed: float, pressure_kpa: float, g: float = G) -> float:
	var mass: float = BODIES[body]["mass"]
	return g - density(pressure_kpa) * drag_coefficient(body) * speed * speed / mass


## Bir adım (RK4).
static func step(state: State, body: StringName, pressure_kpa: float, dt: float, g: float = G) -> void:
	var v0 := state.speed
	var k1v := acceleration(body, v0, pressure_kpa, g)
	var k2v := acceleration(body, v0 + 0.5 * dt * k1v, pressure_kpa, g)
	var k3v := acceleration(body, v0 + 0.5 * dt * k2v, pressure_kpa, g)
	var k4v := acceleration(body, v0 + dt * k3v, pressure_kpa, g)
	var v1 := v0 + dt / 6.0 * (k1v + 2.0 * k2v + 2.0 * k3v + k4v)
	state.depth += 0.5 * (v0 + v1) * dt
	state.speed = v1
	state.time += dt


## `height` metreden ilk hızsız bırakılan cismin yere varış süresi (s) ve çarpma hızı.
static func fall(body: StringName, height: float, pressure_kpa: float, g: float = G) -> Dictionary:
	var state := State.new()
	var dt := 0.001
	while state.depth < height:
		var before_depth := state.depth
		var before_time := state.time
		step(state, body, pressure_kpa, dt, g)
		if state.depth >= height:
			# Son adımı doğrusal ara değerle düzelt.
			var share := (height - before_depth) / maxf(state.depth - before_depth, 1e-9)
			return {"time": before_time + share * dt, "speed": state.speed}
		if state.time > 120.0:
			break
	return {"time": state.time, "speed": state.speed}


## Vakumda kapalı çözüm: t = √(2h/g). `g` Misafirlerin bozduğu yerel çekim ivmesidir.
## Çekim dengeleyici ayarı → g: g = 2 + 0,16·ayar (ayar 0–100). Sağlıklı Dünya: ayar 50, g = 10.
static func gravity_for_dial(dial: float) -> float:
	return 2.0 + 0.16 * dial
static func vacuum_time(height: float, g: float = G) -> float:
	return sqrt(2.0 * height / g)
