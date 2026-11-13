class_name PhilosopherBrain
extends Node
## Filozof LLM ve Diyalog Motoru (Sokrates, Platon, Aristoteles/Aristo, Epiküros,
## el-Kindî, el-Fârâbî, İbn Sînâ, İbn Rüşd).
##
## Oyuncunun yazdığı veya mikrofondan söylediği serbest Türkçe cümleyi değerlendirir:
## 1. Ortamda GEMINI_API_KEY, OPENAI_API_KEY, GROQ_API_KEY, user://llm_key.txt veya
##    yerel Ollama (127.0.0.1:11434) varsa gerçek LLM üzerinden filozofun kimliğiyle
##    (ör. Aristoteles veya Sokrates) canlı JSON karar + replik üretir.
## 2. Anahtar yoksa veya çevrimdışıysa Türkçe kavram/kök analizi + filozofa özgü
##    karakter üslubu motoruyla ("Aristo", "Sokrates" vb.) anında yanıt verir.

signal response_ready(result: Dictionary)
## result = {
##   "verdict": "correct" | "wrong" | "chat" | "already",
##   "choice_id": String,
##   "reply_id": String,      # varsa önceden kaydedilmiş ses anahtarı (stage_1..4, wrong_sofist vb.)
##   "reply_text": String,    # filozofun Türkçe yanıtı (<= 95 karakter)
## }

const PERSONAS := {
	&"socrates": {
		"name": "Sokrates",
		"role": "Atina agorasında yalınayak dolaşan, hiçbir şey bilmediğini bilen, sorularla hakikati doğurtan (maiotik) ve erdemi bilgiyle bir tutan filozof.",
		"who_reply": "Atina taşlarında yürüyen, gösterişsiz bir sorgulayıcıyım; bana sorularımı hatırlat.",
		"teacher_reply": "Ben kimsenin paralı hocası olmadım; ama genç Platon konuşmalarımı hep dinlerdi.",
		"method_reply": "Annem الفينarete ebeydi; ben de sorularımla zihinlerdeki hakikati doğurturum.",
	},
	&"plato": {
		"name": "Platon",
		"role": "Sokrates'in öğrencisi, Akademia'nın kurucusu, mağara alegorisi ve değişmeyen İdealar dünyası filozofu.",
		"who_reply": "Hocam Sokrates'in izinde, görünen gölgelerin ardındaki asıl İdeaları arayan bir düşünürüm.",
		"teacher_reply": "Hocam Sokrates'ti; öğrencim Aristoteles ise Akademia'nın en keskin zekâsıydı.",
		"method_reply": "Duyular yanıltır dostum; akıl gözüyle değişmeyen formlara yükselmeliyiz.",
	},
	&"aristotle": {
		"name": "Aristoteles",
		"role": "Stagiralı Aristoteles (Aristo). Platon'un öğrencisi, Lykeion (Peripatos) kurucusu, mantığın (Organon), madde-form birliğinin, dört nedenin ve altın orta ahlakının filozofu.",
		"who_reply": "Stagiralı bir doğa ve mantık araştırmacısıyım; Lykeion revaklarında yürüyerek düşünürüm.",
		"teacher_reply": "Platon'u severim ama hakikati daha çok severim; formlar bulutlarda değil nesnenin içindedir.",
		"method_reply": "Önce gözlem yapar, sonra kıyas ve dört nedenle varlığın ilkesini temellendiririm.",
	},
	&"epicurus": {
		"name": "Epiküros",
		"role": "Bahçe okulunun kurucusu; atomculuk, ölüm korkusunun yersizliği, acısızlık ve ruh dinginliği (ataraksia) filozofu.",
		"who_reply": "Gürültülü siyasetten uzak, dostlarıyla Bahçe'de ruh dinginliğini arayan bir düşünürüm.",
		"teacher_reply": "Demokritos'un atomlarını okudum ama determinizme özgür irade sapmasını ekledim.",
		"method_reply": "Korkuları doğa bilgisiyle dağıtır, ölçülü ve sade yaşamla ataraksia'ya ulaşırım.",
	},
	&"kindi": {
		"name": "el-Kindî",
		"role": "Bağdat Beytü'l-Hikme bilgini, İslam felsefesinin kurucusu (Filozofü'l-Arab), akıl-vahiy uyumu ve İlk Felsefe yazarı.",
		"who_reply": "Bağdat'ta Yunan mirasını Arapçaya kazandıran, hakikati her kaynakta arayan bir filozofum.",
		"teacher_reply": "Kadim filozofların eserlerini inceledim; hakikat nereden gelirse gelsin insanlığın ortak malıdır.",
		"method_reply": "Matematiksel kanıt ve akılla varlığın ilk nedenini ve evrenin sonluluğunu incelerim.",
	},
	&"farabi": {
		"name": "el-Fârâbî",
		"role": "Türkistan doğumlu Muallim-i Sânî (İkinci Öğretmen), İlimlerin Sayımı, sudûr kuramı ve Erdemli Şehir (el-Medînetü'l-Fâzıla) filozofu.",
		"who_reply": "Aristoteles'ten sonra mantığı yeniden kuran, kanun çalan ve Erdemli Şehir'i düşleyen bir filozofum.",
		"teacher_reply": "İlk öğretmen Aristoteles'in eserlerini defalarca okudum; bana İkinci Öğretmen derler.",
		"method_reply": "Mantıkla kavramları tartar, bilimleri sınıflandırır ve toplumu uyum içinde kurgularım.",
	},
	&"ibn_sina": {
		"name": "İbn Sînâ",
		"role": "Şeyhü'r-Reîs İbn Sînâ (Avicenna). Uçan Adam düşünce deneyi, Zorunlu-Mümkün varlık ayrımı, Kitâbü'ş-Şifâ ve el-Kânûn fi't-Tıbb müellifi.",
		"who_reply": "Hem hekim hem metafizikçiyim; varlığı Zorunlu ve Mümkün diye ayıran Şeyhü'r-Reîs'im.",
		"teacher_reply": "Aristoteles'in Metafizik'ini Fârâbî'nin şerhiyle çözdüm; üstüne kendi burhanımı kurdum.",
		"method_reply": "Boşlukta asılı Uçan Adam deneyiyle özbilinci, burhanla Zorunlu Varlık'ı kanıtlarım.",
	},
	&"ibn_rushd": {
		"name": "İbn Rüşd",
		"role": "Kurtuba kadısı ve hekimi, Aristoteles'in en büyük şârihi (Commentator), Faslü'l-Makâl ve hakikatin birliği filozofu.",
		"who_reply": "Endülüs Kurtuba'da Aristoteles'i şerh eden, aklın ve vahyin süt kardeş olduğunu savunan düşünürüm.",
		"teacher_reply": "Aristoteles insan aklının zirvesidir; ben onun eserlerini sonradan eklenen sislerden arındırdım.",
		"method_reply": "Hakikat hakikate ters düşmez; burhan yöntemiyle doğadaki nedenselliği savunurum.",
	},
}

