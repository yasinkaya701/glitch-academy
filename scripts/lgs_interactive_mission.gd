extends "res://scripts/mission.gd"
## Data-led interaction shell for the LGS campaign's six short, tactile missions.

@export var mission_id: StringName = &"seasons"

const PALETTE := {
	"seasons": Color("#65d7c7"), "bridge": Color("#f3b75b"),
	"turkish": Color("#70a9ff"), "history": Color("#d5a4ff"),
	"english": Color("#75c8fa"), "religion": Color("#f2cb77")
}
const PACK := {
	"seasons": {
		"title":"MEVSİM GÖZLEMEVİ", "subject":"FEN BİLİMLERİ  ·  F.8.1.1",
		"brief":"Güneş ışınları yanlış açıyla geliyor. Önce modeli kur, sonra ışığın hangi yarımküreye dik geldiğini doğrula.",
		"steps":[
			{"label":"MODELİ KUR  /  Dünya'nın eksen eğikliği", "options":["0° · dik eksen", "23,5° · eğik eksen", "45° · aşırı eğim"], "answer":1, "feedback":"Eksen eğikliği yaklaşık 23,5°'dir; mevsimlerin temel nedeni budur."},
			{"label":"IŞIĞI İZLE  /  Kuzey Yarımküre Güneş'e dönük", "options":["Kuzey'de yaz", "Kuzey'de kış", "Her yerde aynı mevsim"], "answer":0, "feedback":"Kuzey Yarımküre Güneş'e dönükken ışınlar daha dik gelir; yaz yaşanır."},
			{"label":"GÖZLEMİ DOĞRULA  /  21 Haziran", "options":["Kuzey'de en uzun gündüz", "Güney'de en uzun gündüz", "Gece ve gündüz eşit"], "answer":0, "feedback":"21 Haziran'da Kuzey Yarımküre en uzun gündüzü yaşar. Gözlemevi kalibre edildi."}]},
	"bridge": {
		"title":"KÖPRÜ ATÖLYESİ", "subject":"MATEMATİK  ·  M.8.3.1.5",
		"brief":"Köprünün iki dik taşıyıcısı 9 ve 12 birim. Kare alanlarıyla ilişkiyi keşfet, ardından doğru kirişi yerleştir.",
		"steps":[
			{"label":"ALANLARI KARŞILAŞTIR  /  dik kenarlar 9 ve 12", "options":["9² + 12² = 225", "9² + 12² = 144", "9 + 12 = 21"], "answer":0, "feedback":"81 + 144 = 225. Dik üçgende hipotenüs üzerindeki karenin alanı, diğer ikisinin toplamıdır."},
			{"label":"KİRİŞİ HESAPLA  /  c² = 225", "options":["c = 14", "c = 15", "c = 16"], "answer":1, "feedback":"√225 = 15 birim. 14 birim kısa kalır; 15 birim açıklığı kapatır."},
			{"label":"KÖPRÜYÜ KAPAT  /  kirişi yuvaya sürükle", "options":["14 birim kirişi yerleştir", "15 birim kirişi yerleştir", "16 birim kirişi yerleştir"], "answer":1, "feedback":"Kiriş oturdu. Yerleşimin ulaşım hattı yeniden açık."}]},
	"turkish": {
		"title":"BOZUK TALİMAT", "subject":"TÜRKÇE  ·  CÜMLEDE ANLAM",
		"brief":"Güvenlik komutunda bir olumsuzluk eki ve bağlam kaymış. Anlamı koruyan, uygulanabilir talimatı kur.",
		"steps":[
			{"label":"ANLAMI ONAR  /  “Kapıyı açık bırakmayın.”", "options":["Kapıyı kapalı tutun.", "Kapıyı açık tutun.", "Kapıyı açmadan bırakın."], "answer":0, "feedback":"“Bırakmayın” olumsuzluğu, kapının açık kalmaması gerektiğini bildirir."},
			{"label":"BAĞLAMI OKU  /  Alarm çalarsa çıkış yolunu koru", "options":["Çıkış yolunu kapatın.", "Çıkış yolunu açık tutun.", "Alarmı duymazdan gelin."], "answer":1, "feedback":"Bağlam, güvenli tahliye için çıkışın açık tutulmasını gerektiriyor."},
			{"label":"KOMUTU DOĞRULA  /  güvenlik kaydı", "options":["Yetkisiz girişte kapıyı kilitleyin.", "Yetkisiz girişte kapıyı kilitlemeyin.", "Kapı yetkisiz girişi kilitlesin."], "answer":0, "feedback":"Açık ve bağlama uygun komut doğrulandı. Metindeki koordinatlar çözüldü."}]},
	"history": {
		"title":"KAYIP KRONOLOJİ", "subject":"T.C. İNKILAP TARİHİ  ·  MİLLÎ MÜCADELE",
		"brief":"Arşiv kayıtları karışmış. Tarihli belgeleri sırala ve kararların birbirine nasıl bağlandığını göster.",
		"steps":[
			{"label":"İLK BELGE  /  Millî Mücadele'nin başlangıç adımı", "options":["Amasya Genelgesi · 22 Haziran 1919", "Sivas Kongresi · 4 Eylül 1919", "TBMM açılışı · 23 Nisan 1920"], "answer":0, "feedback":"Amasya Genelgesi, Millî Mücadele'nin gerekçe ve yöntemini duyurdu."},
			{"label":"BİRLEŞME  /  bütün millî cemiyetler", "options":["Erzurum Kongresi", "Sivas Kongresi", "TBMM'nin açılması"], "answer":1, "feedback":"Sivas Kongresi'nde millî cemiyetler Anadolu ve Rumeli Müdafaa-i Hukuk Cemiyeti adıyla birleştirildi."},
			{"label":"YENİ MECLİS  /  ulusal irade", "options":["19 Mayıs 1919", "23 Nisan 1920", "29 Ekim 1923"], "answer":1, "feedback":"TBMM 23 Nisan 1920'de açıldı. Belgeler kronolojik olarak doğrulandı."}]},
	"english": {
		"title":"SON MESAJ", "subject":"İNGİLİZCE  ·  COMMUNICATION",
		"brief":"Yardım istasyonundan üç kısa mesaj geldi. İsteği anla, uygun yanıtı seç ve iletişim dizisini tamamla.",
		"steps":[
			{"label":"MESSAGE 01  /  “We need clean water.”", "options":["They need clean water.", "They need a new map.", "They are closing the station."], "answer":0, "feedback":"“We need” bir ihtiyacı bildirir; ekip temiz su istiyor."},
			{"label":"MESSAGE 02  /  “The bridge is not safe.”", "options":["Köprü güvenli.", "Köprü güvenli değil.", "Köprü yeniden açıldı."], "answer":1, "feedback":"“Not safe” olumsuzluk bildirir: köprü güvenli değil."},
			{"label":"REPLY  /  Give a clear instruction", "options":["Please wait at the station.", "The station is a blue color.", "I am not a bridge."], "answer":0, "feedback":"Kısa ve anlaşılır yönerge gönderildi. Yardım hattı bağlandı."}]},
	"religion": {
		"title":"DAYANIŞMA ARŞİVİ", "subject":"DİN KÜLTÜRÜ  ·  YARDIMLAŞMA",
		"brief":"Toplumsal yardım kayıtlarını güvenilir kavram ve örneklerle eşleştir. Her seçimde kaynağı ve etkisini incele.",
		"steps":[
			{"label":"KAVRAMI EŞLEŞTİR  /  ihtiyaç sahibine karşılıksız destek", "options":["Yardımlaşma", "İsraf", "Gösteriş"], "answer":0, "feedback":"Yardımlaşma, ihtiyaçların karşılanmasında dayanışmayı ve sorumluluğu destekler."},
			{"label":"ÖRNEĞİ SEÇ  /  ortak iyilik için sürekli katkı", "options":["Bir çeşmenin bakımını birlikte üstlenmek", "Kullanılabilir gıdayı çöpe atmak", "Yardımı yalnızca duyurmak"], "answer":0, "feedback":"Kalıcı yarar sağlayan ortak katkı, dayanışmanın somut bir örneğidir."},
			{"label":"KAYDI DOĞRULA  /  yardımın niteliği", "options":["İhtiyacı gözeten, incitmeden yapılan destek", "Karşılık bekleyerek yapılan yardım", "Başkalarını küçümseyerek verilen destek"], "answer":0, "feedback":"Kayıtlar; samimiyet, ihtiyaç ve insan onurunu gözeten örneklerle onarıldı."}]}
}

