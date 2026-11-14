extends "res://scripts/mission.gd"
## Data-led interaction shell for the LGS campaign's six short, tactile missions.

const UITheme = preload("res://scripts/ui_theme.gd")
const StoryStage3D = preload("res://scripts/lgs_story_stage_3d.gd")

const PHASES: Array[String] = ["KRİZ", "SINA", "TEŞHİS", "DÜZELT", "TOPARLA", "MÜHÜR"]

class EvidenceSource extends Button:
	var evidence_id := -1

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var preview := Label.new()
		preview.text = text
		preview.theme_type_variation = "StrongLabel"
		set_drag_preview(preview)
		return {"evidence_id": evidence_id}


class EvidenceDropZone extends PanelContainer:
	signal evidence_dropped(evidence_id: int)

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("evidence_id")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		evidence_dropped.emit(int(data.evidence_id))

@export var mission_id: StringName = &"seasons"

const PALETTE := {
	"seasons": Color("#3b7867"), "bridge": Color("#a46535"),
	"turkish": Color("#39688d"), "history": Color("#79528e"),
	"english": Color("#39688d"), "religion": Color("#8c6b2a")
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
		"title":"İSPAT LABORATUVARI", "subject":"MATEMATİK  ·  M.8.2.1.3",
		"brief":"Yapay zekâ, (a+b)² özdeşliğini ispatlıyor. 3D alan modelini incele; atlanan parçayı ve hatalı satırı bulup düzelt.",
		"proof_lines":[
			"Kenar: a+b",
			"Alan: (a+b)²",
			"Alanlar: a², ab, ab, b²",
			"Toplam: a²+ab+ab+b²",
			"(a+b)² = a²+b²"],
		"faulty_line":4,
		"rescue":{"label":"Yeni ölçü: a=3, b=2. Eksik iki dikdörtgenin toplam alanı kaçtır?", "expected":"12", "feedback":"Yeni ölçülerde iki ab parçası da hesaba katıldı; köprü açıklığı kapandı."},
		"feedback":"İspat düzeltildi. İki dikdörtgenin alanı ab+ab=2ab; özdeşlik artık alan modeliyle örtüşüyor."},
	"turkish": {
		"title":"BOZUK TALİMAT", "subject":"TÜRKÇE  ·  CÜMLEDE ANLAM",
		"brief":"Güvenlik komutunda bir olumsuzluk eki ve bağlam kaymış. Anlamı koruyan, uygulanabilir talimatı kur.",
		"steps":[
			{"label":"ANLAMI OKU  /  olumsuzluk kaydı", "record":"OLAY KAYDI  ·  Güvenlik fişinde: “Kapıyı açık bırakmayın.”", "options":["Kapıyı kapalı tutun.", "Kapıyı açık tutun.", "Kapıyı açmadan bırakın."], "answer":0, "feedback":"“Bırakmayın” olumsuzluğu, kapının açık kalmaması gerektiğini bildirir."},
			{"label":"BAĞLAMI OKU  /  alarm kaydı", "record":"SAHA NOTU  ·  Alarm çalarsa ekip güvenli çıkış yoluna ulaşmalı.", "options":["Çıkış yolunu kapatın.", "Çıkış yolunu açık tutun.", "Alarmı duymazdan gelin."], "answer":1, "feedback":"Bağlam, güvenli tahliye için çıkışın açık tutulmasını gerektiriyor."},
			{"label":"KOMUTU ONAR  /  güvenlik kaydı", "options":["Yetkisiz girişte kapıyı kilitleyin.", "Yetkisiz girişte kapıyı kilitlemeyin.", "Kapı yetkisiz girişi kilitlesin."], "answer":0, "feedback":"Açık ve bağlama uygun komut doğrulandı. Metindeki koordinatlar çözüldü."}],
		"rescue":{"label":"Yeni kayıt: “Duman koridora yayıldı; kuzey çıkışı açık.” Ekibe hangi talimat gönderilmeli?", "options":["Kuzey çıkışını kullanın.", "Koridora dönün.", "Çıkışı kapalı tutun."], "answer":0, "feedback":"Yeni bağlamda güvenli çıkış korundu."}},
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
			{"label":"MESSAGE 01  /  need ve iletişim amacı", "record":"TRANSCRIPT 01  ·  “We need clean water.”  /  yardım istasyonundan kısa mesaj", "options":["They need clean water.", "They need a new map.", "They are closing the station."], "answer":0, "feedback":"“We need” bir ihtiyacı bildirir; ekip temiz su istiyor."},
			{"label":"MESSAGE 02  /  not ve durum bilgisi", "record":"Telsiz: “The bridge is not safe. Please wait.” Ekip köprü kontrol noktasında bekliyor.", "options":["Köprü güvenli.", "Köprü güvenli değil.", "Köprü yeniden açıldı."], "answer":1, "feedback":"“Not safe” olumsuzluk bildirir: köprü güvenli değil."},
			{"label":"TELSİZİ ONAR  /  Give a clear instruction", "options":["Please wait at the station.", "The station is a blue color.", "I am not a bridge."], "answer":0, "feedback":"Kısa ve anlaşılır yönerge gönderildi. Yardım hattı bağlandı."}],
		"rescue":{"label":"NEW MESSAGE: “Could you send a map? The river route is blocked.” What should the team send?", "options":["A map.", "Clean water.", "A bridge."], "answer":0, "feedback":"Mesajın amacı ve bağlamı birlikte okundu; doğru malzeme ekibe ulaştı."}},
	"religion": {
		"title":"DAYANIŞMA ARŞİVİ", "subject":"DİN KÜLTÜRÜ  ·  YARDIMLAŞMA",
		"brief":"Toplumsal yardım kayıtlarını güvenilir kavram ve örneklerle eşleştir. Her seçimde kaynağı ve etkisini incele.",
		"steps":[
			{"label":"KAVRAM FİŞİNİ OKU  /  ihtiyaç ve destek", "record":"KAYNAK NOTU  ·  Zekât ve sadaka, paylaşma ve yardımlaşma kavramlarıyla ele alınır.", "options":["Yardımlaşma", "İsraf", "Gösteriş"], "answer":0, "feedback":"Yardımlaşma, ihtiyaçların karşılanmasında dayanışmayı ve sorumluluğu destekler."},
			{"label":"ÖRNEK OLAYI OKU  /  ortak iyilik", "record":"İHTİYAÇ NOTU  ·  Mahalle çeşmesi düzenli bakım olmadan kullanılamıyor.", "options":["Bir çeşmenin bakımını birlikte üstlenmek", "Kullanılabilir gıdayı çöpe atmak", "Yardımı yalnızca duyurmak"], "answer":0, "feedback":"Kalıcı yarar sağlayan ortak katkı, dayanışmanın somut bir örneğidir."},
			{"label":"FİLTREYİ ONAR  /  yardımın niteliği", "options":["İhtiyacı gözeten, incitmeden yapılan destek", "Karşılık bekleyerek yapılan yardım", "Başkalarını küçümseyerek verilen destek"], "answer":0, "feedback":"Kayıtlar; samimiyet, ihtiyaç ve insan onurunu gözeten örneklerle onarıldı."}],
		"rescue":{"label":"Yeni kayıt: Bir aile sıcak yemek istiyor; başka bir komşunun kullanılabilir eşyası var. Hangi kayıt önce eşleşmeli?", "options":["Sıcak yemek ihtiyacı", "Eşyaların piyasa değeri", "Yardımın duyurulma sayısı"], "answer":0, "feedback":"Yeni durumda destek, miktardan önce açık ihtiyaca göre yönlendirildi."}}
}