const KEY_FILE := "user://llm_key.txt"

var _http := HTTPRequest.new()
var _busy: bool = false
var _pending_context: Dictionary = {}


func _ready() -> void:
	add_child(_http)
	_http.timeout = 8.0
	_http.request_completed.connect(_on_llm_completed)


## Oyuncunun serbest mesajını değerlendirir ve response_ready sinyali yayar.
func ask(
	philosopher_id: StringName,
	user_text: String,
	stage_level: int,
	used_choices: Array[String],
	choices: Array,
	lines: Dictionary
) -> void:
	var clean: String = user_text.strip_edges()
	if clean == "":
		return

	# 1. Önce yerel kavram eşleştiriciyi çalıştır (kesin bir doğru/yanlış kavram yakalandıysa anında bilinsin)
	var local_eval: Dictionary = _evaluate_locally(philosopher_id, clean, stage_level, used_choices, choices, lines)

	# Eğer yerel motor kesin bir doğru veya yanlış kavram yakaladıysa VE LLM anahtarı yoksa doğrudan dön;
	# LLM anahtarı varsa veya mesaj serbest bir soru/sohbet ise LLM'e de sorabiliriz.
	var llm_cfg: Dictionary = _resolve_llm_config()
	if llm_cfg.is_empty() or _busy:
		response_ready.emit(local_eval)
		return

	_busy = true
	_pending_context = {
		"philosopher_id": philosopher_id,
		"user_text": clean,
		"stage_level": stage_level,
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
	used_choices: Array[String],
	choices: Array,
	lines: Dictionary
) -> Dictionary:
	var norm: String = _normalize_tr(text)

	# Önce yanlış / rakip iddiaları kontrol et
	for item: Variant in choices:
		if not (item is Dictionary):
			continue
		var c := item as Dictionary
		if bool(c.get("correct", false)):
			continue
		if _matches_choice(norm, c):
			var rid: String = String(c.get("reply", "wrong_sofist"))
			return {
				"verdict": "wrong",
				"choice_id": String(c.get("id", "wrong")),
				"reply_id": rid,
				"reply_text": String(lines.get(rid, "Hayır! Bu iddia benim felsefeme tamamen aykırı!")),
			}

	# Doğru fikirleri kontrol et
	for item: Variant in choices:
		if not (item is Dictionary):
			continue
		var c := item as Dictionary
		if not bool(c.get("correct", false)):
			continue
		if _matches_choice(norm, c):
			var cid: String = String(c.get("id", ""))
			if used_choices.has(cid):
				return {
					"verdict": "already",
					"choice_id": cid,
					"reply_id": "",
					"reply_text": "Evet dostum, bunu az önce hatırladım; şimdi diğer halkayı bulmama yardım et.",
				}
			var next_lvl: int = clampi(stage_level + 1, 1, 4)
			var rid_ok: String = StringName("stage_%d" % next_lvl)
			return {
				"verdict": "correct",
				"choice_id": cid,
				"reply_id": rid_ok,
				"reply_text": String(lines.get(rid_ok, "")),
			}

	# Başka bir filozofun kavramını yanlışlıkla bu filozofa söyleme kontrolü
	if _is_rival_concept(pid, norm):
		var rid_w: String = "wrong_empedokles" if lines.has("wrong_empedokles") and (norm.contains("element") or norm.contains("ates") or norm.contains("atom")) else "wrong_sofist"
		return {
			"verdict": "wrong",
			"choice_id": "rival_concept",
			"reply_id": rid_w,
			"reply_text": String(lines.get(rid_w, "Hayır! Beni başka bir düşünürle karıştırıyorsun!")),
		}

	# Sohbet / Soru / İpucu yanıtı (öfke artırmaz, filozof karakteriyle konuşur)
	var persona: Dictionary = PERSONAS.get(pid, PERSONAS[&"socrates"])
	if norm.contains("kimsin") or norm.contains("adin ne") or norm.contains("sen kim") or norm.contains("kendini tanit"):
		return {
			"verdict": "chat",
			"choice_id": "",
			"reply_id": "",
			"reply_text": String(persona.get("who_reply", String(lines.get("chat_hint", "")))),
		}
	if norm.contains("hocan") or norm.contains("ogretmen") or norm.contains("ogrencin") or norm.contains("platon") or norm.contains("sokrates"):
		return {
			"verdict": "chat",
			"choice_id": "",
			"reply_id": "",
			"reply_text": String(persona.get("teacher_reply", String(lines.get("chat_hint", "")))),
		}
	if norm.contains("yontem") or norm.contains("nasil dusun") or norm.contains("felsefen") or norm.contains("ne yapiyor"):
		return {
			"verdict": "chat",
			"choice_id": "",
			"reply_id": "",
			"reply_text": String(persona.get("method_reply", String(lines.get("chat_hint", "")))),
		}
	if norm.contains("merhaba") or norm.contains("selam") or norm.contains("hey") or norm.contains("nasilsin"):
		return {
			"verdict": "chat",
			"choice_id": "",
			"reply_id": "",
			"reply_text": "Selam dostum… Zihnim hâlâ sisli; bana temel fikirlerimi hatırlatır mısın?",
		}

	# Sıradaki hatırlanmamış fikre göre doğal ipucu ver
	var next_label: String = _next_unremembered_label(choices, used_choices)
	if next_label != "":
		return {
			"verdict": "chat",
			"choice_id": "",
			"reply_id": "",
			"reply_text": "Sözlerin tanıdık geliyor… Özellikle '%s' üzerine ne düşündüğümü hatırlat." % next_label,
		}
	return {
		"verdict": "chat",
		"choice_id": "",
		"reply_id": "chat_hint",
		"reply_text": String(lines.get("chat_hint", "Bana ana fikirlerimi kendi cümlelerinle hatırlat.")),
	}


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


