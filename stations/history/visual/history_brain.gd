class_name HistoryBrain
extends Node
## Tarih Meydanı Arka Plan LLM ve Durum Tetikleyici Motoru (Mete Han, Sultan Alparslan,
## Fatih Sultan Mehmed, Kanuni Sultan Süleyman, Mimar Sinan, Mustafa Kemal Atatürk).
##
## Kullanıcıya çoktan seçmeli şık verilmez; oyuncunun yazdığı ya da mikrofondan söylediği
## tarihî ilkeler, antlaşmalar, fermanlar ve sözler Gemini 3.5 Flash Lite tarafından çözümlenir.

signal response_ready(result: Dictionary)

const STAGE_TRIGGERS := ["", "stir", "glimmer", "dawn", "recalled"]

const PERSONAS := {
	&"mete_han": {
		"name": "Mete Han",
		"role": "Asya Hun Devleti hükümdarı. MÖ 209 Onlu askeri teşkilatın kurucusu, 'Toprak milletin köküdür' ilkesiyle vatan toprağını vermeyen ve Türk boylarını tek bayrakta toplayan ulu kağan.",
		"all_keywords": [
			"mete han", "mete", "oguz kagan", "asya hun", "onlu teskilat", "onbasi", "yuzbasi", "binbasi",
			"tumen", "kara kuvvetleri", "209", "toprak", "vatan", "milletin koku", "corak", "devletin temeli",
			"otuken", "kurultay", "tore", "turk boylari", "islikli ok", "cin", "ipek yolu", "birlik"
		],
		"confirm_1": "Evet! Ordumu onlu teşkilatla kurdum ve atımı versem de bir karış vatan toprağını vermedim!",
		"confirm_2": "Ötüken otağında töre yeniden canlandı: Toprak milletin köküdür, Türk boyları tek bayrak altındadır!",
		"chat_reply": "Ötüken bozkırında at koştururum; töremiz açık, ordumuz onlu teşkilatla yenilmezdir.",
	},
	&"alparslan": {
		"name": "Sultan Alparslan",
		"role": "Büyük Selçuklu Hükümdarı. 26 Ağustos 1071 Malazgirt Zaferi ile Anadolu'nun kapılarını Türklere açan, beyaz kefenini giyip ordusunun önüne geçen ulu sultan.",
		"all_keywords": [
			"alparslan", "alp arslan", "malazgirt", "1071", "26 agustos", "anadolu", "kapi", "beyaz kefen",
			"romen diyojen", "turan taktigi", "hilal", "ani", "ebul feth", "nizamulmulk", "nizamiye",
			"selcuklu", "kilic hakki", "vatan"
		],
		"confirm_1": "Evet! 1071 Malazgirt Ovası'nda beyaz kefenimi giydim ve Anadolu'nun kapılarını açtık!",
		"confirm_2": "Size öyle bir vatan aldım ki ebediyen sizin olacaktır; Nizamülmülk ile ilmi ve adaleti kurduk!",
		"chat_reply": "Malazgirt'te cuma namazından sonra atımın kuyruğunu bağlayıp ordumun başına geçtim.",
	},
	&"fatih": {
		"name": "Fatih Sultan Mehmed",
		"role": "Osmanlı Padişahı (II. Mehmed). 1453 İstanbul'un fethi, gemilerin karadan Haliç'e indirilmesi, Şahi topları, Sahn-ı Seman ve Kanunnâme-i Âl-i Osman bânisi.",
		"all_keywords": [
			"fatih", "mehmed", "istanbul", "fetih", "1453", "29 mayis", "sahi", "top", "halic",
			"gemileri karadan", "orta cag", "yeni cag", "sahn", "seman", "kanunname", "avni", "ali kuscu",
			"topkapi", "ya ben istanbulu", "imkansiz"
		],
		"confirm_1": "Evet! Şahi toplarıyla surları dövdük, gemileri karadan Haliç'e indirip İstanbul'u fethettik!",
		"confirm_2": "İmkânsız diye bir şey yoktur; Orta Çağ kapandı, Sahn-ı Seman ve adaletle cihan devleti kuruldu!",
		"chat_reply": "Bizim gücümüzün ulaştığı yerlere onların hayalleri bile ulaşamaz.",
	},
	&"kanuni": {
		"name": "Kanuni Sultan Süleyman",
		"role": "Osmanlı Padişahı. 46 yıllık saltanatında adalet ve kanun düzeni, Mohaç Meydan Muharebesi, Preveze Deniz Zaferi ve Süleymaniye bânisi.",
		"all_keywords": [
			"kanuni", "suleyman", "kanun", "muhtesem", "adalet", "mohac", "preveze", "barbaros",
			"akdeniz", "rodos", "belgrad", "zigetvar", "suleymaniye", "muhibbi", "nefes sihhat", "devlet"
		],
		"confirm_1": "Evet! Ülkemde adalet ve kanunla hükmettiğim için bana Kanûnî dediler; Mohaç'ta zafer kazandık!",
		"confirm_2": "Halk içinde muteber bir nesne yok devlet gibi, olmaya devlet cihanda bir nefes sıhhat gibi!",
		"chat_reply": "Kılıcımız adalet ve nizam içindir; kanundan ve haktan kıl payı ayrılmayız.",
	},
	&"mimar_sinan": {
		"name": "Mimar Sinan",
		"role": "Osmanlı Başmimarı (Koca Sinan). Şehzade (çıraklık), Süleymaniye (kalfalık) ve Selimiye (ustalık) camileri, kubbe akustiği ve su kemerleri üstadı.",
		"all_keywords": [
			"mimar sinan", "sinan", "koca sinan", "sehzade", "suleymaniye", "selimiye", "ciraklik",
			"kalfalik", "ustalik", "edirne", "kubbe", "akustik", "kup", "su kemeri", "kirksesme", "pergel"
		],
		"confirm_1": "Evet! Şehzade çıraklık, Süleymaniye kalfalık, Edirne Selimiye ise ustalık eserimdir!",
		"confirm_2": "Her taş yerine oturdu: Pergelin sabit ayağı ilim, dönen ayağıyla cihana asırlarca duracak eserler diktik!",
		"chat_reply": "Pergelimle taşı ve kubbeyi teraziye koyarım; Selimiye'de tek kubbeyle mekân birliğini kurdum.",
	},
	&"ataturk": {
		"name": "Mustafa Kemal Atatürk",
		"role": "Türkiye Cumhuriyeti'nin kurucusu, Kurtuluş Savaşı Başkomutanı. MEB 8. Sınıf İnkılap Tarihi (LGS · İTA.8.2.2). 19 Mayıs 1919 Samsun, Amasya Genelgesi, Erzurum ve Sivas Kongreleri, I. TBMM'nin açılışı ve Lozan Barış Antlaşması.",
		"all_keywords": [
			"ataturk", "mustafa kemal", "kemal pasa", "pasa", "19 mayis", "samsun", "amasya", "genelge", "tamim",
			"azim ve karari", "gerekce", "yontem", "vatanin butunlugu", "bagimsizlik tehlikede",
			"erzurum", "sivas", "kongre", "milli sinirlar", "vatan bir butundur", "parcalanamaz",
			"anadolu ve rumeli", "mudafaa-i hukuk", "armhc", "temsil heyeti", "irade-i milliye",
			"manda ret", "ya istiklal ya olum", "23 nisan", "1920", "tbmm", "meclis", "egemenlik",
			"milletindir", "hakimiyet bila kaydu sart", "milli irade", "kurucu meclis",
			"sakarya", "buyuk taarruz", "baskomutan", "dumlupinar", "akdeniz",
			"lozan", "baris antlasmasi", "kapitulasyon", "kapitulasyonlar", "tam bagimsizlik",
			"cumhuriyet", "29 ekim", "misak-i milli", "canakkale"
		],
		"confirm_1": "Evet! Amasya Genelgesi ile milletin istiklalini yine milletin azim ve kararı kurtaracaktır dedik!",
		"confirm_2": "Egemenlik kayıtsız şartsız milletindir; Türkiye Cumhuriyeti ilelebet payidar kalacaktır!",
		"chat_reply": "Milletin bağımsızlığı ve kayıtsız şartsız egemenliği her şeyin üstündedir; parolamız ya istiklal ya ölümdür.",
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
	var persona: Dictionary = PERSONAS.get(pid, PERSONAS[&"mete_han"])

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

	# 2. Lidere ait herhangi bir söz, kavram, belge veya ilke geçti mi?
	if hit_count > 0:
		var matched_id: String = _best_choice_id(norm, choices)
		var pts: int = 1
		var target_lvl: int = clampi(stage_level + pts, 1, 4)
		var trig: String = STAGE_TRIGGERS[target_lvl]
		var rid_stage: String = "stage_%d" % clampi(target_lvl, 1, 4)
		var reply_txt: String = String(lines.get(rid_stage, persona.get("confirm_2" if target_lvl >= 4 else "confirm_1", "")))
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
	var persona: Dictionary = PERSONAS.get(pid, PERSONAS[&"mete_han"])

	var sys_prompt: String = (
		"Sen Türk ve dünya tarihinin büyük şahsiyeti %s'sin (%s). Mevcut aşama: %d/4.\n"
		+ "Oyuncu seninle konuşuyor.\n"
		+ "KESİN KURALLAR:\n"
		+ "1. Oyuncu sana ait HERHANGİ BİR söz, zafer, kanun, antlaşma, ilke veya kimlik bilgisi verdiyse KESİNLİKLE trigger='correct' döndür!\n"
		+ "2. Oyuncu o aşamaya uygun tarihsel bir kararını, fermanını, zaferini veya ilkeni doğru söylediyse trigger='correct' ve points=1 döndür.\n"
		+ "3. Oyuncu senin tarihî vizyonuna tamamen zıt bir iddia söylediyse (ör. teslimiyet, mandacılık, Sevr) trigger='wrong' ve points=0 döndür.\n"
		+ "4. ASLA 'bana kendimi hatırlat' DEME! Doğrudan o dönemin lideri olarak sözü onayla.\n"
		+ "5. reply_text Türkçe, vakur/lider üslupta, birinci tekil şahıs ve EN FAZLA 90 karakter olsun.\n"
		+ "Yalnızca geçerli JSON döndür: {\"trigger\":\"correct|wrong|chat\",\"points\":1,\"mood\":\"smile|thinking|angry\",\"reply_text\":\"...\"}"
	) % [
		persona.get("name", "Lider"),
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
	var llm_pts: int = clampi(int(idict.get("points", 1)), 0, 1)
	var fb_pts: int = clampi(int(fallback.get("points", 0)), 0, 1)

	# Yerel analiz lidere ait doğru söz/kavram yakaladıysa LLM asla bunu "chat"e düşüremez
	var final_trig: String = llm_trig
	if fb_trig in ["stir", "glimmer", "dawn", "recalled", "correct"] or llm_trig in ["stir", "glimmer", "dawn", "recalled", "correct"]:
		final_trig = "correct"
	var final_pts: int = 1 if (final_trig in ["stir", "glimmer", "dawn", "recalled", "correct"]) else 0

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