var stage := 0
var locked := false
var shell: VBoxContainer
var feedback: Label
var action_label: Label
var action_buttons: VBoxContainer
var progress_label: Label
var diorama


func _ready() -> void:
	if mission_id == &"":
		mission_id = &"seasons"
	_build_ui()
	_show_stage()


func _build_ui() -> void:
	var data: Dictionary = PACK.get(String(mission_id), PACK["seasons"])
	var accent: Color = PALETTE.get(String(mission_id), PALETTE["seasons"])
	var bg := ColorRect.new()
	bg.color = Color("#081321")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	shell = VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = 36
	shell.offset_top = 26
	shell.offset_right = -36
	shell.offset_bottom = -26
	shell.add_theme_constant_override("separation", 16)
	add_child(shell)
	var header := HBoxContainer.new()
	shell.add_child(header)
	var eyebrow := Label.new()
	eyebrow.text = data.subject
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow.add_theme_color_override("font_color", accent)
	eyebrow.add_theme_font_size_override("font_size", 15)
	header.add_child(eyebrow)
	progress_label = Label.new()
	header.add_child(progress_label)
	var title := Label.new()
	title.text = data.title
	title.add_theme_font_size_override("font_size", 32)
	shell.add_child(title)
	var brief := Label.new()
	brief.text = data.brief
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brief.custom_minimum_size.y = 48
	brief.add_theme_color_override("font_color", Color("#bdcddd"))
	shell.add_child(brief)
	var stage_card := PanelContainer.new()
	stage_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101f31")
	panel_style.border_color = accent.darkened(0.35)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 26
	panel_style.content_margin_top = 24
	panel_style.content_margin_right = 26
	panel_style.content_margin_bottom = 24
	stage_card.add_theme_stylebox_override("panel", panel_style)
	shell.add_child(stage_card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	stage_card.add_child(content)
	var visual_row := HBoxContainer.new()
	visual_row.add_theme_constant_override("separation", 18)
	content.add_child(visual_row)
	diorama = load("res://scenes/lgs_diorama.tscn").instantiate()
	diorama.mission_id = mission_id
	diorama.custom_minimum_size = Vector2(300, 176)
	diorama.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visual_row.add_child(diorama)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_row.add_child(right)
	var step_name := Label.new()
	step_name.text = "AKTİF DENEY"
	step_name.add_theme_color_override("font_color", accent)
	step_name.add_theme_font_size_override("font_size", 12)
	right.add_child(step_name)
	action_label = Label.new()
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.add_theme_font_size_override("font_size", 21)
	right.add_child(action_label)
	action_buttons = VBoxContainer.new()
	action_buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_buttons.add_theme_constant_override("separation", 9)
	content.add_child(action_buttons)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 32
	feedback.add_theme_color_override("font_color", accent)
	content.add_child(feedback)
	var note := Label.new()
	note.text = "Kayıtlar, yürürlükteki müfredat kavramlarıyla karşılaştırılır. Kurmaca arıza yalnızca oyundaki verileri etkiler."
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color("#7d92a8"))
	shell.add_child(note)