var stage := 0
var locked := false
var shell: VBoxContainer
var feedback: Label
var action_label: Label
var action_buttons: VBoxContainer
var progress_label: Label
var diorama
var phase := 0
var _completion_emitted := false
var _selected_evidence := -1
var attempts := 0
var fault_visible := false
var phase_segments: HBoxContainer


func _ready() -> void:
	if mission_id == &"":
		mission_id = &"seasons"
	fault_visible = true
	if mission_id == &"bridge":
		DisplayServer.window_set_title("İspat Laboratuvarı · LGS Matematik")
	_build_ui()
	_show_stage()


func _build_ui() -> void:
	var data: Dictionary = PACK.get(String(mission_id), PACK["seasons"])
	var accent: Color = PALETTE.get(String(mission_id), PALETTE["seasons"])
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	shell = VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = 36
	shell.offset_top = 18 if mission_id == &"bridge" else 26
	shell.offset_right = -36
	shell.offset_bottom = -18 if mission_id == &"bridge" else -26
	shell.add_theme_constant_override("separation", 10)
	add_child(shell)
	var header := HBoxContainer.new()
	shell.add_child(header)
	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "KickerLabel"
	eyebrow.text = data.subject
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow.add_theme_color_override("font_color", accent)
	eyebrow.add_theme_font_size_override("font_size", 15)
	header.add_child(eyebrow)
	progress_label = Label.new()
	progress_label.theme_type_variation = "KickerLabel"
	header.add_child(progress_label)
	phase_segments = HBoxContainer.new()
	phase_segments.add_theme_constant_override("separation", 5)
	for i in PHASES.size():
		var segment := ColorRect.new()
		segment.name = "PhaseSegment%d" % i
		segment.custom_minimum_size = Vector2(0, 3)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.color = UITheme.EDGE
		phase_segments.add_child(segment)
	shell.add_child(phase_segments)
	var title := Label.new()
	title.text = data.title
	title.theme_type_variation = "HeadlineLabel"
	shell.add_child(title)
	var brief := Label.new()
	brief.text = data.brief
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brief.hide()
	brief.add_theme_color_override("font_color", UITheme.MUTED)
	shell.add_child(brief)
	var stage_card := PanelContainer.new()
	stage_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = UITheme.PANEL
	panel_style.border_color = accent.darkened(0.35)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	var card_padding := 14
	panel_style.content_margin_left = card_padding
	panel_style.content_margin_top = card_padding
	panel_style.content_margin_right = card_padding
	panel_style.content_margin_bottom = card_padding
	stage_card.add_theme_stylebox_override("panel", panel_style)
	shell.add_child(stage_card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12 if mission_id == &"bridge" else 15)
	stage_card.add_child(content)
	var visual_row := HBoxContainer.new()
	visual_row.add_theme_constant_override("separation", 18)
	visual_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(visual_row)
	diorama = StoryStage3D.new() if mission_id in [&"turkish", &"english", &"religion"] else load("res://scenes/lgs_diorama.tscn").instantiate()
	diorama.mission_id = mission_id
	if mission_id == &"bridge":
		diorama.custom_minimum_size = Vector2(500, 340)
		diorama.proof_animation_finished.connect(_on_proof_animation_finished)
	else:
		diorama.custom_minimum_size = Vector2(460, 330)
	diorama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diorama.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_row.add_child(diorama)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 330
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var action_scroll := ScrollContainer.new()
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.custom_minimum_size.x = 350
	visual_row.add_child(action_scroll)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(right)
	var step_name := Label.new()
	step_name.text = "Onarım tezgâhı"
	step_name.theme_type_variation = "KickerLabel"
	step_name.add_theme_color_override("font_color", accent)
	right.add_child(step_name)
	action_label = Label.new()
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.theme_type_variation = "SectionLabel"
	right.add_child(action_label)
	action_buttons = VBoxContainer.new()
	action_buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_buttons.add_theme_constant_override("separation", 6)
	right.add_child(action_buttons)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 32
	feedback.add_theme_color_override("font_color", accent)
	right.add_child(feedback)
	var note := Label.new()
	note.text = "MERİDYEN’in bozduğu ayarı kanıtla düzelt; yeni durumda onarımı kendin uygula."
	note.hide()
	note.theme_type_variation = "MutedLabel"
	note.add_theme_color_override("font_color", UITheme.MUTED)
	shell.add_child(note)


