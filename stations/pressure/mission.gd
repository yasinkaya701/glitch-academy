extends "res://scripts/mission.gd"

const COLOR_CYAN := Color("#6fe3c1")
const COLOR_AMBER := Color("#f2a65a")
const COLOR_DANGER := Color("#e5645a")

@onready var stage: Control = %Stage
@onready var fault_overlay: TextureRect = %FaultOverlay
@onready var skip_btn: Button = %SkipBtn

@onready var headline: Label = %Headline
@onready var body: Label = %Body
@onready var formula: Label = %Formula
@onready var feedback: Label = %Feedback

@onready var depth_row: VBoxContainer = %DepthRow
@onready var depth_slider: HSlider = %DepthSlider
@onready var depth_label: Label = %DepthLabel

@onready var answer_row: HBoxContainer = %AnswerRow
@onready var answer_input: LineEdit = %AnswerInput
@onready var submit_btn: Button = %SubmitBtn

@onready var unlock_btn: Button = %UnlockBtn

var phase: StringName = &"intro"
var intro_time: float = 0.0


func _ready() -> void:
	skip_btn.pressed.connect(_skip_intro)
	depth_slider.value_changed.connect(_on_depth_slider_changed)
	submit_btn.pressed.connect(_on_submit_pressed)
	answer_input.text_submitted.connect(func(_t): _on_submit_pressed())
	unlock_btn.pressed.connect(_on_unlock_pressed)
	
	_show_intro()


func _process(delta: float) -> void:
	if phase == &"intro":
		intro_time += delta
		if intro_time > 4.0:
			_skip_intro()


func _show_intro() -> void:
	phase = &"intro"
	fault_overlay.show()
	skip_btn.show()
	depth_row.hide()
	answer_row.hide()
	unlock_btn.hide()
	
	headline.text = "ARIZA: Sıvı Basınç Manifoldu Kilitli!"
	body.text = "Hidrolik boru hattındaki basınç seviyesi yanlış ayarlandığı için güvenlik vanası kilitlendi. U-borusundaki sıvı farkını gözlemleyerek hedef basınca ulaş."
	formula.text = "P_sıvı = h · d · g (Derinlik · Yoğunluk · Yerçekimi)"
	feedback.text = "Açılışı geçmek için düğmeye bas veya bekle."


func _skip_intro() -> void:
	phase = &"calc"
	fault_overlay.hide()
	skip_btn.hide()
	
	answer_row.show()
	depth_row.hide()
	unlock_btn.hide()
	answer_input.text = ""
	answer_input.grab_focus()
	
	headline.text = "1. Adım: Hedef Derinliği Hesapla"
	body.text = "Su dolu tankta (d = 1000 kg/m³, g = 10 m/s²), vananın açılması için gereken hedef basınç P = 2000 Pa'dır. Huni kaç cm derinliğe daldırılmalıdır?"
	formula.text = "2000 = (h / 100) · 1000 · 10   =>   h = ?"
	feedback.text = "Gereken derinliği santimetre (cm) cinsinden girin."


func _on_submit_pressed() -> void:
	var val_text := answer_input.text.strip_edges()
	var val := int(val_text)
	
	# 2000 = h_m * 1000 * 10 => h_m = 0.2 m = 20 cm
	if val == 20:
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "Doğru! 2000 Pa basınç için h = 20 cm derinlik gerekir."
		answer_row.hide()
		_step_adjust_depth()
	else:
		feedback.set("theme_override_colors/font_color", COLOR_DANGER)
		feedback.text = "Hatalı hesaplama. 2000 = h_m x 10000 => h_m = 0.2 m = 20 cm."


func _step_adjust_depth() -> void:
	phase = &"adjust"
	depth_row.show()
	depth_slider.value = stage.depth_cm
	depth_label.text = "Mevcut Derinlik: %.0f cm" % stage.depth_cm
	
	headline.text = "2. Adım: Huniyi Hedef Derinliğe İndir"
	body.text = "Kaydırıcıyı kullanarak huniyi 20 cm derinliğe ayarla ve U-borusu manometresindeki Δh sütun farkının P = 2000 Pa'ya denk gelmesini sağla."
	formula.text = "Hedef: h = 20 cm  =>  P = 2000 Pa"


func _on_depth_slider_changed(value: float) -> void:
	stage.depth_cm = value
	depth_label.text = "Mevcut Derinlik: %.0f cm (P = %.0f Pa)" % [value, stage.get_pressure_pa()]
	stage.queue_redraw()
	
	if absf(value - 20.0) < 1.0:
		if not unlock_btn.visible:
			unlock_btn.show()
			unlock_btn.disabled = false
			feedback.set("theme_override_colors/font_color", COLOR_CYAN)
			feedback.text = "Hedef basınca (2000 Pa) ulaşıldı! Vanayı açmak için düğmeye basın."
	else:
		unlock_btn.hide()
		feedback.set("theme_override_colors/font_color", COLOR_AMBER)
		feedback.text = "Huniyi 20 cm seviyesine hizalayın."


func _on_unlock_pressed() -> void:
	unlock_btn.disabled = true
	stage.valve_unlocked = true
	stage.queue_redraw()
	
	feedback.set("theme_override_colors/font_color", COLOR_CYAN)
	feedback.text = "KLİK! Hidrolik vana başarıyla açıldı. Basınç İstasyonu onarıldı."
	headline.text = "GÖREV TAMAMLANDI"
	completed.emit()
