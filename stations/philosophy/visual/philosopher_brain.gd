class_name PhilosopherBrain
extends Node
## Filozof Arka Plan LLM ve Durum Tetikleyici Motoru (Sokrates, Platon, Aristoteles, Epiküros,
## el-Kindî, el-Fârâbî, İbn Sînâ, İbn Rüşd).
##
## Kullanıcıya çoktan seçmeli şık gösterilmez. Kullanıcının yazdığı veya mikrofondan söylediği
## serbest cümle Gemini LLM'e (ve aynı anda yerel felsefi söz/kavram çözümleyiciye) gider.
## Filozofa ait herhangi bir söz, kavram, yöntem, eser veya kimlik bilgisi verildiğinde
## doğrudan aşama ilerler ve sonuca (ONARILDI) ulaşılır.

signal response_ready(result: Dictionary)

const STAGE_TRIGGERS := ["", "stir", "glimmer", "dawn", "recalled"]

const PERSONAS := {
	&"socrates": {
		"name": "Sokrates",
		"role": "Atina agorasında dolaşan, 'bildiğim tek şey hiçbir şey bilmediğimdir', 'sorgulanmamış hayat yaşanmaya değmez', 'kendini tanı' ve 'erdem bilgidir, kimse bilerek kötülük yapmaz' diyen, sorularla hakikati doğurtan (maiotik/ebelik) filozof.",
		"all_keywords": [
			"sokrates", "socrat", "bildigim tek sey", "tek bildigim", "hicbir sey bilmedig",
			"hic bir sey bilmedig", "bilmedigimi biliyorum", "bilgisiz", "cahil", "kendini tani",
			"kendini bil", "gnothi", "sorgulanmamis", "yasanmaya degmez", "erdem bilgidir",
			"erdem", "kimse bilerek kotuluk", "kotuluk yapmaz", "ahlak", "dogurtma", "dogurt",
			"maiotik", "mayotik", "ebelik", "ebe", "ironi", "curutme", "elenkhos", "soru sor",
			"sorularla", "diyalog", "savunma", "apologia", "baldiran", "zehir", "at sinegi",
			"agora", "atina", "platonun hocasi", "daimon", "ic ses", "hakikat", "bilgelik",
		],
		"confirm_1": "Evet! Bildiğim tek şey hiçbir şey bilmediğimdir; sorularımla ruhlardaki hakikati doğurturum!",
		"confirm_2": "İşte şimdi zihnim tamamen aydınlandı: Sorgulanmamış hayat yaşanmaya değmez ve erdem bilgidir!",
		"chat_reply": "Atina agorasında insanlara 'Erdem nedir, cesaret nedir?' diye sorarım; çünkü sorgulanmamış hayat yaşanmaya değmez.",
	},
	&"plato": {
		"name": "Platon",
		"role": "Sokrates'in öğrencisi, Akademia kurucusu; mağara alegorisi, değişmeyen İdealar dünyası, anamnesis (bilmek hatırlamaktır) ve Devlet'teki filozof kral düşünürü.",
		"all_keywords": [
			"platon", "eflatun", "magara", "golge", "zincir", "gunes", "alegori", "idea",
			"idealar", "formlar", "duyular dunyasi", "gorunus", "asil gercek", "hatirlamak",
			"anamnesis", "ruh olumsuz", "olumsuz ruh", "filozof kral", "devlet", "politeia",
			"akademia", "akademi", "sokratesin ogrencisi", "aristotelesin hocasi", "iyi ideasi",
			"adalet", "solen", "eros", "kopya", "hakikat",
		],
		"confirm_1": "Evet! Mağaradaki gölgeler gelip geçicidir; asıl hakikat akılla kavranan değişmeyen İdealar dünyasıdır!",
		"confirm_2": "Şimdi her şey berrak: Öğrenmek ruhun İdeaları yeniden kavramasıdır ve adil siteyi filozof krallar yönetir!",
		"chat_reply": "Duyularımız bize mağara duvarındaki gölgeleri gösterir; akıl gözüyle değişmeyen İdealar dünyasına yükselmeliyiz.",
	},
	&"aristotle": {
		"name": "Aristoteles",
		"role": "Stagiralı Aristoteles (Aristo), Lykeion kurucusu, Muallim-i Evvel; madde-form birliği (hylomorfizm), dört neden, mantık/kıyas (Organon) ve altın orta (eudaimonia) filozofu.",
		"all_keywords": [
			"aristoteles", "aristo", "madde", "form", "hylomorfizm", "toz", "potansiyel",
			"edimsel", "dort neden", "maddi", "formel", "fail", "ereksel", "telos", "amac",
			"mantik", "kiyas", "organon", "kategori", "oncul", "altin orta", "olcululuk",
			"eudaimonia", "mutluluk", "asiri uc", "lykeion", "lise", "peripatetik", "messai",
			"yuruyerek", "doga", "gozlem", "biyoloji", "metafizik", "nikhomakhos", "politika",
			"zoon politikon", "iskender", "stagira", "muallimi evvel", "ilk ogretmen",
		],
		"confirm_1": "Evet! Formlar ayrı bir dünyada değil nesnenin içindedir; varlığı maddi, formel, fail ve ereksel dört nedenle açıklarım!",
		"confirm_2": "Şimdi tamamlandı: Doğru düşünmenin aracı Organon mantığıdır, erdem ise iki aşırı uç arasındaki altın ortadır!",
		"chat_reply": "Lykeion revaklarında doğayı gözlemlerim; her nesne madde ve formun birliğidir ve erdem altın ortada bulunur.",
	},
	&"epicurus": {
		"name": "Epiküros",
		"role": "Bahçe okulu kurucusu; atomlar ve boşluk, ölüm korkusunun yersizliği ('ölüm varken biz yokuz'), acısızlık (aponia), ölçülü haz ve ruh dinginliği (ataraksia) filozofu.",
		"all_keywords": [
			"epikuros", "epikur", "atom", "bosluk", "sapma", "clinamen", "olum", "korku",
			"biz varken olum yok", "olum varken biz yokuz", "acisiz", "aponia", "olculu haz",
			"haz", "sade", "ataraksia", "dingin", "huzur", "bahce", "dostluk", "tetrapharmakos",
			"dort ilac", "ruh dinginligi",
		],
		"confirm_1": "Evet! Evren atomlar ve boşluktan ibarettir; biz varken ölüm yoktur, ölüm varken de biz yokuz!",
		"confirm_2": "Şimdi Bahçe'nin huzuru geri döndü: Gerçek mutluluk bedende acısızlık ve ruhta sarsılmaz ataraksia dinginliğidir!",
		"chat_reply": "Bahçe'de dostlarımla sade bir yaşam sürerim; ölüm korkusunu doğa bilgisiyle aşar, ataraksia dinginliğini ararım.",
	},
	&"kindi": {
		"name": "el-Kindî",
		"role": "Bağdat Beytü'l-Hikme bilgini, İslam felsefesinin kurucusu; hakikatin evrenselliği, akıl-vahiy uyumu, evrenin sonluluğu (hudûs) ve İlk Felsefe yazarı.",
		"all_keywords": [
			"kindi", "elkindi", "beytul hikme", "hikmet evi", "bagdat", "nereden gelirse",
			"hakikat", "miras", "tercume", "akil", "vahiy", "uyum", "uzlas", "din", "felsefe",
			"hudus", "sonlu", "zaman", "yaratil", "ilk felsefe", "uzuntu", "ilk neden",
			"islam felsefesi", "filozoful arab",
		],
		"confirm_1": "Evet! Hakikat nereden ve kimden gelirse gelsin insanlığın ortak malıdır; akıl ile vahiy aynı gerçeği söyler!",
		"confirm_2": "Şimdi İlk Felsefe'nin ışığı yandı: Evren hudûs deliliyle sonludur ve üzüntünün ilacı aklın bilgeliğidir!",
		"chat_reply": "Bağdat Beytü'l-Hikme'de kadim eserleri incelerim; hakikat nereden gelirse gelsin alınmalı, akıl ve vahiy uzlaşmalıdır.",
	},
	&"farabi": {
		"name": "el-Fârâbî",
		"role": "Muallim-i Sânî (İkinci Öğretmen); mantık, İlimlerin Sayımı (İhsâü'l-Ulûm), sudûr/Etkin Akıl ve Erdemli Şehir (el-Medînetü'l-Fâzıla) filozofu.",
		"all_keywords": [
			"farabi", "elfarabi", "muallimi sani", "muallim", "ikinci ogretmen", "mantik",
			"ihsa", "ilimlerin sayimi", "siniflandir", "bilimler", "sudur", "etkin akil",
			"faal akil", "tasma", "erdemli sehir", "medinetul fazila", "fazil sehir",
			"yardimlasma", "mutluluk", "kanun", "muzik",
		],
		"confirm_1": "Evet! Aristoteles'ten sonra mantığı yeniden kurduğum için bana Muallim-i Sânî derler; ilimleri İhsâü'l-Ulûm'da sınıflandırdım!",
		"confirm_2": "Şimdi tamamlandı: Varlık sudûr düzeniyle taşar ve insanlar gerçek mutluluk için Erdemli Şehir'de yardımlaşır!",
		"chat_reply": "Mantığı düşüncenin terazisi sayar, İhsâü'l-Ulûm ile bilimleri sınıflandırır ve insanların yardımlaştığı Erdemli Şehir'i kurarım.",
	},
	&"ibn_sina": {
		"name": "İbn Sînâ",
		"role": "Şeyhü'r-Reîs İbn Sînâ (Avicenna); Uçan Adam düşünce deneyi, Zorunlu-Mümkün varlık ayrımı, Kitâbü'ş-Şifâ ve el-Kânûn fi't-Tıbb müellifi.",
		"all_keywords": [
			"ibn sina", "ibni sina", "avicenna", "ucan adam", "boslukta", "ozbilinc", "benlik",
			"ruh", "nefs", "zorunlu", "mumkun", "vacibul vucud", "vacib", "mumkin", "mahiyet",
			"varlik", "sifa", "kitabus sifa", "kanun", "el kanun", "tip", "hekim", "seyhur reis",
			"seyh", "reis", "metafizik", "isarat",
		],
		"confirm_1": "Evet! Boşlukta asılı Uçan Adam bile kendi özbilincini bilir ve mümkün varlıklar Zorunlu Varlık'a muhtaçtır!",
		"confirm_2": "Şimdi her şey yerli yerinde: Kitâbü'ş-Şifâ ve el-Kânûn fi't-Tıbb'ın yazarı Şeyhü'r-Reîs İbn Sînâ'yım!",
		"chat_reply": "Boşlukta asılı Uçan Adam deneyiyle ruhun özbilincini gösterir, varlığı Zorunlu ve Mümkün diye ayırırım.",
	},
	&"ibn_rushd": {
		"name": "İbn Rüşd",
		"role": "Kurtuba kadısı İbn Rüşd (Averroes), Aristoteles'in büyük şârihi; 'hakikat hakikate ters düşmez' ilkesi, Faslü'l-Makâl, Tehâfütü't-Tehâfüt ve nedensellik savunucusu.",
		"all_keywords": [
			"ibn rusd", "ibni rusd", "averroes", "hakikat hakikate", "ters dusmez", "celismez",
			"iki hakikat", "sut kardes", "faslul makal", "fasl", "makal", "burhan", "tevil",
			"serh", "sarih", "tehafut", "nedensellik", "sebep", "aristoteles", "kurtuba",
			"endulus", "akil", "tabiat",
		],
		"confirm_1": "Evet! Hakikat hakikate ters düşmez, bilakis onu doğrular; felsefe ile din aynı hakikatin süt kardeşidir!",
		"confirm_2": "Şimdi tamamen berraklaştı: Aristoteles'in büyük şârihi olarak doğadaki nedenselliği ve aklın burhanını savunurum!",
		"chat_reply": "Kurtuba'da Aristoteles'i şerh ederim; Faslü'l-Makâl'de gösterdiğim gibi hakikat hakikate asla ters düşmez.",
	},
}