func _show_stage() -> void:
	var data: Dictionary = PACK.get(String(mission_id), PACK["seasons"])
	phase = clampi(phase, 0, PHASES.size() - 1)
	_set_phase_indicator()
	locked = false
	_clear_actions()
	var solved := phase >= 4 and not fault_visible
	diorama.set_lesson_state(phase, solved, fault_visible, data.get("faulty_line", -1) if phase >= 2 and mission_id == &"bridge" else -1, phase >= 4 and mission_id == &"bridge")
	match phase:
		0:
			action_label.text = _crisis_line(String(mission_id))
			feedback.text = "Bozuk ayarı ve sahnedeki kaybı incele."
			_add_action_button("SAHNEDEKİ KAYBI İNCELE", _begin_test)
		1:
			action_label.text = _test_line(String(mission_id))
			feedback.text = "Ölçüm kaydını çalıştır; sonuç sahnede ve kayıtta görünsün."
			var run_button := _add_action_button("ÖLÇÜM KAYDINI AL", _advance_phase)
			if mission_id == &"bridge":
				run_button.disabled = not diorama.proof_animation_done
				if not diorama.proof_animation_done:
					feedback.text = "Alan parçaları masaya yerleşiyor; kaydı açmak için yazımın bitmesini bekle."
		2:
			if mission_id == &"bridge":
				_show_proof_diagnosis(data)
			else:
				_show_evidence_check(data, stage, "KANIT FİŞİNİ BOZUK AYAR SATIRINA BIRAK" if stage == 0 else "İKİNCİ KAYDI AYNI BAĞLAMDA KARŞILAŞTIR")
		3:
			if mission_id == &"bridge":
				_show_proof_repair(data)
			else:
				_show_repair(data)
		4:
			if mission_id == &"bridge":
				_show_bridge_rescue(data)
			else:
				_show_rescue(data)
		5:
			if mission_id == &"bridge":
				action_label.text = "Alan modeli ve köprü açıklığı birlikte doğrulandı."
			else:
				action_label.text = "Onarılan ayarla yeni durumda düzenek yeniden çalışıyor."
			feedback.text = "Doğru davranış sahnede kalıcı; kaydı merkeze mühürle."
			_add_action_button("MÜHÜRÜ KAPAT", _finish)
	_update_status_colors()


