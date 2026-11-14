extends Node

const MISSION_PATH := "res://stations/free_fall/mission.tscn"

func _ready() -> void:
	call_deferred("_capture_mission")

func _capture_mission() -> void:
	var window := get_tree().root
	window.size = Vector2i(1600, 900)
	var mission: Control = load(MISSION_PATH).instantiate()
	window.add_child(mission)
	await get_tree().process_frame
	mission.call("_on_skip")
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	window.get_texture().get_image().save_png("res://docs/review/issue15_freefall_ready.png")
	var stage: Control = mission.call("_stage")
	stage.call("release", [&"steel", &"foam"])
	await get_tree().create_timer(2.15).timeout
	await RenderingServer.frame_post_draw
	window.get_texture().get_image().save_png("res://docs/review/issue15_freefall_running.png")
	get_tree().quit()