const KEY_FILE := "user://llm_key.txt"

var _http := HTTPRequest.new()
var _busy: bool = false
var _pending_context: Dictionary = {}


func _ready() -> void:
	add_child(_http)
	_http.timeout = 7.0
	_http.request_completed.connect(_on_llm_completed)


func cancel() -> void:
	_http.cancel_request()
	_busy = false
	_pending_context.clear()


func ask(
	philosopher_id: StringName,
	user_text: String,
	stage_level: int,
	anger_level: float,
	used_choices: Array[String],
	choices: Array,
	lines: Dictionary
) -> void:
	var clean: String = user_text.strip_edges()
	if clean == "":
		return

	var local_eval: Dictionary = _evaluate_locally(
		philosopher_id, clean, stage_level, anger_level, used_choices, choices, lines
	)
	var llm_cfg: Dictionary = _resolve_llm_config()
	if llm_cfg.is_empty():
		response_ready.emit(local_eval)
		return

	if _busy:
		_http.cancel_request()
		_busy = false

	_busy = true
	_pending_context = {
		"philosopher_id": philosopher_id,
		"user_text": clean,
		"stage_level": stage_level,
		"anger_level": anger_level,
		"used_choices": used_choices.duplicate(),
		"choices": choices,
		"lines": lines,
		"fallback": local_eval,
	}
	_send_llm_request(llm_cfg, _pending_context)


