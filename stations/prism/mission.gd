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

@onready var add_layer_btn: Button = %AddLayerBtn
@onready var answer_row: HBoxContainer = %AnswerRow
@onready var answer_input: LineEdit = %AnswerInput
@onready var submit_btn: Button = %SubmitBtn

var phase: StringName = &"intro"
var intro_time: float = 0.0


func _ready() -> void:
	skip_btn.pressed.connect(_skip_intro)
	add_layer_btn.pressed.connect(_on_add_layer_pressed)
	submit_btn.pressed.connect(_on_submit_pressed)
	answer_input.text_submitted.connect(func(_t): _on_submit_pressed())
	
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
	add_layer_btn.hide()
	answer_row.hide()
	
	headline.text = "ARIZA: Kasa Hacmi Hatalı!"
	body.text = "Depo kasası eksik ve orantısız yüklendiği için kargo platformunda dengesizlik ve kayma oluştu. Prizmanın tam hacmi hesaplanmalı."
	formula.text = "Prizma Hacmi = Taban Alanı · Yükseklik"
	feedback.text = "Kasayı onarmak için 'Açılışı Geç' düğmesine bas veya bekle."


func _skip_intro() -> void:
	phase = &"base_calc"
	fault_overlay.hide()
	skip_btn.hide()
	
	answer_row.show()
	answer_input.text = ""
	answer_input.grab_focus()
	
	headline.text = "1. Adım: Taban Katmanını Hesapla"
	body.text = "Kasanın tabanında boyu 4 birim, eni 3 birim küp bulunuyor. Taban katmanında (1. katta) toplam kaç birim küp vardır?"
	formula.text = "Taban Alanı = En · Boy = 4 · 3 = ?"
	feedback.text = "1. kattaki birim küp sayısını girin."


func _on_submit_pressed() -> void:
	var val_text := answer_input.text.strip_edges()
	var val := int(val_text)
	
	if phase == &"base_calc":
		if val == 12:
			feedback.set("theme_override_colors/font_color", COLOR_CYAN)
			feedback.text = "Doğru! Taban katmanında 4 x 3 = 12 birim küp yer alır."
			_step_total_volume()
		else:
			feedback.set("theme_override_colors/font_color", COLOR_DANGER)
			feedback.text = "Tekrar dene. Taban: 4 sütun x 3 sıra = 12 küp."
	elif phase == &"total_calc":
		if val == 36:
			feedback.set("theme_override_colors/font_color", COLOR_CYAN)
			feedback.text = "Harika! Toplam hacim = 12 x 3 = 36 birim küptür."
			answer_row.hide()
			_step_fill_crate()
		else:
			feedback.set("theme_override_colors/font_color", COLOR_DANGER)
			feedback.text = "Tekrar dene. Formül: 12 (taban) x 3 (yükseklik) = 36."


func _step_total_volume() -> void:
	phase = &"total_calc"
	answer_input.text = ""
	answer_input.grab_focus()
	
	headline.text = "2. Adım: Toplam Hacmi Hesapla"
	body.text = "Kasa toplam 3 kat yüksekliğindedir. Her katta 12 birim küp olduğuna göre, bu prizmanın alabileceği toplam küp sayısı (hacim) kaçtır?"
	formula.text = "Hacim (V) = Taban Alanı · Yükseklik = 12 · 3 = ?"
	feedback.text = "Toplam birim küp sayısını girin."


func _step_fill_crate() -> void:
	phase = &"pack"
	add_layer_btn.show()
	add_layer_btn.text = "Katman Ekle (2. Katı Yükle)"
	
	headline.text = "3. Adım: Kasayı Doldur & Kilitle"
	body.text = "Hesaplanan birim küpleri katmanlar halinde kasaya yerleştirerek depoyu tam kapasiteye ulaştır."
	formula.text = "V = a · b · c = 4 · 3 · 3 = 36 birim³"


func _on_add_layer_pressed() -> void:
	if stage.visible_layers < 3:
		stage.visible_layers += 1
		stage.queue_redraw()
		if stage.visible_layers == 2:
			add_layer_btn.text = "Katman Ekle (3. Katı Yükle)"
			feedback.text = "2. kat yerleştirildi (24 küp)."
		elif stage.visible_layers == 3:
			add_layer_btn.disabled = true
			add_layer_btn.text = "Kasa Tamamen Doldu"
			feedback.set("theme_override_colors/font_color", COLOR_CYAN)
			feedback.text = "MÜKEMMEL! 36 birim küp tam hizalandı. Prizma Deposu onarıldı."
			headline.text = "GÖREV TAMAMLANDI"
			completed.emit()
