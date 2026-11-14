extends Control
## MERİDYEN's short post-experiment transmission.

signal dismissed

const GUIDE_TEXTURE = preload("res://assets/characters/meridyen_guide.png")
const BROKEN_LAWS_ATLAS = preload("res://assets/story/broken_laws_atlas.png")

const NEWS_REPORTS := {
	"seasons": {"region": Rect2(8, 8, 752, 494), "place": "GÖZLEMEVİ · EGE GÖZLEM HATTI", "headline": "ÜÇ GÜNEŞ, AYNI AVLUDA ÜÇ FARKLI GÖLGE OLUŞTURDU", "report": "Güneş ışığının geliş açısı kayda göre değişmedi. Ancak gözlem avlusundaki gölgeler aynı anda üç yöne uzadı; seradaki sıcaklık çizelgesi de mevsim hesabından saptı."},
	"measurement": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · TAŞIMA LABORATUVARI", "headline": "YÜK ASANSÖRÜ, KÜTLE VE AĞIRLIK KAYDI KARIŞINCA DURDU", "report": "Kayıt ekranı kilogram ile newtonu tek ölçü gibi gösterdi. Aynı yük, iki istasyonda farklı sınırda göründü ve güvenlik kilidi asansörü kapattı."},
	"vectors": {"region": Rect2(8, 8, 752, 494), "place": "GÖZLEMEVİ · VEKTÖR LİMANI", "headline": "YÖN KAYDI SİLİNEN KAPSÜL RIHTIMA YANDAN SÜRÜKLENDİ", "report": "Kapsülün itki büyüklüğü doğruydu; doğu-kuzey yön bileşenleri kayıttan düşmüştü. Otomatik yanaşma, doğru uzunluğa rağmen rotayı tutturamadı."},
	"derivative": {"region": Rect2(8, 517, 752, 494), "place": "GÖZLEMEVİ · DEPO ATÖLYESİ", "headline": "KUTU BÜYÜDÜKÇE HACMİ ARTMADI: DEPO PLANI TAŞTI", "report": "Aynı levhadan kesilen kareler büyütülünce kutu önce genişledi, sonra kapasitesi azaldı. Eski kayıt her kesimde hacmin artacağını söylüyordu; raf ölçüleri birbiriyle uyuşmadı."},
	"bridge": {"region": Rect2(8, 517, 752, 494), "place": "GÖZLEMEVİ · KÖPRÜ ŞANTİYESİ", "headline": "KÖPRÜNÜN İKİ YARISI ORTADA BİRLEŞMEDİ", "report": "Taşıyıcılar ölçümde eşit görünüyordu; kayıtta bir açıklığın uzunluğu eksikti. Montaj ekibi, eksik parçayı fark edince köprüyü güvenli biçimde durdurdu."},
	"prism": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · MALZEME DEPOSU", "headline": "KATMAN HESABI ATLANNCA KORUYUCU KASA KAPANMADI", "report": "Kasanın dış ölçüsü doğruydu ama iç kaplama katmanları hesaba katılmadı. Ölçümler ile teslim fişi uyuşmayınca kırılabilir örnekler taşınamadı."},
	"free_fall": {"region": Rect2(8, 517, 752, 494), "place": "GÖZLEMEVİ · DÜŞME TESTİ KUYUSU", "headline": "İKİ CİSİMİN DÜŞÜŞ SÜRESİ TEK DEĞER OLARAK KAYDEDİLDİ", "report": "Hava direnci ayrı ölçülmeyince iki farklı cismin iniş süreleri aynı kayda sıkıştırıldı. Test düzeneği sonuçları tekrar edemedi ve güvenlik ağı erken açıldı."},
	"newton": {"region": Rect2(8, 517, 752, 494), "place": "GÖZLEMEVİ · HAREKET HATTI", "headline": "AYNI İTİŞ, AĞIR KIZAKTA AYNI İVMEYİ ÜRETMEDİ", "report": "Yük iki katına çıktığında hız değişimi kayıttaki kadar olmadı. İtme kuvveti sabit kalmıştı; MERİDYEN'in çizelgesinde kütle farkı görünmüyordu."},
	"projectile": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · ATIŞ SAHASI", "headline": "YATAY ROTA DEĞİŞİNCE DÜŞME SÜRESİ DE KAYITTA DEĞİŞTİ", "report": "İki fırlatma aynı yükseklikten başladı; yatay hızları farklıydı. Gerçek düşüş süreleri eşit kalırken kayıt tek bir eğriyi izledi ve hedefler kaçırıldı."},
	"collision": {"region": Rect2(8, 517, 752, 494), "place": "GÖZLEMEVİ · ÇARPIŞMA PİSTİ", "headline": "ÇARPIŞMA SONRASI YÖN KAYDI KAYBOLDU", "report": "Arabaların çarpışma öncesi hızları ölçüldü; yön işaretleri kayıttan silindi. Son toplam hız beklenenin iki katı çıktı ve deney tekrarlanamaz hale geldi."},
	"indicator": {"region": Rect2(777, 8, 752, 494), "place": "GÖZLEMEVİ · ÇÖZELTİ LABORATUVARI", "headline": "GÖSTERGE AYNI RENKTE KALDI, İKİ ÇÖZELTİ FARKLI TEPKİ VERDİ", "report": "Renk kaydı çözelti ölçümünden ayrıştı. pH sensörü iki numuneyi aynı gösterince laboratuvar ekibi hangi kabın daha asidik olduğunu belirleyemedi."},
	"heart": {"region": Rect2(777, 8, 752, 494), "place": "GÖZLEMEVİ · YAŞAM PROTOKOLÜ", "headline": "OKSİJENSİZ KAN AKCİĞER YERİNE VÜCUDA YÖNLENDİRİLDİ", "report": "Ana toplardamardan gelen oksijence fakir kanın akış kaydı ters yöne döndü. Dokulara ulaşan oksijen azaldı; kalp ve damar ölçümleri MERİDYEN'in çizelgesiyle uyuşmadı."},
	"pressure": {"region": Rect2(777, 8, 752, 494), "place": "GÖZLEMEVİ · BASINÇ ODASI", "headline": "DERİNE İNEN SENSÖR, SU BASINCINDA ARTIŞ GÖRMEDİ", "report": "Aynı sıvıda derinlik arttıkça ölçülen basınç yükselmeliydi. Sensör sabit kaldı; su tankının kapak kilidi güvenlik nedeniyle devreye girdi."},
	"philosophy": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · FİKİR MEYDANI", "headline": "AYNI SÖZ, İKİ AYRI DÜŞÜNÜRE ATFEDİLDİ", "report": "Arşiv kayıtları bir alıntıyı farklı filozoflara bağladı. Sözün bağlamı ve dayanağı kaybolunca öğrenciler çelişkili kaynaklarla karşılaştı."},
	"history": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · TARİH ARŞİVİ", "headline": "BELGELERİN TARİHİ YER DEĞİŞTİRDİ, KRONOLOJİ BOZULDU", "report": "Aynı olayı anlatan iki belgenin tarihleri birbirini tutmadı. Arşiv sırası kayınca bir anlaşma, onu hazırlayan olaydan önce gerçekleşmiş göründü."},
	"pulley": {"region": Rect2(8, 517, 752, 494), "place": "GÖZLEMEVİ · MAKARA ATÖLYESİ", "headline": "YÜK DAHA AZ KUVVETLE ÇIKTI, İP YOLU KAYITTA KISALDI", "report": "Hareketli makara yükü kaldırdı ama kuvvet kazancı ile çekilen ip yolu arasındaki karşılık kayıtta yoktu. Enerji hesabı tutmayınca vinç durduruldu."},
	"turkish": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · UYARI İSTASYONU", "headline": "TEK BİR EKSİK EK, GÜVENLİK UYARISINI TERSİNE ÇEVİRDİ", "report": "Talimatın olumsuzluk eki kayıt satırından silinince kapalı çıkış açık, güvenli rota tehlikeli göründü. Ekip, levhadaki metinle sensör kaydını karşılaştırdı."},
	"english": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · İLETİŞİM AĞI", "headline": "YARDIM ÇAĞRISI, UYARI MESAJI OLARAK YANLIŞ EKİBE GİTTİ", "report": "İstek cümlesindeki amaç kaydıyla uyarı işareti karıştı. Acil yardım çağrısı yanlış kanala yöneldi; ekipler özgün mesajı yeniden okumak zorunda kaldı."},
	"religion": {"region": Rect2(777, 517, 752, 494), "place": "GÖZLEMEVİ · TOPLUMSAL DESTEK AĞI", "headline": "YARDIM KAYDI İHTİYAÇ YERİNE GÖSTERİŞİ İŞARET ETTİ", "report": "Destek kaynakları yanlış ölçüte göre dağıtılınca gerçek ihtiyaç noktası boş kaldı. Gözlem ekibi kayıtları başvuru ve sonuçlarla karşılaştırdı."},
	"genetics": {"region": Rect2(777, 8, 752, 494), "place": "GÖZLEMEVİ · YAŞAM PROTOKOLÜ", "headline": "GÖRÜNMEYEN ÇEKİNİK ALEL, KAYITTA TAMAMEN SİLİNDİ", "report": "Ebeveynlerde görünmeyen bir alel sonraki kuşakta ortaya çıktı. MERİDYEN'in kayıt tablosu çekinik bilgiyi yok saydığı için kalıtım olasılıkları tutmadı."},
	"spin": {"region": Rect2(777, 8, 752, 494), "place": "GÖZLEMEVİ · MODERN ATOM LABORATUVARI", "headline": "ATOM DEMETİ İKİ AYRI ÖLÇÜM İZİ BIRAKTI", "report": "Dedektör kaydı atom demetini tek, sürekli bir iz olarak öngördü. Ölçüm ekranında ise iki ayrık sonuç belirdi; cihazın kaydı ile gözlenen dağılım ayrıştı."}
}