func _evaluate_locally(
	pid: StringName,
	text: String,
	stage_level: int,
	anger_level: float,
	_used_choices: Array[String],
	choices: Array,
	lines: Dictionary
) -> Dictionary:
	var norm: String = _normalize_tr(text)
	var persona: Dictionary = PERSONAS.get(pid, PERSONAS[&"socrates"])

	# 1. Önce açıkça rakip / yanlış iddiaları kontrol et (ancak doğru kavram geçmiyorsa)
	var hit_count: int = _count_philosopher_hits(pid, norm, choices)
	if hit_count == 0:
		for item: Variant in choices:
			if not (item is Dictionary):
				continue
			var c := item as Dictionary
			if bool(c.get("correct", false)):
				continue
			if _matches_choice(norm, c):
				var rid: String = String(c.get("reply", "wrong_sofist"))
				var will_leave: bool = (anger_level + 0.50) >= 1.0
				return {
					"trigger": "angry_leave" if will_leave else "wrong",
					"points": 0,
					"choice_id": String(c.get("id", "wrong")),
					"reply_id": "angry_leave" if will_leave else rid,
					"mood": "angry",
					"reply_text": String(lines.get("angry_leave" if will_leave else rid, "Hayır! Bu iddia benim felsefeme tamamen aykırı!")),
				}
		if _is_rival_concept(pid, norm):
			var rid_w: String = "wrong_empedokles" if lines.has("wrong_empedokles") and (norm.contains("element") or norm.contains("ates") or norm.contains("atom")) else "wrong_sofist"
			var will_leave2: bool = (anger_level + 0.50) >= 1.0
			return {
				"trigger": "angry_leave" if will_leave2 else "wrong",
				"points": 0,
				"choice_id": "rival_concept",
				"reply_id": "angry_leave" if will_leave2 else rid_w,
				"mood": "angry",
				"reply_text": String(lines.get("angry_leave" if will_leave2 else rid_w, "Hayır! Beni başka bir düşünürle karıştırıyorsun!")),
			}

	# 2. Filozofa ait herhangi bir söz, kavram, yöntem, eser veya isim geçti mi?
	if hit_count > 0:
		var matched_id: String = _best_choice_id(norm, choices)
		var pts: int = 4 if (hit_count >= 3 or norm.length() >= 48) else 2
		var target_lvl: int = clampi(stage_level + pts, 1, 4)
		var trig: String = STAGE_TRIGGERS[target_lvl]
		var reply_txt: String = String(persona.get("confirm_2" if target_lvl >= 4 else "confirm_1", ""))
		var rid_stage: String = "stage_4" if target_lvl >= 4 else ("stage_%d" % clampi(target_lvl, 1, 3))
		if lines.has(rid_stage):
			reply_txt = String(lines.get(rid_stage, reply_txt))
		return {
			"trigger": trig,
			"points": pts,
			"choice_id": matched_id if matched_id != "" else ("truth_%d" % target_lvl),
			"reply_id": rid_stage,
			"mood": "smile",
			"reply_text": reply_txt,
		}

	# 3. Genel soru veya selamlaşma: Asla "bana kendimi hatırlat" deme; doğrudan kendi felsefesini anlat
	return {
		"trigger": "chat",
		"points": 0,
		"choice_id": "",
		"reply_id": "",
		"mood": "thinking",
		"reply_text": String(persona.get("chat_reply", "Hakikati akıl ve sorgulamayla ararım.")),
	}


