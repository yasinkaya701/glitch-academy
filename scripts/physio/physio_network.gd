extends RefCounted
## Fizyoloji motoru çekirdeği: toplu parametreli (lumped) sıvı ağı. Çizimden bağımsız, headless test edilir.
## Düğüm = hacim tutan odacık (kalp odacığı, damar yatağı, kas yatağı). Bağ = iki düğüm arası direnç,
## isteğe bağlı kapak (tek yön), darlık, kaçak ve kelepçe. Kalp, damar ve ileride kas aynı çekirdeği kullanır.
## Birimler: mmHg, mL, s. Direnç mmHg·s/mL.

class Compartment:
	var id: StringName
	var volume := 0.0        ## mL
	var unstressed := 0.0    ## mL, basınç oluşturmayan hacim
	var e_min := 0.1         ## mmHg/mL, gevşekken sertlik
	var e_max := 0.1         ## mmHg/mL, tam kasılmada sertlik (pasif düğümde e_min ile aynı)
	var activation := 0.0    ## 0–1, kasılma düzeyi (kalp odacığı, kas yatağı)
	var o2 := 0.2            ## 0–1, mL kan başına oksijen doygunluğu
	var pressure := 0.0
	var is_source := false   ## true ise oksijen bu düğümde akciğer gibi sıfırlanır

	func elastance() -> float:
		return lerpf(e_min, e_max, activation)

	func update_pressure() -> void:
		pressure = elastance() * (volume - unstressed)


class Conduit:
	var id: StringName
	var from: StringName
	var to: StringName
	var resistance := 0.01   ## mmHg·s/mL
	var valve := false       ## true: tek yönlü akış (varsayılan from→to)
	var reversed := false    ## true: valve ters takılı, yalnızca to→from akar
	var opening := 1.0       ## 0–1, açıklık. Darlık ve kelepçe burada düşer
	var leak := 0.0          ## 0–1, kapalıyken geri akış (yetersizlik)
	var stuck_open := false  ## kapak açık takılı
	var flow := 0.0          ## mL/s, from→to pozitif
	var volume_moved := 0.0  ## mL, ölçüm döneminde toplam ileri akış
	var volume_back := 0.0   ## mL, ölçüm döneminde toplam geri akış (yetersizlik)
	var exchange_to := -1.0  ## ≥ 0: geçen kan bu doygunluğa yaklaşır (akciğer)
	var exchange_k := 1.0    ## 0–1, gaz alışverişi verimi
	var uptake := 0.0        ## doygunluk·mL/s, doku oksijen tüketimi (kas, organ yatağı)

	func effective_resistance() -> float:
		return resistance / maxf(opening * opening, 0.0004)


var nodes: Dictionary = {}   ## id → Compartment
var links: Dictionary = {}   ## id → Conduit
var time := 0.0


func add_node(id: StringName, volume: float, unstressed: float, e_min: float, e_max: float = -1.0) -> Compartment:
	var node := Compartment.new()
	node.id = id
	node.volume = volume
	node.unstressed = unstressed
	node.e_min = e_min
	node.e_max = e_max if e_max >= 0.0 else e_min
	node.update_pressure()
	nodes[id] = node
	return node


func add_link(id: StringName, from: StringName, to: StringName, resistance: float, valve: bool = false) -> Conduit:
	var link := Conduit.new()
	link.id = id
	link.from = from
	link.to = to
	link.resistance = resistance
	link.valve = valve
	links[id] = link
	return link


func step(delta: float) -> void:
	## Sabit alt adımlı açık Euler. Kapak dirençleri küçük olduğundan 0,5 ms adım kararlı.
	var remaining := delta
	while remaining > 0.0:
		var dt := minf(remaining, 0.0005)
		_substep(dt)
		remaining -= dt
	time += delta


func _substep(dt: float) -> void:
	for node: Compartment in nodes.values():
		node.update_pressure()
	var delta_volume := {}
	for id in nodes:
		delta_volume[id] = 0.0
	for link: Conduit in links.values():
		var a: Compartment = nodes[link.from]
		var b: Compartment = nodes[link.to]
		var drop := a.pressure - b.pressure
		var flow := 0.0
		var r := link.effective_resistance()
		if link.opening <= 0.001 and not (link.valve and link.leak > 0.0):
			flow = 0.0
		elif link.valve:
			var forward := -drop if link.reversed else drop
			if forward > 0.0 or link.stuck_open:
				flow = drop / r
			elif link.leak > 0.0:
				# Kapalı kapakta kaçak: geri akış, yetersizlik derecesiyle orantılı.
				flow = drop / (8.0 * link.resistance / maxf(link.leak * link.leak, 0.0001) + r)
		else:
			flow = drop / r
		# Boşalan düğümün gerilmemiş hacminin altına inmesin.
		if flow > 0.0:
			flow = minf(flow, maxf(a.volume - a.unstressed * 0.2, 0.0) / dt)
		else:
			flow = maxf(flow, -maxf(b.volume - b.unstressed * 0.2, 0.0) / dt)
		link.flow = flow
		var forward_sign := -1.0 if link.reversed else 1.0
		if flow * forward_sign > 0.0:
			link.volume_moved += absf(flow) * dt
		elif flow != 0.0:
			link.volume_back += absf(flow) * dt
		delta_volume[link.from] -= flow * dt
		delta_volume[link.to] += flow * dt
		_move_oxygen(link, a, b, flow, dt)
	for id in nodes:
		var node: Compartment = nodes[id]
		node.volume += delta_volume[id]
		node.update_pressure()


func _move_oxygen(link: Conduit, a: Compartment, b: Compartment, flow: float, dt: float) -> void:
	## Karışım: akışla taşınan kan, hedef düğümün doygunluğunu hacim oranında değiştirir.
	var moved := absf(flow) * dt
	if moved <= 0.0:
		return
	var source: Compartment = a if flow > 0.0 else b
	var target: Compartment = b if flow > 0.0 else a
	var saturation := source.o2
	if flow > 0.0:
		if link.exchange_to >= 0.0:
			saturation = lerpf(saturation, link.exchange_to, link.exchange_k)
		if link.uptake > 0.0:
			# Doku, kandan sabit hızda oksijen alır: az akışta çıkan kan daha da oksijensiz.
			saturation = maxf(saturation - link.uptake / maxf(flow, 1.0), 0.0)
	var pool := maxf(target.volume, 1.0)
	target.o2 = clampf(target.o2 + (saturation - target.o2) * minf(moved / pool, 1.0), 0.0, 1.0)


func total_volume() -> float:
	var total := 0.0
	for node: Compartment in nodes.values():
		total += node.volume
	return total


func reset_counters() -> void:
	for link: Conduit in links.values():
		link.volume_moved = 0.0
		link.volume_back = 0.0
