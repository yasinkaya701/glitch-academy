extends Control

signal finished
signal alarm_changed(strength: float)

const DURATION := 13.5
const CUE_STARTS := [0.0, 2.7, 5.4, 8.1, 10.8, DURATION]
const HEADLINES := [
	"MERİDYEN: Gözlemevi asistanı.",
	"Aynı koşullar. Farklı sonuçlar.",
	"İlk kayıtta küçük bir sensör sapması.",
	"Kayıt ile ölçüm ayrışıyor.",
	"Kalibratör: ölç, kayda değil.",
]
const CAPTIONS := [
	"Ben MERİDYEN. Gözlemevinin kalibrasyon asistanıyım.",
	"Aynı anda bırakılan iki yük, sensöre farklı zamanlarda ulaştı.",
	"Cihaz bu farkı geçici bir sensör sapması olarak işaretledi.",
	"Gözlem ile kayıt aynı sonucu vermiyor. Düzeneği yeniden ölçelim.",
	"İlk düzeneği incele; ölçümünü kaydet ve onarımı doğrula.",
]
const GUIDE_LINES := [
	"Merhaba. Ben MERİDYEN; gözlemevinin kalibrasyon asistanıyım.",
	"İki ölçüm aynı koşullarda alındı. Sensörler farklı sonuç kaydetti.",
	"İlk kaydı sensör sapması olarak sınıflandırdım.",
	"Kayıt ile kendi ölçümün uyuşmuyorsa, birlikte tekrar kontrol edelim.",
	"Kalibratör, önce ölçümüne güven. Hazırım.",
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
@onready var guide_portrait: TextureRect = %GuidePortrait
@onready var guide_bubble: PanelContainer = %GuideBubble
@onready var guide_line: Label = %GuideLine

var elapsed := 0.0
var cue_index := -1
var started := false
var playing := false
var _cue_top := CUE_TOP
var _cue_bottom := CUE_BOTTOM
var _guide_top := -340.0
var _guide_bottom := -18.0


func _ready() -> void:
	hide()
	set_process(false)
	set_process_input(false)
	var title_font := FontVariation.new()
	title_font.base_font = UITheme.SERIF_FONT
	title_font.variation_opentype = {"weight": 600}
	headline.add_theme_font_override("font", title_font)
	var speech_font := FontVariation.new()
	speech_font.base_font = UITheme.SERIF_FONT
	speech_font.variation_opentype = {"weight": 500}
	caption.add_theme_font_override("font", UITheme.FONT)
	guide_line.add_theme_font_override("font", speech_font)
	guide_line.add_theme_color_override("font_color", Color("#22332f"))
	skip.pressed.connect(_finish)
	resized.connect(_layout_intro)
	_layout_intro()


func _layout_intro() -> void:
	if not is_node_ready():
		return
	var compact := size.x < 980.0
	var mobile := size.x < 600.0
	if compact:
		cue.anchor_right = 0.72
		cue.offset_left = 28.0
		_cue_top = -236.0 if not mobile else -276.0
		_cue_bottom = -74.0 if not mobile else -242.0
		headline.add_theme_font_size_override("font_size", 27 if mobile else 30)
		caption.add_theme_font_size_override("font_size", 15 if mobile else 17)
		_guide_top = -236.0 if not mobile else -196.0
		_guide_bottom = -18.0
		guide_portrait.offset_left = -218.0 if not mobile else -180.0
		guide_portrait.offset_top = _guide_top
		guide_portrait.offset_right = -18.0
		guide_portrait.offset_bottom = _guide_bottom
		guide_line.add_theme_font_size_override("font_size", 16 if mobile else 18)
		guide_bubble.anchor_left = 0.04 if mobile else 1.0
		guide_bubble.anchor_right = 0.96 if mobile else 1.0
		guide_bubble.offset_left = 0.0 if mobile else -286.0
		guide_bubble.offset_top = 84.0
		guide_bubble.offset_right = 0.0 if mobile else -28.0
		guide_bubble.offset_bottom = 176.0 if mobile else 196.0
		trace.hide()
	else:
		cue.anchor_right = 0.64
		cue.offset_left = 48.0
		_cue_top = CUE_TOP
		_cue_bottom = CUE_BOTTOM
		headline.add_theme_font_size_override("font_size", 34)
		caption.add_theme_font_size_override("font_size", 18)
		_guide_top = -340.0
		_guide_bottom = -18.0
		guide_portrait.offset_left = -350.0
		guide_portrait.offset_top = _guide_top
		guide_portrait.offset_right = -28.0
		guide_portrait.offset_bottom = _guide_bottom
		guide_line.add_theme_font_size_override("font_size", 20)
		guide_bubble.anchor_left = 1.0
		guide_bubble.anchor_right = 1.0
		guide_bubble.offset_left = -398.0
		guide_bubble.offset_top = 100.0
		guide_bubble.offset_right = -32.0
		guide_bubble.offset_bottom = 214.0


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
		headline.add_theme_font_size_override("font_size", 40 if cue_index == 4 else (30 if size.x < 980.0 else 34))
		trace.visible = cue_index == 1 and size.x >= 980.0
		guide_line.text = GUIDE_LINES[cue_index]
	var cue_start: float = CUE_STARTS[cue_index]
	var cue_end: float = CUE_STARTS[cue_index + 1]
	var fade_in := smoothstep(cue_start, cue_start + 0.55, elapsed)
	var fade_out := 1.0 - smoothstep(cue_end - 0.5, cue_end, elapsed)
	cue.modulate.a = fade_in * fade_out
	guide_line.modulate.a = fade_in * fade_out
	guide_portrait.modulate.a = clampf(0.24 + fade_in * 0.76, 0.0, 1.0) * fade_out
	var bob := sin(elapsed * 1.8) * 3.0
	guide_portrait.offset_top = _guide_top + bob
	guide_portrait.offset_bottom = _guide_bottom + bob
	var rise := (1.0 - fade_in) * 9.0
	cue.offset_top = _cue_top + rise
	cue.offset_bottom = _cue_bottom + rise
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