func _count_philosopher_hits(pid: StringName, norm: String, choices: Array) -> int:
	var hits: int = 0
	for item: Variant in choices:
		if item is Dictionary and bool((item as Dictionary).get("correct", false)):
			if _matches_choice(norm, item as Dictionary):
				hits += 1
	var persona: Dictionary = PERSONAS.get(pid, {})
	var kws: Array = persona.get("all_keywords", [])
	for kw: Variant in kws:
		var k: String = _normalize_tr(String(kw))
		if k != "" and norm.contains(k):
			hits += 1
	return hits


func _best_choice_id(norm: String, choices: Array) -> String:
	for item: Variant in choices:
		if item is Dictionary and bool((item as Dictionary).get("correct", false)):
			if _matches_choice(norm, item as Dictionary):
				return String((item as Dictionary).get("id", ""))
	return "philosopher_quote"


func _matches_choice(norm_text: String, choice: Dictionary) -> bool:
	var label_norm: String = _normalize_tr(String(choice.get("label", "")))
	if label_norm != "" and norm_text.contains(label_norm):
		return true
	var kws: Array = choice.get("keywords", [])
	for kw: Variant in kws:
		var k: String = _normalize_tr(String(kw))
		if k != "" and norm_text.contains(k):
			return true
	return false


func _is_rival_concept(pid: StringName, norm: String) -> bool:
	if norm.contains("sofist") or norm.contains("para karsiligi") or norm.contains("safsata"):
		return true
	if pid == &"aristotle" and (norm.contains("magara") or norm.contains("golge") or norm.contains("ayri dunya")):
		return true
	if pid == &"socrates" and (norm.contains("dort element") or norm.contains("atom") or norm.contains("hazcilik")):
		return true
	if pid == &"plato" and (norm.contains("yalniz duyu") or norm.contains("atom") or norm.contains("materyalist")):
		return true
	return false