func _set_phase_indicator() -> void:
	progress_label.text = "%d / 6   %s" % [phase + 1, PHASES[phase].capitalize()]
	for index in phase_segments.get_child_count():
		var segment := phase_segments.get_child(index) as ColorRect
		segment.color = UITheme.ACCENT.darkened(0.5) if index < phase else UITheme.ACCENT if index == phase else UITheme.EDGE


func _clear_actions() -> void:
	for child in action_buttons.get_children():
		action_buttons.remove_child(child)
		child.queue_free()
	_selected_evidence = -1


func _add_action_button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 40
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.theme_type_variation = "PrimaryButton" if label == "MÜHÜRÜ KAPAT" else "Button"
	button.pressed.connect(callback)
	action_buttons.add_child(button)
	return button


func _add_choice_buttons(options: Array, callback: Callable) -> void:
	for index in options.size():
		_add_action_button(String(options[index]), callback.bind(index))


func _add_evidence_drop(options: Array, callback: Callable) -> void:
	for index in options.size():
		var card := EvidenceSource.new()
		card.evidence_id = index
		card.text = String(options[index])
		card.custom_minimum_size.y = 40
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_constant_override("line_spacing", 2)
		card.add_theme_color_override("font_color", UITheme.INK)
		card.pressed.connect(func() -> void:
			_selected_evidence = index
			feedback.text = "Fiş seçildi; bozuk ayara uygula.")
		action_buttons.add_child(card)
	var zone := EvidenceDropZone.new()
	zone.custom_minimum_size.y = 44
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zone_style := StyleBoxFlat.new()
	zone_style.bg_color = UITheme.BG
	zone_style.border_color = UITheme.EDGE_STRONG
	zone_style.set_border_width_all(1)
	zone_style.set_corner_radius_all(2)
	zone_style.content_margin_left = 12
	zone_style.content_margin_top = 8
	zone_style.content_margin_right = 12
	zone_style.content_margin_bottom = 8
	zone.add_theme_stylebox_override("panel", zone_style)
	var zone_label := Label.new()
	zone_label.text = "Bozuk ayar: fişi buraya bırak"
	zone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zone_label.theme_type_variation = "KickerLabel"
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone.add_child(zone_label)
	zone.evidence_dropped.connect(callback)
	action_buttons.add_child(zone)
	_add_action_button("Seçilen kanıtı uygula", func() -> void:
		if _selected_evidence >= 0:
			callback.call(_selected_evidence)
		else:
			feedback.text = "Önce bir kanıt fişi seç.")