func _show_stage() -> void:
	var data: Dictionary = PACK.get(String(mission_id), PACK["seasons"])
	var steps: Array = data.steps
	progress_label.text = "KAYIT %02d / %02d" % [stage + 1, steps.size()]
	action_label.text = steps[stage].label
	feedback.text = "Bir işlem seç. Sonucu gözlem alanında göreceksin."
	diorama.set_lesson_state(stage, false)
	locked = false
	for child in action_buttons.get_children(): child.queue_free()
	for i in range(steps[stage].options.size()):
		var button := Button.new()
		button.text = "%s     ›" % steps[stage].options[i]
		button.custom_minimum_size.y = 46
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#17293d")
		normal.border_color = Color("#30465d")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(9)
		normal.content_margin_left = 16
		normal.content_margin_right = 16
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#203b52")
		hover.border_color = PALETTE.get(String(mission_id), PALETTE["seasons"])
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_color_override("font_color", Color("#edf5fc"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.pressed.connect(_choose.bind(i))
		action_buttons.add_child(button)


func _choose(choice: int) -> void:
	if locked:
		return
	var data: Dictionary = PACK.get(String(mission_id), PACK["seasons"])
	var step: Dictionary = data.steps[stage]
	if choice != step.answer:
		diorama.set_lesson_state(stage, false, true)
		feedback.text = "Ölçüm uyuşmadı. %s" % _hint(String(mission_id), stage)
		feedback.add_theme_color_override("font_color", Color("#ff9c8e"))
		return
	locked = true
	diorama.set_lesson_state(stage, true)
	feedback.text = "✓   %s" % step.feedback
	feedback.add_theme_color_override("font_color", PALETTE.get(String(mission_id), PALETTE["seasons"]))
	for button in action_buttons.get_children():
		button.disabled = true
	if stage == data.steps.size() - 1:
		var finish := Button.new()
		finish.text = "ONARIMI UYGULA  →"
		finish.custom_minimum_size.y = 48
		finish.pressed.connect(_finish)
		action_buttons.add_child(finish)
	else:
		var next := Button.new()
		next.text = "SONRAKİ ÖLÇÜM  →"
		next.custom_minimum_size.y = 48
		next.pressed.connect(_next_stage)
		action_buttons.add_child(next)


func _next_stage() -> void:
	stage += 1
	_show_stage()


func _finish() -> void:
	feedback.text = "BÖLGE ONARILDI  ·  DOĞRULAMA KAYDI MERKEZE GÖNDERİLDİ"
	completed.emit()


func _hint(key: String, step_index: int) -> String:
	var hints: Dictionary = {
		"seasons":["Dünya'nın eksen eğikliği yaklaşık 23,5°.", "Dik ışın alan yarımkürede yaz yaşanır.", "21 Haziran'da Kuzey Yarımküre'de gündüz en uzundur."],
		"bridge":["Dik kenarların karelerini topla.", "225'in karekökünü bul.", "Hesaplanan uzunluk 9–12–15 üçlüsünü tamamlar."],
		"turkish":["Olumsuzluk, kapının açık bırakılmamasını söylüyor.", "Güvenlik bağlamında tahliye yolu kapanmamalı.", "Komut, yetkisiz girişi engelleyecek biçimde açık olmalı."],
		"history":["Amasya Genelgesi, kongrelerden önce yayımlandı.", "Cemiyetler Sivas Kongresi'nde birleştirildi.", "TBMM 1920'de açıldı."],
		"english":["“We need” = “İhtiyacımız var”.", "“Not safe” = “Güvenli değil”.", "Uygun yanıt nazik ve açık bir yönerge vermeli."],
		"religion":["İhtiyaç sahibine destek dayanışmadır.", "Ortak ve kalıcı faydayı gözet.", "Yardım, insan onurunu koruyarak yapılır."]}
	return hints.get(key, ["Kaydı yeniden incele."])[step_index]
