extends "res://scripts/mission.gd"

const ThreeBodyModelScript := preload("res://stations/yks/three_body_model.gd")

@onready var plot: Control = %Plot
@onready var status: Label = %Status
@onready var delta_slider: HSlider = %DeltaSlider
@onready var delta_value: Label = %DeltaValue
@onready var compare_button: Button = %Compare
@onready var action_button: Button = %Release

var baseline_paths: Array[PackedVector2Array] = []
var changed_paths: Array[PackedVector2Array] = []
var _has_baseline := false
var _has_changed := false

func _ready() -> void:
	delta_slider.value_changed.connect(_on_delta_changed)
	%RunBaseline.pressed.connect(_run_baseline)
	%RunChanged.pressed.connect(_run_changed)
	compare_button.pressed.connect(_compare)
	action_button.pressed.connect(_release_control)
	action_button.disabled = true
	_on_delta_changed(delta_slider.value)

func _on_delta_changed(value: float) -> void:
	delta_value.text = "Δv  %0.3f" % value

func _run_baseline() -> void:
	baseline_paths = ThreeBodyModelScript.simulate(0.0)
	_has_baseline = true
	plot.set_paths(baseline_paths, changed_paths)
	status.text = "Başlangıç koşulları kaydedildi."
	compare_button.disabled = not _has_changed

func _run_changed() -> void:
	changed_paths = ThreeBodyModelScript.simulate(delta_slider.value)
	_has_changed = true
	plot.set_paths(baseline_paths, changed_paths)
	status.text = "İlk hız bileşenine küçük bir fark eklendi."
	compare_button.disabled = not _has_baseline

func _compare() -> void:
	if not _has_baseline or not _has_changed:
		return
	var difference := baseline_paths[0][-1].distance_to(changed_paths[0][-1])
	status.text = "Son konum farkı  %0.2f birim  ·  ikinci iz kehribar" % difference
	action_button.disabled = false

func _release_control() -> void:
	if action_button.disabled:
		return
	status.text = "Ölçüm yasaları sabit. Merkezi karar yetkisi serbest bırakıldı."
	completed.emit()
	action_button.disabled = true
