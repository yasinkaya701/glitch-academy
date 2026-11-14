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

@onready var dip_btn: Button = %DipBtn
@onready var neutralize_btn: Button = %NeutralizeBtn
@onready var choice_row: HBoxContainer = %ChoiceRow
@onready var acid_btn: Button = %AcidBtn
@onready var base_btn: Button = %BaseBtn

var phase: StringName = &"intro"
var intro_time: float = 0.0


func _ready() -> void:
	skip_btn.pressed.connect(_skip_intro)
	dip_btn.pressed.connect(_on_dip_pressed)
	acid_btn.pressed.connect(_on_choice_selected.bind("asit"))
	base_btn.pressed.connect(_on_choice_selected.bind("baz"))
	neutralize_btn.pressed.connect(_on_neutralize_pressed)
	
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
	dip_btn.hide()
	choice_row.hide()
	neutralize_btn.hide()
	
	headline.text = "ARIZA: Asit Korozyon Alarmı!"
	body.text = "Kimyasal reaktör hattındaki çözeltinin pH dengesi bozuldu. Aşırı asidik akış borularda aşınma ve delinme tehlikesi yaratıyor."
	formula.text = "pH < 7 (Asidik)  ·  pH = 7 (Nötr)  ·  pH > 7 (Bazik)"
	feedback.text = "Açılışı geçmek için düğmeye bas veya bekle."


func _skip_intro() -> void:
	phase = &"dip"
	fault_overlay.hide()
	skip_btn.hide()
	dip_btn.show()
	choice_row.hide()
	neutralize_btn.hide()
	
	headline.text = "1. Adım: İndikatör Testi"
	body.text = "Bilinmeyen numuneye mavi turnusol kağıdını daldırarak renk değişimini ve pH probunu incele."
	formula.text = "Mavi Turnusol + ?  =>  Kırmızı / Mavi"
	feedback.text = "'Turnusol Kağıdını Daldır' düğmesine bas."


func _on_dip_pressed() -> void:
	dip_btn.disabled = true
	stage.litmus_inserted = true
	stage.queue_redraw()
	
	feedback.set("theme_override_colors/font_color", COLOR_AMBER)
	feedback.text = "Mavi turnusol kağıdı çözeltiye değdiğinde kırmızıya dönüştü! pH probu 2.5 gösteriyor."
	
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(_step_identify)


func _step_identify() -> void:
	phase = &"identify"
	dip_btn.hide()
	choice_row.show()
	
	headline.text = "2. Adım: Madde Türünü Belirle"
	body.text = "Mavi turnusolu kırmızıya çeviren ve pH değeri 7'den küçük (pH = 2.5) olan bu çözelti nedir?"
	formula.text = "pH = 2.5  ·  Kırmızı Renk  =>  Asit mi Baz mı?"


func _on_choice_selected(choice: String) -> void:
	if choice == "asit":
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "Doğru! pH < 7 ve turnusolü kırmızı yapan maddeler ASİT'tir."
		choice_row.hide()
		_step_neutralize()
	else:
		feedback.set("theme_override_colors/font_color", COLOR_DANGER)
		feedback.text = "Hatalı! Bazlar turnusolu maviye çevirir ve pH > 7'dir. Tekrar düşün."


func _step_neutralize() -> void:
	phase = &"neutralize"
	neutralize_btn.show()
	neutralize_btn.disabled = false
	
	headline.text = "3. Adım: Nötrleştirme Reaksiyonu"
	body.text = "Asidik çözeltiyi nötrlemek (pH = 7.0 hedefi) ve boru hattını kurtarmak için büretten kontrollü baz damlat."
	formula.text = "Asit + Baz  =>  Tuz + Su (Nötrleşme: pH -> 7.0)"


func _on_neutralize_pressed() -> void:
	neutralize_btn.disabled = true
	feedback.set("theme_override_colors/font_color", COLOR_AMBER)
	feedback.text = "Baz damlatılıyor... pH dengeleniyor..."
	
	var tween := create_tween()
	tween.tween_property(stage, "current_ph", 7.0, 1.8)
	tween.tween_callback(func():
		stage.is_neutralized = true
		stage.queue_redraw()
		feedback.set("theme_override_colors/font_color", COLOR_CYAN)
		feedback.text = "MÜKEMMEL! pH = 7.0 tam nötr seviyeye ulaştı. Korozyon durduruldu, laboratuvar onarıldı."
		headline.text = "GÖREV TAMAMLANDI"
		completed.emit()
	)