func _update_status_colors() -> void:
	var accent: Color = PALETTE.get(String(mission_id), UITheme.ACCENT)
	feedback.add_theme_color_override("font_color", UITheme.DANGER if fault_visible else accent)


func _crisis_line(key: String) -> String:
	return {
		"bridge":"Köprü orta kirişi çöktü; alan kaydında iki dikdörtgen görünmesine rağmen toplam eksik.",
		"turkish":"MERİDYEN komutu ters okudu; tahliye kapısı kapandı ve ekip dışarıda kaldı.",
		"english":"Telsiz anahtar kelimeye göre yanlış malzeme gönderdi; ekip köprüde bekliyor.",
		"religion":"Destek tablosu en büyük paketi yanlış haneye bıraktı; acil ihtiyaç karşılanmadı."
	}.get(key, "Düzeneğin ölçümü beklenen sonuçtan saptı; kayıp sahnede görünür.")


func _test_line(key: String) -> String:
	return {
		"bridge":"a² ve b² kareleriyle iki ab dikdörtgenini alan karesinde izle.",
		"turkish":"Olay fişindeki olumsuzluk ve çıkış durumu aynı kayda işlensin.",
		"english":"Telsiz kaydını ve yardım noktasının bağlam notunu birlikte oku.",
		"religion":"İhtiyaç kaydıyla destek fişinin kaynağını yan yana incele."
	}.get(key, "Ölçümü çalıştır ve kayıttaki farkı gözlemle.")


func _begin_test() -> void:
	phase = 1
	_show_stage()


func _advance_phase() -> void:
	if phase == 1:
		stage = 0
	phase = mini(phase + 1, 5)
	_show_stage()


func _show_evidence_check(data: Dictionary, index: int, prompt: String) -> void:
	var step: Dictionary = data.steps[index]
	action_label.text = String(step.label)
	feedback.text = prompt
	if step.has("record"):
		var record := Label.new()
		record.text = String(step.record)
		record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		record.theme_type_variation = "StrongLabel"
		record.custom_minimum_size.y = 42
		action_buttons.add_child(record)
	_add_evidence_drop(step.options, _choose_evidence.bind(index))


func _choose_evidence(choice: int, index: int) -> void:
	var data: Dictionary = PACK[String(mission_id)]
	var step: Dictionary = data.steps[index]
	if choice != int(step.answer):
		fault_visible = true
		diorama.set_lesson_state(phase, false, true)
		feedback.text = "Kanıt kaydı bu ilişkiyi desteklemiyor; %s" % _hint(String(mission_id), index)
		_update_status_colors()
		return
	fault_visible = false
	feedback.text = "Kayıt uyuştu. %s" % String(step.feedback)
	if index == 0:
		stage = 1
		_show_stage()
	else:
		stage = 0
		phase = 3
		_show_stage()


func _on_proof_animation_finished() -> void:
	if mission_id != &"bridge" or phase != 1:
		return
	for button in action_buttons.get_children():
		button.disabled = false
	feedback.text = "Dört alan parçası ölçüm kaydına geçti; şimdi kaydı aç."


