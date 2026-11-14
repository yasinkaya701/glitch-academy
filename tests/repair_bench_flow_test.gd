extends SceneTree
## Tests real inputs, interrupted playback, finite attempts and independent applications.
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(label: String, condition: bool) -> void:
	print("%s %s" % ["ok" if condition else "HATA", label])
	if not condition: failures += 1
func finish_run(m: Control) -> void:
	m._elapsed = 2.8
	m._process(0.0)
func _run() -> void:
	for kind in ["newton", "projectile", "collision"]:
		var m = load("res://stations/%s/mission.tscn" % kind).instantiate()
		root.add_child(m)
		await process_frame
		var done := [0]
		m.completed.connect(func() -> void: done[0] += 1)
		m._on_action()
		check(kind + " cannot skip running crisis through action", m.phase == m.Phase.CRISIS)
		m._on_skip()
		m._on_action()
		check(kind + " no evidence before completed measurement", m.records.is_empty())
		m._rewind_run()
		check(kind + " rewind keeps the same measurement", m.records.is_empty() and m.busy)
		finish_run(m)
		m._on_action()
		finish_run(m)
		m._on_action()
		check(kind + " both measured records required", m.phase == m.Phase.DIAGNOSIS)
		m._attach_evidence(0)
		m._attach_evidence(0)
		check(kind + " duplicate evidence cannot unlock plate", m.phase == m.Phase.DIAGNOSIS)
		m._attach_evidence(1)
		await process_frame
		m.entry.text = "wrong"
		m._on_action()
		check(kind + " wrong rule cannot repair", not m.repaired and not m.busy)
		m.entry.text = {"newton":"a=F/m", "projectile":"t=sqrt(2*h/g)", "collision":"p=m1*v1+m2*v2"}[kind]
		m._on_action()
		finish_run(m)
		check(kind + " repair shown before rescue", m.repaired and done[0] == 0)
		m._on_action()
		await process_frame
		var starting_tries: int = m.tries_left
		m.entry.text = ""
		m._on_action()
		check(kind + " empty input costs no attempt", m.tries_left == starting_tries and not m.busy)
		m.entry.text = "1"
		m._on_action()
		m._on_action()
		finish_run(m)
		check(kind + " wrong run consumes exactly one attempt", m.tries_left == 2 and done[0] == 0)
		for index in 2:
			m.entry.text = str(m._correct_value(m._recovery_case(index)))
			m._on_action()
			finish_run(m)
			if index == 0:
				check(kind + " first recovery does not finish mission", done[0] == 0)
				m._on_action()
				await process_frame
		check(kind + " both independent recoveries required", m.phase == m.Phase.SEAL and done[0] == 0)
		m._on_action()
		m._on_action()
		check(kind + " completion emitted once", done[0] == 1)
		m.queue_free()
		await process_frame
	# Exhaustion must invalidate the evidence and the repaired state.
	var m = load("res://stations/collision/mission.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.busy = false
	m.repaired = true
	m._enter_recovery()
	for attempt in 3:
		m.entry.text = "1"
		m._on_action()
		finish_run(m)
		await process_frame
	check("no silent refill", m.tries_left == 0 and m.hud.action.text == "Krize sar")
	m._on_action()
	check("exhaustion restarts crisis and clears repair", m.phase == m.Phase.CRISIS and not m.repaired and m.records.is_empty())
	m.queue_free()
	print("BAŞARISIZ: %d" % failures)
	quit(failures)
