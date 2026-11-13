class_name PhilosopherBrain
extends Node
## Filozof Arka Plan LLM ve Durum Tetikleyici Motoru (Sokrates, Platon, Aristoteles, Epiküros,
## el-Kindî, el-Fârâbî, İbn Sînâ, İbn Rüşd).
##
## Kullanıcıya çoktan seçmeli şık gösterilmez. Kullanıcının yazdığı veya mikrofondan söylediği
## serbest cümle LLM'e (veya anahtar yoksa yerleşik semantik tetikleyiciye) gider ve şu JSON
## sözleşmesiyle sahnedeki animasyonu/aşamayı tetikler:
## {
##   "trigger": "stir" | "glimmer" | "dawn" | "recalled" | "wrong" | "angry_leave" | "chat",
##   "choice_id": String,     # eşleşen kavram kimliği
##   "reply_id": String,      # varsa önceden kaydedilmiş ses anahtarı (stage_1..4, wrong_sofist vb.)
##   "reply_text": String,    # filozofun Türkçe yanıtı (<= 95 karakter)
##   "mood": String           # neutral | confused | thinking | smile | angry
## }

signal response_ready(result: Dictionary)

const STAGE_TRIGGERS := ["", "stir", "glimmer", "dawn", "recalled"]

const PERSONAS := {
	&"socrates": {
		"name": "Sokrates",
		"role": "Atina agorasında dolaşan, 'bildiğim tek şey hiçbir şey bilmediğimdir' diyen, sorularla hakikati doğurtan (maiotik) ve erdemi bilgiyle bir tutan filozof.",
		"who_reply": "Atina taşlarında yürüyen bir sorgulayıcıyım; bilgelik iddiamı ve yöntemimi hatırlat.",
		"teacher_reply": "Ben paralı hoca olmadım; genç Platon konuşmalarımı dinlerdi.",
		"method_reply": "Annem ebeydi; ben de sorularımla zihinlerdeki doğruyu doğurturum.",
	},
	&"plato": {
		"name": "Platon",
		"role": "Sokrates'in öğrencisi, Akademia kurucusu, mağara alegorisi, değişmeyen İdealar dünyası, anamnesis (bilmek hatırlamaktır) ve filozof kral düşünürü.",
		"who_reply": "Görünen gölgelerin ardındaki değişmeyen İdeaları arayan Atinalı düşünürüm.",
		"teacher_reply": "Hocam Sokrates'ti; öğrencim Aristoteles ise Akademia'nın en keskin zekâsıydı.",
		"method_reply": "Mağaradaki gölgelerden çıkıp akıl gözüyle asıl formlara yükselmeliyiz.",
	},
	&"aristotle": {
		"name": "Aristoteles",
		"role": "Stagiralı Aristoteles (Aristo). Lykeion kurucusu; madde-form birliği (hylomorfizm), dört neden (maddi, formel, fail, ereksel), mantık/kıyas (Organon) ve altın orta (eudaimonia) filozofu.",
		"who_reply": "Stagiralı bir doğa ve mantık araştırmacısıyım; Lykeion revaklarında yürüyerek düşünürüm.",
		"teacher_reply": "Platon'u severim ama hakikati daha çok severim; formlar nesnenin içindedir.",
		"method_reply": "Önce doğayı gözlemler, sonra kıyas ve dört nedenle varlığı temellendiririm.",
	},
	&"epicurus": {
		"name": "Epiküros",
		"role": "Bahçe okulu kurucusu; atomlar ve boşluk, ölüm korkusunun yersizliği, acısızlık/ölçülü haz ve ruh dinginliği (ataraksia) filozofu.",
		"who_reply": "Dostlarıyla Bahçe'de korkulardan arınmış ruh dinginliğini arayan bir düşünürüm.",
		"teacher_reply": "Demokritos'un atomlarını inceledim ama özgür irade sapmasını ekledim.",
		"method_reply": "Doğa bilgisiyle ölüm korkusunu yener, sade yaşamla ataraksia'ya ulaşırım.",
	},
	&"kindi": {
		"name": "el-Kindî",
		"role": "Bağdat Beytü'l-Hikme bilgini, İslam felsefesinin kurucusu; hakikatin evrenselliği, akıl-vahiy uyumu, evrenin sonluluğu (hudûs) ve İlk Felsefe yazarı.",
		"who_reply": "Bağdat'ta kadim mirası inceleyen, hakikati her kaynakta arayan bir filozofum.",
		"teacher_reply": "Hakikat nereden gelirse gelsin insanlığın ortak malıdır.",
		"method_reply": "Matematiksel delil ve akılla varlığın ilk nedenini incelerim.",
	},
	&"farabi": {
		"name": "el-Fârâbî",
		"role": "Muallim-i Sânî (İkinci Öğretmen); mantık, İlimlerin Sayımı (İhsâü'l-Ulûm), sudûr/Etkin Akıl ve Erdemli Şehir (el-Medînetü'l-Fâzıla) filozofu.",
		"who_reply": "Aristoteles'ten sonra mantığı yeniden kuran ve Erdemli Şehir'i düşleyen bir filozofum.",
		"teacher_reply": "İlk öğretmen Aristoteles'tir; bana mantıktaki katkılarımla Muallim-i Sânî derler.",
		"method_reply": "Mantıkla kavramları tartar, bilimleri sınıflandırır ve toplumu uyumla kurarım.",
	},
	&"ibn_sina": {
		"name": "İbn Sînâ",
		"role": "Şeyhü'r-Reîs İbn Sînâ; Uçan Adam düşünce deneyi, Zorunlu-Mümkün varlık ayrımı, Kitâbü'ş-Şifâ ve el-Kânûn fi't-Tıbb müellifi.",
		"who_reply": "Hem hekim hem metafizikçiyim; varlığı Zorunlu ve Mümkün diye ayıran Şeyhü'r-Reîs'im.",
		"teacher_reply": "Aristoteles'in Metafizik'ini Fârâbî'nin şerhiyle çözdüm.",
		"method_reply": "Boşlukta asılı Uçan Adam deneyiyle özbilinci, burhanla Zorunlu Varlık'ı kanıtlarım.",
	},
	&"ibn_rushd": {
		"name": "İbn Rüşd",
		"role": "Kurtuba kadısı, Aristoteles'in büyük şârihi; 'hakikat hakikate ters düşmez' ilkesi, Faslü'l-Makâl ve nedensellik savunucusu.",
		"who_reply": "Kurtuba'da Aristoteles'i şerh eden, akıl ile vahyin süt kardeş olduğunu savunan düşünürüm.",
		"teacher_reply": "Aristoteles insan aklının zirvesidir; ben onun eserlerini şerh ettim.",
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
	if llm_cfg.is_empty() or _busy:
		response_ready.emit(local_eval)
		return

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
	used_choices: Array[String],
	choices: Array,
	lines: Dictionary
) -> Dictionary:
	var norm: String = _normalize_tr(text)

	# 1. Doğru fikirleri kontrol et (öncelikle yeni bir doğru kavram yakalandı mı?)
	for item: Variant in choices:
		if not (item is Dictionary):
			continue
		var c := item as Dictionary
		if not bool(c.get("correct", false)):
			continue
		if _matches_choice(norm, c):
			var cid: String = String(c.get("id", ""))
			if used_choices.has(cid):
				var next_hint: String = _next_unremembered_label(choices, used_choices)
				return {
					"trigger": "chat",
					"choice_id": cid,
					"reply_id": "",
					"mood": "smile",
					"reply_text": "Bunu az önce hatırladım dostum! Şimdi bana '%s' ilkesini anlat." % next_hint,
				}
			var next_lvl: int = clampi(stage_level + 1, 1, 4)
			var rid_ok: String = "stage_%d" % next_lvl
			var trig: String = STAGE_TRIGGERS[next_lvl]
			return {
				"trigger": trig,
				"choice_id": cid,
				"reply_id": rid_ok,
				"mood": "smile" if next_lvl >= 3 else "thinking",
				"reply_text": String(lines.get(rid_ok, "")),
			}

	# 2. Yanlış / rakip iddiaları kontrol et
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
			"choice_id": "rival_concept",
			"reply_id": "angry_leave" if will_leave2 else rid_w,
			"mood": "angry",
			"reply_text": String(lines.get("angry_leave" if will_leave2 else rid_w, "Hayır! Beni başka bir düşünürle karıştırıyorsun!")),
		}

	# 3. Sohbet / Soru / İpucu yanıtı
	var persona: Dictionary = PERSONAS.get(pid, PERSONAS[&"socrates"])
	if norm.contains("kimsin") or norm.contains("adin ne") or norm.contains("sen kim") or norm.contains("kendini tanit"):
		return {
			"trigger": "chat",
			"choice_id": "",
			"reply_id": "",
			"mood": "thinking",
			"reply_text": String(persona.get("who_reply", String(lines.get("chat_hint", "")))),
		}
	if norm.contains("hocan") or norm.contains("ogretmen") or norm.contains("ogrencin") or norm.contains("platon") or norm.contains("sokrates"):
		return {
			"trigger": "chat",
			"choice_id": "",
			"reply_id": "",
			"mood": "smile",
			"reply_text": String(persona.get("teacher_reply", String(lines.get("chat_hint", "")))),
		}
	if norm.contains("yontem") or norm.contains("nasil dusun") or norm.contains("felsefen") or norm.contains("ne yapiyor"):
		return {
			"trigger": "chat",
			"choice_id": "",
			"reply_id": "",
			"mood": "thinking",
			"reply_text": String(persona.get("method_reply", String(lines.get("chat_hint", "")))),
		}
	if norm.contains("merhaba") or norm.contains("selam") or norm.contains("hey") or norm.contains("nasilsin"):
		return {
			"trigger": "chat",
			"choice_id": "",
			"reply_id": "chat_hint",
			"mood": "confused",
			"reply_text": String(lines.get("chat_hint", "Selam dostum… Zihnim sisli; bana temel fikirlerimi hatırlatır mısın?")),
		}

	var next_label: String = _next_unremembered_label(choices, used_choices)
	if next_label != "":
		return {
			"trigger": "chat",
			"choice_id": "",
			"reply_id": "",
			"mood": "thinking",
			"reply_text": "Zihnimde bir şeyler dolaşıyor… Bana '%s' hakkındaki düşüncemi hatırlat." % next_label,
		}
	return {
		"trigger": "chat",
		"choice_id": "",
		"reply_id": "chat_hint",
		"mood": "thinking",
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
	var choices: Array = ctx["choices"]
	var used: Array = ctx["used_choices"]
	var next_lvl: int = clampi(int(ctx["stage_level"]) + 1, 1, 4)
	var next_trig: String = STAGE_TRIGGERS[next_lvl]

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
		"Sen %s'sin (%s). Hafızan sisli (Aşama %d/4, Öfke %.2f). "
		+ "Oyuncu sana fikirlerini serbest cümleyle hatırlatmaya çalışıyor.\n"
		+ "Henüz hatırlamadığın doğru fikirler: [%s]\n"
		+ "Senin felsefene ters/yanlış iddialar: [%s]\n"
		+ "Kurallar:\n"
		+ "1. Oyuncunun mesajı doğru fikirlerden birini anlatıyorsa trigger='%s' ve choice_id o fikrin kodu olsun.\n"
		+ "2. Oyuncunun mesajı senin felsefene ters bir iddiaysa trigger='wrong' (öfke >= 0.5 ise 'angry_leave') olsun.\n"
		+ "3. Oyuncu soru soruyor veya sohbet ediyorsa trigger='chat' olsun ve şık vermeden kendi filozof üslubunla ipucu sezdir.\n"
		+ "4. reply_text Türkçe, birinci tekil şahıs ve EN FAZLA 90 karakter olsun.\n"
		+ "Yalnızca geçerli JSON döndür: {\"trigger\":\"%s|wrong|angry_leave|chat\",\"choice_id\":\"...\",\"mood\":\"thinking|smile|angry|confused\",\"reply_text\":\"...\"}"
	) % [
		persona.get("name", "Filozof"),
		persona.get("role", ""),
		int(ctx["stage_level"]),
		float(ctx["anger_level"]),
		", ".join(remaining_desc),
		", ".join(wrong_desc),
		next_trig,
		next_trig,
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
	var trig: String = _safe_str(idict.get("trigger"), _safe_str(fallback.get("trigger"), "chat"))
	var cid: String = _safe_str(idict.get("choice_id"), _safe_str(fallback.get("choice_id"), ""))
	var mood: String = _safe_str(idict.get("mood"), _safe_str(fallback.get("mood"), "thinking"))
	var reply_text: String = _safe_str(idict.get("reply_text"), _safe_str(fallback.get("reply_text"), "")).strip_edges()
	if reply_text.length() > 95:
		reply_text = reply_text.substr(0, 92) + "…"
	if reply_text == "":
		reply_text = _safe_str(fallback.get("reply_text"), "")

	response_ready.emit({
		"trigger": trig,
		"choice_id": cid if cid != "" else _safe_str(fallback.get("choice_id"), ""),
		"reply_id": "",
		"mood": mood,
		"reply_text": reply_text,
	})


func _safe_str(val: Variant, default_val: String = "") -> String:
	if val == null:
		return default_val
	return String(val)
