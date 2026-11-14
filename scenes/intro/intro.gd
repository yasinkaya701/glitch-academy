extends Control

signal finished
signal alarm_changed(strength: float)

const DURATION := 9.0
const CUE_STARTS := [0.0, 2.2, 4.5, 6.8, DURATION]
const HEADLINES := [
	"MERİDYEN: “Küçük bir sapma.”",
	"Aynı koşullar. Farklı sonuçlar.",
	"Dünya’nın ayarı bozuldu.",
	"Yanlış Dünya",
]
const CAPTIONS := [
	"MERİDYEN, ölçümlerdeki farkları önemsiz saydı.",
	"Aynı anda bırakılan iki yük, sensöre farklı zamanlarda ulaştı.",
	"Bir kaydı değiştirmek, deneyin sonucunu değiştirmez.",
	"İlk düzeneği incele. MERİDYEN’in atladığı kanıtı bul.",
]
const ACCENT_NORMAL := Color("#3b7867")
const ACCENT_ALARM := Color("#b85f56")
const CUE_TOP := -240.0
const CUE_BOTTOM := -74.0

@onready var cue: VBoxContainer = %Cue
@onready var headline: Label = %Headline
@onready var caption: Label = %Caption
@onready var location: Label = %Location
@onready var trace: Label = %Trace
@onready var progress: ProgressBar = %Progress
@onready var skip: Button = %Skip

var elapsed := 0.0
var cue_index := -1
var started := false
var playing := false


func _ready() -> void:
	hide()
	set_process(false)
	set_process_input(false)
	var title_font := FontVariation.new()
	title_font.base_font = UITheme.DISPLAY_FONT
	title_font.variation_opentype = {"weight": 600}
	headline.add_theme_font_override("font", title_font)
	caption.add_theme_font_override("font", UITheme.FONT)
	skip.pressed.connect(_finish)


func start() -> void:
	if started:
		return
	started = true
	playing = true
	elapsed = 0.0
	_update_frame()
	show()
	set_process(true)
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		_finish()
		return
	_update_frame()


func _update_frame() -> void:
	var next_cue := 0
	for index in range(1, HEADLINES.size()):
		if elapsed >= CUE_STARTS[index]:
			next_cue = index
	if next_cue != cue_index:
		cue_index = next_cue
		headline.text = HEADLINES[cue_index]
		caption.text = CAPTIONS[cue_index]
		headline.add_theme_font_size_override("font_size", 54 if cue_index == 3 else 34)
		trace.visible = cue_index == 1
	var cue_start: float = CUE_STARTS[cue_index]
	var cue_end: float = CUE_STARTS[cue_index + 1]
	var fade_in := smoothstep(cue_start, cue_start + 0.55, elapsed)
	var fade_out := 1.0 - smoothstep(cue_end - 0.5, cue_end, elapsed)
	cue.modulate.a = fade_in * fade_out
	var rise := (1.0 - fade_in) * 9.0
	cue.offset_top = CUE_TOP + rise
	cue.offset_bottom = CUE_BOTTOM + rise
	var alarm := smoothstep(2.4, 4.8, elapsed) * (1.0 - smoothstep(5.5, 7.5, elapsed))
	location.add_theme_color_override("font_color", ACCENT_NORMAL.lerp(ACCENT_ALARM, alarm))
	if trace.visible:
		_update_trace(elapsed - cue_start)
	progress.value = elapsed / DURATION
	alarm_changed.emit(alarm)


func _update_trace(cue_elapsed: float) -> void:
	const ARRIVAL_A := 1.6
	const ARRIVAL_B := 2.1
	var time_a := ("%0.1f" % minf(cue_elapsed, ARRIVAL_A)).replace(".", ",")
	var time_b := ("%0.1f" % minf(cue_elapsed, ARRIVAL_B)).replace(".", ",")
	trace.text = "Yük A   %s s\nYük B   %s s" % [time_a, time_b]
	trace.modulate.a = smoothstep(0.0, 0.3, cue_elapsed)
	var alarm := 0.0 if cue_elapsed < ARRIVAL_A else smoothstep(ARRIVAL_A, ARRIVAL_B, cue_elapsed)
	trace.add_theme_color_override("font_color", ACCENT_NORMAL.lerp(ACCENT_ALARM, alarm))


func _finish() -> void:
	if not playing:
		return
	playing = false
	set_process(false)
	set_process_input(false)
	hide()
	alarm_changed.emit(0.0)
	finished.emit()
