extends SceneTree

const SCENE := "res://stations/projectile/mission.tscn"
const OUT := "res://docs/review/"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene := load(SCENE) as PackedScene
	var mission := scene.instantiate()
	root.add_child(mission)
	await process_frame
	await process_frame
	mission.capture_finished_state(20.0)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png(OUT + "projectile_mission_hit.png")
	mission.capture_finished_state(14.0)
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png(OUT + "projectile_mission_miss.png")
	print("Saved running-scene hit and miss captures.")
	quit()