var _continue_action: Callable
var _return_action: Callable
var _card: PanelContainer
var _news_image: TextureRect
var _news_place: Label
var _news_headline: Label
var _news_report: Label
var _portrait: TextureRect
var _speaker: Label
## Public labels are kept available for campaign UI and lightweight flow checks.
var heading: Label
var message: Label
var _actions: GridContainer
var _continue_button: Button
var _return_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 40
	mouse_filter = Control.MOUSE_FILTER_STOP
	var wash := ColorRect.new()
	wash.color = Color(UITheme.BG, 0.62)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wash)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24.0
	center.offset_right = -24.0
	center.offset_top = 24.0
	center.offset_bottom = -24.0
	add_child(center)
	_card = PanelContainer.new()
	_card.theme_type_variation = "ConsolePanel"
	_card.custom_minimum_size = Vector2(0, 0)
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_card.add_child(content)
	_news_image = TextureRect.new()
	_news_image.custom_minimum_size = Vector2(0, 250)
	_news_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_news_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_news_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_news_image)
	_news_place = Label.new()
	_news_place.theme_type_variation = "KickerLabel"
	_news_place.add_theme_color_override("font_color", Color("#dbae62"))
	content.add_child(_news_place)
	_news_headline = Label.new()
	_news_headline.add_theme_font_size_override("font_size", 22)
	_news_headline.add_theme_color_override("font_color", Color("#eeeae0"))
	_news_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_news_headline)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	content.add_child(header)
	_portrait = TextureRect.new()
	_portrait.texture = GUIDE_TEXTURE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(88, 88)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 7)
	header.add_child(identity)
	_speaker = Label.new()
	_speaker.text = "MERİDYEN"
	_speaker.theme_type_variation = "SectionLabel"
	identity.add_child(_speaker)
	heading = Label.new()
	heading.theme_type_variation = "HeadlineLabel"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(heading)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 19)
	content.add_child(message)
	_news_report = Label.new()
	_news_report.add_theme_font_size_override("font_size", 16)
	_news_report.add_theme_color_override("font_color", Color("#b1ac9e"))
	_news_report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_news_report)
	_actions = GridContainer.new()
	_actions.add_theme_constant_override("h_separation", 12)
	_actions.add_theme_constant_override("v_separation", 10)
	content.add_child(_actions)
	_continue_button = Button.new()
	_continue_button.theme_type_variation = "PrimaryButton"
	_continue_button.custom_minimum_size.y = 48
	_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_button.pressed.connect(_continue)
	_actions.add_child(_continue_button)
	_return_button = Button.new()
	_return_button.text = "Merkeze dön"
	_return_button.custom_minimum_size.y = 48
	_return_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_return_button.pressed.connect(_return)
	_actions.add_child(_return_button)
	resized.connect(_layout_dialogue)
	hide()


