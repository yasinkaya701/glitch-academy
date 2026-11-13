extends "res://scripts/mission.gd"

const COLOR_CYAN := Color("#6fe3c1")
const COLOR_AMBER := Color("#f2a65a")
const COLOR_DANGER := Color("#e5645a")

@onready var stage: Control = %Stage
@onready var fault_overlay: TextureRect = %FaultOverlay
@onready var skip_btn: Button = %SkipBtn

# UI Panels & Controls
@onready var headline: Label = %Headline
@onready var body: Label = %Body
@onready var formula: Label = %Formula
@onready var feedback: Label = %Feedback

@onready var pump_btn: Button = %PumpBtn
@onready var drop_btn: Button = %DropBtn
@onready var answer_row: HBoxContainer = %AnswerRow
@onready var answer_input: LineEdit = %AnswerInput
@onready var submit_btn: Button = %SubmitBtn

var phase: StringName = &"intro"
var intro_time: float = 0.0


func _ready() -> void:
	skip_btn.pressed.connect(_skip_intro)
	pump_btn.pressed.connect(_on_pump_pressed)
	drop_btn.pressed.connect(_on_drop_pressed)
	submit_btn.pressed.connect(_on_submit_pressed)
	answer_input.text_submitted.connect(func(_t): _on_submit_pressed())
	
	_show_intro_phase()


func _process(delta: float) -> void:
	if phase == &"intro":
		intro_time += delta
		if intro_time > 4.0:
			_skip_intro()


func _show_intro_phase() -> void:
	phase = &"intro"
	fault_overlay.show()
	skip_btn.show()
	pump_btn.hide()
	drop_btn.hide()
	answer_row.hide()
	
	headline.text = "ARIZA: Vakum Odası Hava Almış!"
	body.text = "Hava direnci nedeniyle tüy havada süzülürken kurşun bilye hızla düşüyor. Yük sensörleri senkronizasyonunu kaybetti ve düşüş süresi hatalı ölçülüyor."
	formula.text = "Arıza Sebebi: F_hava = k · A · v² (Hava Direnci Farkı)"
	feedback.text = "Deneyi başlatmak için vakum pompasını çalıştırın."


func _skip_intro() -> void:
	phase = &"vacuum"
	fault_overlay.hide()
	skip_btn.hide()
	
	pump_btn.show()
	drop_btn.hide()
	answer_row.hide()
	
	headline.text = "1. Adım: Odayı Boşalt (Vakumla)"
	body.text = "Tüm gaz moleküllerini dışarı atmak için vakum pompasını çalıştır. Havasız ortamda hava direnci sıfırlanır."
	formula.text = "Hedef Basınç: P = 0.0 kPa (İdeal Vakum)"
	feedback.text = "'Vakumu Başlat' düğmesine basarak havayı tahliye edin."


func _on_pump_pressed() -> void:
	pump_btn.disabled = true
	feedback.text = "Vakum pompalanıyor..."
	
	var tween := create_tween()
	tween.tween_property(stage, "pressure_kpa", 0.0, 1.8)
	tween.tween_callback(func():
		pump_btn.hide()
		_step_calculation()
	)


func _step_calculation() -> void:
	phase = &"calc"
	answer_row.show()
	answer_input.text = ""
	answer_input.grab_focus()
	
	headline.text = "2. Adım: Düşüş Süresini Hesapla"
	body.text = "Vakum tüpünün yüksekliği h = 5 m'dir. Yerçekimi ivmesi g = 10 m/s² kabul edildiğinde, serbest bırakılan bir cisim kaç saniyede yere çarpar?"
	formula.text = "h = 1/2 · g · t²   =>   5 = 1/2 · 10 · t²   =>   t = ?"
	feedback.text = "Sonucu saniye cinsinden girin (Örn: 1.0)."


func _on_submit_pressed() -> void:
	var val_text := answer_input.text.strip_edges().replace(",", ".")
	var val := float(val_text)
	
	# t = sqrt(2*5/10) = 1.0 s
	if absf(val - 1.0) < 0.1:
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "Doğru! t = 1.0 saniye. Kütle hesaba katılmaz; her iki cisim de aynı anda düşecektir."
		answer_row.hide()
		_step_verification()
	else:
		feedback.set("theme_override_colors/font_color", COLOR_DANGER)
		feedback.text = "Hatalı hesaplama. Formül: 5 = 5 · t² => t² = 1 => t = 1 saniye."


func _step_verification() -> void:
	phase = &"verify"
	drop_btn.show()
	drop_btn.disabled = false
	
	headline.text = "3. Adım: Eşzamanlı Bırakma & Doğrulama"
	body.text = "Kurşun bilye (1 kg) ve tüy (2 g) aynı anda serbest bırakılacak. Vakum ortamında ikisi de 1.00 saniyede sensör tablasına ulaşmalıdır."
	formula.text = "a_bilye = g = 10 m/s²  =  a_tüy = g = 10 m/s²"


func _on_drop_pressed() -> void:
	drop_btn.disabled = true
	feedback.set("theme_override_colors/font_color", COLOR_AMBER)
	feedback.text = "Düşüş başladı... Sayaç: 1.00 s"
	
	stage.ball_y = 0.0
	stage.feather_y = 0.0
	stage.drop_progress = 0.0
	stage.is_dropping = true
	
	# Wait for drop completion
	var timer := get_tree().create_timer(1.1)
	timer.timeout.connect(func():
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "KUSURSUZ! İki kütle tam 1.00 saniyede sensöre aynı anda çarptı. Düşüş Odası onarıldı."
		headline.text = "GÖREV TAMAMLANDI"
		completed.emit()
	)
