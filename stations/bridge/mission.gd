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

@onready var answer_row: HBoxContainer = %AnswerRow
@onready var answer_input: LineEdit = %AnswerInput
@onready var submit_btn: Button = %SubmitBtn

@onready var close_bridge_btn: Button = %CloseBridgeBtn

var phase: StringName = &"intro"
var intro_time: float = 0.0


func _ready() -> void:
	skip_btn.pressed.connect(_skip_intro)
	submit_btn.pressed.connect(_on_submit_pressed)
	answer_input.text_submitted.connect(func(_t): _on_submit_pressed())
	close_bridge_btn.pressed.connect(_on_close_bridge_pressed)
	
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
	answer_row.hide()
	close_bridge_btn.hide()
	
	headline.text = "ARIZA: Köprü Çapraz Kirişi Koptu!"
	body.text = "Kafes kiriş sistemindeki taşıyıcı diyagonal eleman koptuğu için köprü kanadı açık kaldı ve ulaşım hattı kilitlendi."
	formula.text = "Pisagor Bağıntısı: a² + b² = c²"
	feedback.text = "Açılışı geçmek için düğmeye bas veya bekle."


func _skip_intro() -> void:
	phase = &"calc"
	fault_overlay.hide()
	skip_btn.hide()
	
	answer_row.show()
	close_bridge_btn.hide()
	answer_input.text = ""
	answer_input.grab_focus()
	
	headline.text = "1. Adım: Kiriş Uzunluğunu Hesapla"
	body.text = "Kule dikmesi a = 6 m, taban kirişi b = 8 m uzunluğundadır. Kirişlerin dik açı oluşturduğu bu üçgende eksik olan çelik çapraz kiriş (c) kaç metre olmalıdır?"
	formula.text = "6² + 8² = c²   =>   36 + 64 = 100   =>   c = ?"
	feedback.text = "Kiriş uzunluğunu metre cinsinden girin (Örn: 10)."


func _on_submit_pressed() -> void:
	var val_text := answer_input.text.strip_edges()
	var val := int(val_text)
	
	if val == 10:
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "Doğru! c = 10 m (6-8-10 özel dik üçgeni)."
		answer_row.hide()
		_step_install_beam()
	else:
		feedback.set("theme_override_colors/font_color", COLOR_DANGER)
		feedback.text = "Hatalı hesaplama. c² = 36 + 64 = 100 => c = 10 m."


func _step_install_beam() -> void:
	phase = &"install"
	close_bridge_btn.show()
	close_bridge_btn.disabled = false
	
	headline.text = "2. Adım: Kirişi Monte Et & Köprüyü Kapat"
	body.text = "Üretilen 10 metrelik çelik kirişi yerine yerleştirerek köprü kanadını emniyetle kilitle."
	formula.text = "c = 10 m Hazır  ·  Statik Emniyet: %100"


func _on_close_bridge_pressed() -> void:
	close_bridge_btn.disabled = true
	stage.hypotenuse_installed = true
	stage.queue_redraw()
	
	feedback.set("theme_override_colors/font_color", COLOR_AMBER)
	feedback.text = "Kiriş kilitlendi... Köprü kanatları indiriliyor..."
	
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		stage.bridge_closed = true
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "KLİK! Köprü güvenle kapandı ve trafik hattı açıldı. Köprü Atölyesi onarıldı."
		headline.text = "GÖREV TAMAMLANDI"
		completed.emit()
	)