func _show_proof_diagnosis(data: Dictionary) -> void:
	action_label.text = "Alan modelinin hangi satırı köprü açıklığını bırakıyor?"
	feedback.text = "İspat tahtasındaki son satırı, masadaki dört alan parçasıyla karşılaştır."
	_add_choice_buttons(data.proof_lines, _choose_proof_line)


func _choose_proof_line(index: int) -> void:
	var data: Dictionary = PACK["bridge"]
	if index != int(data.faulty_line):
		fault_visible = true
		diorama.set_lesson_state(phase, false, true, index, false)
		feedback.text = "Bu satır parça alanlarıyla tutarlı; diğer satırları ve açık kalan yeri karşılaştır."
		_update_status_colors()
		return
	fault_visible = false
	feedback.text = "İki ab parçası tabloda var, fakat son satırın toplamına girmemiş."
	phase = 3
	_show_stage()


func _show_proof_repair(data: Dictionary) -> void:
	action_label.text = "Eksik iki alanı son satıra ekle."
	feedback.text = "İki ayrı ab dikdörtgenini alan toplamına kat."
	var entry := LineEdit.new()
	entry.placeholder_text = "Özdeşliği yaz"
	entry.custom_minimum_size.y = 48
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_theme_font_override("font", UITheme.FONT)
	entry.add_theme_font_size_override("font_size", 18)
	action_buttons.add_child(entry)
	var apply := _add_action_button("DÜZELTMEYİ DENE", func() -> void: _submit_formula(entry, data))
	entry.text_submitted.connect(func(_text: String) -> void: _submit_formula(entry, data))
	apply.theme_type_variation = "PrimaryButton"


func _show_repair(data: Dictionary) -> void:
	var step: Dictionary = data.steps[2]
	action_label.text = String(step.label)
	feedback.text = "Bozuk ayarı kanıttaki ilişkiye göre güncelle."
	_add_choice_buttons(step.options, _choose_repair)


func _choose_repair(choice: int) -> void:
	var data: Dictionary = PACK[String(mission_id)]
	var correct := int(data.steps[2].answer)
	if choice != correct:
		fault_visible = true
		diorama.set_lesson_state(phase, false, true)
		feedback.text = "Düzenek bu ayarla hâlâ kayıyor; %s" % _hint(String(mission_id), 2)
		_update_status_colors()
		return
	fault_visible = false
	diorama.set_lesson_state(phase, true)
	feedback.text = "Ayar değişti; ölçüm sahnede doğru davranışı gösteriyor."
	phase = 4
	_show_stage()


func _submit_formula(entry: LineEdit, data: Dictionary) -> void:
	if locked:
		return
	var submitted := _normalize_formula(entry.text)
	if submitted != "(a+b)^2=a^2+2ab+b^2" and submitted != "a^2+2ab+b^2=(a+b)^2":
		fault_visible = true
		diorama.set_lesson_state(phase, false, true, data.faulty_line, false)
		feedback.text = "Alan toplamı hâlâ modeli karşılamıyor; iki eş dikdörtgeni ayrı ayrı hesaba kat."
		_update_status_colors()
		return
	fault_visible = false
	diorama.set_lesson_state(phase, true, false, data.faulty_line, true)
	feedback.text = "Girilen özdeşlik alan modeliyle eşleşti; köprü taşıyıcılarını düzelt."
	phase = 4
	_show_stage()


func _normalize_formula(formula: String) -> String:
	return formula.to_lower().replace("²", "^2").replace(" ", "").replace("·", "")


func _numeric_matches(value: String, expected: String) -> bool:
	var normalized := value.strip_edges().replace(",", ".")
	if not normalized.is_valid_float() or not expected.is_valid_float():
		return false
	return is_equal_approx(normalized.to_float(), expected.to_float())