func _layout_dialogue() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	var usable_width := maxf(get_viewport_rect().size.x - 64.0, 280.0)
	_card.custom_minimum_size.x = minf(760.0, usable_width)
	var compact := usable_width < 520.0
	_news_image.custom_minimum_size.y = 148.0 if compact else 250.0
	_portrait.custom_minimum_size = Vector2(64, 64) if compact else Vector2(88, 88)
	heading.add_theme_font_size_override("font_size", 23 if compact else 29)
	message.add_theme_font_size_override("font_size", 16 if compact else 19)
	_news_headline.add_theme_font_size_override("font_size", 18 if compact else 22)
	_news_report.add_theme_font_size_override("font_size", 14 if compact else 16)
	_actions.columns = 1 if compact or not _return_button.visible else 2


func present(title: String, text: String, action_text: String, on_continue: Callable, on_return: Callable = Callable(), news_id: StringName = &"") -> void:
	heading.text = title
	message.text = text
	var report: Dictionary = NEWS_REPORTS.get(String(news_id), {})
	var showing_news := not report.is_empty()
	_news_image.visible = showing_news
	_news_place.visible = showing_news
	_news_headline.visible = showing_news
	_news_report.visible = showing_news
	if showing_news:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = BROKEN_LAWS_ATLAS
		atlas_texture.region = report["region"]
		_news_image.texture = atlas_texture
		_news_place.text = "CANLI GÖZLEM  ·  " + String(report["place"])
		_news_headline.text = String(report["headline"])
		_news_report.text = String(report["report"])
		_speaker.text = "DÜNYA HABERLERİ  ·  MERİDYEN GÖZLEM AĞI"
	else:
		_news_image.texture = null
		_speaker.text = "MERİDYEN"
	_continue_button.text = action_text
	_continue_action = on_continue
	_return_action = on_return
	_return_button.visible = on_return.is_valid()
	_layout_dialogue()
	show()
	_card.modulate.a = 0.0
	_card.scale = Vector2(0.98, 0.98)
	var entrance := create_tween()
	entrance.set_parallel(true)
	entrance.tween_property(_card, "modulate:a", 1.0, 0.2)
	entrance.tween_property(_card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_continue_button.grab_focus()


func _continue() -> void:
	var action := _continue_action
	hide()
	_continue_action = Callable()
	_return_action = Callable()
	if action.is_valid():
		action.call()
	dismissed.emit()


func _return() -> void:
	var action := _return_action
	hide()
	_continue_action = Callable()
	_return_action = Callable()
	if action.is_valid():
		action.call()
	dismissed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _return_action.is_valid():
			_return()
		else:
			_continue()
		get_viewport().set_input_as_handled()