func _next_unremembered_label(choices: Array, used_choices: Array[String]) -> String:
	for item: Variant in choices:
		if not (item is Dictionary):
			continue
		var c := item as Dictionary
		if bool(c.get("correct", false)) and not used_choices.has(String(c.get("id", ""))):
			return String(c.get("label", ""))
	return ""


func _normalize_tr(s: String) -> String:
	var out: String = s.to_lower()
	var map := {
		"ı": "i", "İ": "i", "ş": "s", "Ş": "s", "ğ": "g", "Ğ": "g",
		"ü": "u", "Ü": "u", "ö": "o", "Ö": "o", "ç": "c", "Ç": "c",
		"î": "i", "Î": "i", "û": "u", "Û": "u", "â": "a", "Â": "a",
	}
	for k: String in map.keys():
		out = out.replace(k, String(map[k]))
	return out


func _resolve_llm_config() -> Dictionary:
	var gemini_key: String = OS.get_environment("GEMINI_API_KEY").strip_edges()
	var openai_key: String = OS.get_environment("OPENAI_API_KEY").strip_edges()
	var groq_key: String = OS.get_environment("GROQ_API_KEY").strip_edges()
	var ollama_host: String = OS.get_environment("OLLAMA_HOST").strip_edges()

	if gemini_key == "" and openai_key == "" and groq_key == "" and FileAccess.file_exists(KEY_FILE):
		var f := FileAccess.open(KEY_FILE, FileAccess.READ)
		if f != null:
			var raw: String = f.get_as_text().strip_edges()
			if raw.begins_with("AIza"):
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
			"url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + gemini_key,
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
	var choices: Array = ctx["choices"]
	var used: Array = ctx["used_choices"]

	var remaining_desc: Array[String] = []
	var wrong_desc: Array[String] = []
	for item: Variant in choices:
		if not (item is Dictionary):
			continue
		var c := item as Dictionary
		var cid: String = String(c.get("id", ""))
		var lbl: String = String(c.get("label", ""))
		if bool(c.get("correct", false)):
			if not used.has(cid):
				remaining_desc.append("%s (%s)" % [cid, lbl])
		else:
			wrong_desc.append("%s (%s)" % [cid, lbl])

	var sys_prompt: String = (
		"Sen %s'sin (%s). Hafızan sisli (Aşama %d/4). "
		+ "Oyuncu sana fikirlerini hatırlatmaya çalışıyor.\n"
		+ "Henüz hatırlamadığın doğru fikirler: [%s]\n"
		+ "Senin felsefene ters/yanlış iddialar: [%s]\n"
		+ "Kurallar:\n"
		+ "1. Oyuncunun mesajı doğru fikirlerden birini anlatıyorsa verdict='correct' ve choice_id o fikrin kodu olsun.\n"
		+ "2. Oyuncunun mesajı senin felsefene ters bir iddiaysa verdict='wrong' olsun ve itiraz et.\n"
		+ "3. Oyuncu soru soruyor veya sohbet ediyorsa verdict='chat' olsun ve kendi filozof üslubunla ipucu ver.\n"
		+ "4. reply_text Türkçe, birinci tekil şahıs ve EN FAZLA 90 karakter olsun.\n"
		+ "Yalnızca geçerli JSON döndür: {\"verdict\":\"correct|wrong|chat\",\"choice_id\":\"...\",\"reply_text\":\"...\"}"
	) % [
		persona.get("name", "Filozof"),
		persona.get("role", ""),
		int(ctx["stage_level"]),
		", ".join(remaining_desc),
		", ".join(wrong_desc),
	]

	var provider: String = String(cfg.get("provider", ""))
	var body_str: String = ""
	if provider == "gemini":
		body_str = JSON.stringify({
			"systemInstruction": {"parts": [{"text": sys_prompt}]},
			"contents": [{"role": "user", "parts": [{"text": String(ctx["user_text"])}]}],
			"generationConfig": {"responseMimeType": "application/json", "temperature": 0.35},
		})
	elif provider == "openai":
		body_str = JSON.stringify({
			"model": cfg.get("model", "gpt-4o-mini"),
			"response_format": {"type": "json_object"},
			"temperature": 0.35,
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
			if not parts.is_empty():
				content_json = String(parts[0].get("text", ""))
	elif od.has("choices"):
		var chs: Array = od.get("choices", [])
		if not chs.is_empty():
			content_json = String(chs[0].get("message", {}).get("content", ""))
	elif od.has("message"):
		content_json = String(od.get("message", {}).get("content", ""))

	var inner: Variant = JSON.parse_string(content_json)
	if not (inner is Dictionary):
		response_ready.emit(fallback)
		return

	var idict := inner as Dictionary
	var verdict: String = String(idict.get("verdict", fallback.get("verdict", "chat")))
	var cid: String = String(idict.get("choice_id", fallback.get("choice_id", "")))
	var reply_text: String = String(idict.get("reply_text", fallback.get("reply_text", ""))).strip_edges()
	if reply_text.length() > 95:
		reply_text = reply_text.substr(0, 92) + "…"
	if reply_text == "":
		reply_text = String(fallback.get("reply_text", ""))

	response_ready.emit({
		"verdict": verdict,
		"choice_id": cid if cid != "" else String(fallback.get("choice_id", "")),
		"reply_id": "",
		"reply_text": reply_text,
	})