func _show_bridge_rescue(data: Dictionary) -> void:
	var rescue: Dictionary = data.rescue
	action_label.text = String(rescue.label)
	feedback.text = "Yeni kenar ölçülerinde açık alanı hesapla. Kalan hak: %d / 3" % (3 - attempts)
	var entry := LineEdit.new()
	entry.placeholder_text = "Alanı yaz"
	entry.custom_minimum_size.y = 48
	entry.add_theme_font_override("font", UITheme.FONT)
	entry.add_theme_font_size_override("font_size", 18)
	action_buttons.add_child(entry)
	var apply := _add_action_button("KİRİŞİ YÜKLE", func() -> void: _choose_rescue(entry.text))
	entry.text_submitted.connect(func(value: String) -> void: _choose_rescue(value))
	apply.theme_type_variation = "PrimaryButton"


func _show_rescue(data: Dictionary) -> void:
	var rescue: Dictionary = data.rescue
	action_label.text = String(rescue.label)
	feedback.text = "Yeni durumda doğru eylemi uygula. Kalan hak: %d / 3" % (3 - attempts)
	_add_choice_buttons(rescue.options, _choose_rescue)


func _choose_rescue(choice: Variant) -> void:
	if locked:
		return
	var data: Dictionary = PACK[String(mission_id)]
	var rescue: Dictionary = data.rescue
	var correct := _numeric_matches(String(choice), String(rescue.expected)) if mission_id == &"bridge" else int(choice) == int(rescue.answer)
	if not correct:
		attempts += 1
		fault_visible = true
		diorama.set_lesson_state(phase, false, true, data.get("faulty_line", -1), false)
		if mission_id == &"bridge":
			feedback.text = "Girilen alanla kiriş dengelenmedi; açıklıkta fark kaldı. %d hak kaldı." % (3 - attempts)
		elif mission_id == &"turkish":
			feedback.text = "Yanlış kapı açıldı; ekip bu çıkışı kullanamıyor. %d hak kaldı." % (3 - attempts)
		elif mission_id == &"english":
			feedback.text = "Yanlış malzeme yola çıktı; telsiz ekibi bekletiyor. %d hak kaldı." % (3 - attempts)
		else:
			feedback.text = "Destek yanlış haneye gitti; ihtiyaç karşılanmadı. %d hak kaldı." % (3 - attempts)
		_update_status_colors()
		if attempts >= 3:
			locked = true
			_clear_actions()
			feedback.text = "Haklar bitti; SAR ile kriz başlangıcına döndün."
			_add_action_button("Krize sar", _restart_after_failure)
		return
	locked = true
	fault_visible = false
	diorama.set_lesson_state(phase, true, false, data.get("faulty_line", -1), mission_id == &"bridge")
	feedback.text = String(rescue.feedback)
	phase = 5
	_show_stage()


func _finish() -> void:
	if phase != 5 or _completion_emitted:
		return
	_completion_emitted = true
	feedback.text = "MÜHÜRLENDİ · DÜZELTME KAYDI MERKEZE GÖNDERİLDİ"
	completed.emit()


func _hint(key: String, step_index: int) -> String:
	var hints: Dictionary = {
		"bridge":["Alan modelindeki bütün parçaları ve toplam satırını karşılaştır."],
		"turkish":["Olumsuzluk ve olay bağlamını birlikte kullan.", "Talimatı olay kaydındaki durumla karşılaştır.", "Komutun anlamı ile güvenlik hedefi aynı yönde olmalı."],
		"english":["Mesajın eylemini ve nedenini birlikte oku.", "Olumsuzluk sözcüğünün anlamı nasıl değiştirdiğini incele.", "Yanıt hem isteğe hem durum notuna uymalı."],
		"religion":["Kaynağın tanımını senaryodaki ihtiyaçla karşılaştır.", "Örneğin yararının kime ve ne zaman ulaştığını incele.", "Kararı ihtiyaç ve insan onuru kaydıyla denetle."]}
	return hints.get(key, ["Kaydı yeniden incele."])[step_index]


func _restart_after_failure() -> void:
	phase = 0
	stage = 0
	attempts = 0
	fault_visible = true
	locked = false
	_show_stage()