func _normalize_tr(s: String) -> String:
	var out: String = s.replace("İ", "i").replace("I", "i").replace("ı", "i").to_lower()
	var map := {
		"ş": "s", "Ş": "s", "ğ": "g", "Ğ": "g",
		"ü": "u", "Ü": "u", "ö": "o", "Ö": "o", "ç": "c", "Ç": "c",
		"î": "i", "Î": "i", "û": "u", "Û": "u", "â": "a", "Â": "a",
		"'": "", "’": "", "\"": "", "-": " ",
	}
	for k: String in map.keys():
		out = out.replace(k, String(map[k]))
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


func _resolve_llm_config() -> Dictionary:
	var gemini_key: String = OS.get_environment("GEMINI_API_KEY").strip_edges()
	var openai_key: String = OS.get_environment("OPENAI_API_KEY").strip_edges()
	var groq_key: String = OS.get_environment("GROQ_API_KEY").strip_edges()
	var ollama_host: String = OS.get_environment("OLLAMA_HOST").strip_edges()

	if gemini_key == "" and openai_key == "" and groq_key == "" and FileAccess.file_exists(KEY_FILE):
		var f := FileAccess.open(KEY_FILE, FileAccess.READ)
		if f != null:
			var raw: String = f.get_as_text().strip_edges()
			if raw.begins_with("AIza") or raw.begins_with("AQ."):
				gemini_key = raw
			elif raw.begins_with("gsk_"):
				groq_key = raw
			elif raw.begins_with("sk-"):
				openai_key = raw
			elif raw.begins_with("http"):
				ollama_host = raw

	if gemini_key != "":
		return {
			"provider": "gemini",
			"url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=" + gemini_key,
			"headers": PackedStringArray(["Content-Type: application/json"]),
		}
	if groq_key != "":
		return {
			"provider": "openai",
			"model": "llama-3.3-70b-versatile",
			"url": "https://api.groq.com/openai/v1/chat/completions",
			"headers": PackedStringArray(["Authorization: Bearer " + groq_key, "Content-Type: application/json"]),
		}
	if openai_key != "":
		return {
			"provider": "openai",
			"model": "gpt-4o-mini",
			"url": "https://api.openai.com/v1/chat/completions",
			"headers": PackedStringArray(["Authorization: Bearer " + openai_key, "Content-Type: application/json"]),
		}
	if ollama_host != "":
		var base: String = ollama_host if ollama_host.begins_with("http") else ("http://" + ollama_host)
		return {
			"provider": "ollama",
			"model": OS.get_environment("OLLAMA_MODEL") if OS.get_environment("OLLAMA_MODEL") != "" else "llama3.1",
			"url": base.trim_suffix("/") + "/api/chat",
			"headers": PackedStringArray(["Content-Type: application/json"]),
		}
	return {}


func _send_llm_request(cfg: Dictionary, ctx: Dictionary) -> void:
	var pid: StringName = ctx["philosopher_id"]
	var persona: Dictionary = PERSONAS.get(pid, PERSONAS[&"socrates"])

	var sys_prompt: String = (
		"Sen %s'sin (%s). Mevcut hatırlama aşaması: %d/4.\n"
		+ "Oyuncu seninle konuşuyor.\n"
		+ "KESİN KURALLAR:\n"
		+ "1. Oyuncu sana ait HERHANGİ BİR söz, alıntı, ilke, yöntem, eser, kavram veya senin adını/kimliğini söylediyse KESİNLİKLE trigger='correct' döndür!\n"
		+ "2. Oyuncu senin meşhur bir sözünü veya birden fazla kavramını doğru söylediyse points=4 (tek kavram söylediyse points=2) ver ki doğrudan sonuca ulaşılsın.\n"
		+ "3. Oyuncu senin felsefene tamamen zıt/rakip bir iddia söylediyse (ör. Sokrates'e sofist/materyalist demek) trigger='wrong' ve points=0 döndür.\n"
		+ "4. Oyuncu sadece 'merhaba/nasılsın/kimsin' dediyse trigger='chat' döndür ve kendi temel sözlerini/ilkelerini doğrudan söyle.\n"
		+ "5. ASLA 'bana kendimi hatırlat' veya 'bana fikirlerimi hatırlat' DEME! Doğrudan filozof olarak o sözü onaylayıp sahiplen.\n"
		+ "6. reply_text Türkçe, birinci tekil şahıs ve EN FAZLA 90 karakter olsun.\n"
		+ "Yalnızca geçerli JSON döndür: {\"trigger\":\"correct|wrong|chat\",\"points\":2,\"mood\":\"smile|thinking|angry\",\"reply_text\":\"...\"}"
	) % [
		persona.get("name", "Filozof"),
		persona.get("role", ""),
		int(ctx["stage_level"]),
	]

	var provider: String = String(cfg.get("provider", ""))
	var body_str: String = ""
	if provider == "gemini":
		body_str = JSON.stringify({
			"systemInstruction": {"parts": [{"text": sys_prompt}]},
			"contents": [{"role": "user", "parts": [{"text": String(ctx["user_text"])}]}],
			"generationConfig": {"responseMimeType": "application/json", "temperature": 0.25},
		})
	elif provider == "openai":
		body_str = JSON.stringify({
			"model": cfg.get("model", "gpt-4o-mini"),
			"response_format": {"type": "json_object"},
			"temperature": 0.25,
			"messages": [
				{"role": "system", "content": sys_prompt},
				{"role": "user", "content": String(ctx["user_text"])},
			],
		})
	elif provider == "ollama":
		body_str = JSON.stringify({
			"model": cfg.get("model", "llama3.1"),
			"stream": false,
			"format": "json",
			"messages": [
				{"role": "system", "content": sys_prompt},
				{"role": "user", "content": String(ctx["user_text"])},
			],
		})

	var err: int = _http.request(String(cfg["url"]), cfg["headers"], HTTPClient.METHOD_POST, body_str)
	if err != OK:
		_busy = false
		response_ready.emit(ctx["fallback"])


func _on_llm_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _busy:
		return
	_busy = false
	var fallback: Dictionary = _pending_context.get("fallback", {})
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		response_ready.emit(fallback)
		return

	var raw_text: String = body.get_string_from_utf8()
	var outer: Variant = JSON.parse_string(raw_text)
	if not (outer is Dictionary):
		response_ready.emit(fallback)
		return

	var od := outer as Dictionary
	var content_json: String = ""
	if od.has("candidates"):
		var cands: Array = od.get("candidates", [])
		if not cands.is_empty():
			var parts: Array = cands[0].get("content", {}).get("parts", [])
			for idx in range(parts.size() - 1, -1, -1):
				var p: Variant = parts[idx]
				if p is Dictionary and not bool((p as Dictionary).get("thought", false)):
					var t: String = String((p as Dictionary).get("text", "")).strip_edges()
					if t != "":
						content_json = t
						break
	elif od.has("choices"):
		var chs: Array = od.get("choices", [])
		if not chs.is_empty():
			content_json = String(chs[0].get("message", {}).get("content", ""))
	elif od.has("message"):
		content_json = String(od.get("message", {}).get("content", ""))

	var i0: int = content_json.find("{")
	var i1: int = content_json.rfind("}")
	if i0 >= 0 and i1 > i0:
		content_json = content_json.substr(i0, i1 - i0 + 1)

	var inner: Variant = JSON.parse_string(content_json)
	if not (inner is Dictionary):
		response_ready.emit(fallback)
		return

	var idict := inner as Dictionary
	var llm_trig: String = _safe_str(idict.get("trigger"), "chat")
	var fb_trig: String = _safe_str(fallback.get("trigger"), "chat")
	var llm_pts: int = int(idict.get("points", 2 if llm_trig in ["stir", "glimmer", "dawn", "recalled", "correct"] else 0))
	var fb_pts: int = int(fallback.get("points", 0))

	# Yerel analiz filozofa ait doğru söz/kavram yakaladıysa LLM asla bunu "chat"e düşüremez
	var final_trig: String = llm_trig
	var final_pts: int = maxi(llm_pts, fb_pts)
	if fb_trig in ["stir", "glimmer", "dawn", "recalled", "correct"]:
		final_trig = "correct"
		final_pts = maxi(final_pts, 2)
	elif llm_trig in ["stir", "glimmer", "dawn", "recalled", "correct"]:
		final_trig = "correct"
		final_pts = maxi(final_pts, 2)

	var mood: String = _safe_str(idict.get("mood"), _safe_str(fallback.get("mood"), "smile"))
	var reply_text: String = _safe_str(idict.get("reply_text"), _safe_str(fallback.get("reply_text"), "")).strip_edges()
	var norm_reply: String = _normalize_tr(reply_text)
	if reply_text == "" or norm_reply.contains("hatirlat"):
		reply_text = _safe_str(fallback.get("reply_text"), "")
	if reply_text.length() > 95:
		reply_text = reply_text.substr(0, 92) + "…"

	response_ready.emit({
		"trigger": final_trig,
		"points": final_pts,
		"choice_id": _safe_str(idict.get("choice_id"), _safe_str(fallback.get("choice_id"), "llm_match")),
		"reply_id": "",
		"mood": mood,
		"reply_text": reply_text,
	})


func _safe_str(val: Variant, default_val: String = "") -> String:
	if val == null:
		return default_val
	return String(val)
