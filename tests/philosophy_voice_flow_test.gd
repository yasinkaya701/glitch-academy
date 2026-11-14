extends SceneTree
## Çalıştır: Godot --headless --path . --script res://tests/philosophy_voice_flow_test.gd

var failures := 0
var completions := 0
var finishes := 0
var mission

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	mission = load("res://stations/philosophy/mission.tscn").instantiate()
	root.add_child(mission)
	mission.completed.connect(func() -> void: completions += 1)
	mission.stage.voice.line_finished.connect(func(_id: StringName) -> void: finishes += 1)
	await create_timer(0.5).timeout
	var voice = mission.stage.voice
	check("opening line plays recorded audio immediately", voice.is_busy() and voice._player.playing)
	check("send and microphone wait for speech", mission._send_btn.disabled and mission._mic_btn.disabled)
	mission._input_box.text = "Erdem bilgidir"
	var opening_id: StringName = voice._active_id
	mission._on_text_submitted(mission._input_box.text)
	mission._on_mic_pressed()
	check("early input preserves draft and opening audio", mission._input_box.text == "Erdem bilgidir" and voice._active_id == opening_id and voice._player.playing)
	await finish_audio(voice)
	check("controls unlock after audio ends", not voice.is_busy() and not mission._send_btn.disabled and not mission._mic_btn.disabled)

	# Yerel değerlendiricinin döndürdüğü aynı metin yeniden TTS'e gitmemeli.
	var used: Array[String] = []
	var reply: Dictionary = mission.brain._evaluate_locally(&"socrates", "maiotik", 0, 0.0, used, voice.get_choices(&"socrates"), voice.get_lines(&"socrates"))
	mission.apply_llm_trigger(reply)
	check("known reply uses its recording", voice._active_id == StringName(reply.reply_id) and voice._player.playing and voice._tts_thread == null)
	await finish_audio(voice)
	mission.apply_llm_trigger({"trigger": "correct", "points": 4, "reply_id": "stage_4", "reply_text": voice.get_line_text(&"socrates", &"stage_4")})
	check("completion waits while final words play", completions == 0 and voice._player.playing)
	await finish_audio(voice)
	check("final words finish before mission completion", completions == 1)

	mission._pick(0)
	await finish_audio(voice)
	mission.apply_llm_trigger({"trigger": "wrong", "reply_id": "wrong_sofist"})
	check("wrong answer speaks without completing", voice._player.playing and completions == 1)
	await finish_audio(voice)
	mission.apply_llm_trigger({"trigger": "angry_leave"})
	await create_timer(1.6).timeout
	check("philosopher stays visible during farewell", voice.is_busy() and mission.stage.actor.modulate.a > 0.95)
	await finish_audio(voice)
	await create_timer(1.6).timeout
	check("philosopher leaves after farewell", mission.stage.actor.modulate.a < 0.05)

	mission._pick(0)
	check("retry restores philosopher visibility", mission.stage.actor.modulate.a == 1.0)
	var old_generation: int = voice._generation
	mission._pick(1)
	var current_text: String = voice.get_line_text(&"plato", &"stage_0")
	var current_stream = voice._player.stream
	voice._on_local_tts_ready("res://stations/philosophy/audio/socrates/stage_4.mp3", "res://stations/philosophy/audio/socrates/stage_4.json", "Eski yanıt", old_generation, 0)
	voice._on_stt_done(true, "Eski mikrofon yanıtı", old_generation)
	check("late TTS and microphone cannot replace new philosopher", voice._player.stream == current_stream and mission._index == 1 and mission.stage._line_label.text.contains(current_text))
	mission.brain.cancel()
	mission.brain._on_llm_completed(0, 200, PackedStringArray(), "{}".to_utf8_buffer())
	check("cancelled brain request stays ignored", voice._player.stream == current_stream)

	# Ses üretimi beklenirken süre tahminiyle bitmiş sinyali yayılmamalı.
	voice.stop()
	voice._active_id = &"pending_test"
	voice._set_busy(true)
	var before_finishes: int = finishes
	voice._process(12.0)
	check("pending generation does not finish on an estimated timer", voice.is_busy() and finishes == before_finishes and not mission.stage.actor.speaking)
	voice._on_local_tts_ready("", "", "", voice._generation, 1)
	check("generation failure releases controls", not voice.is_busy() and not mission._send_btn.disabled)

	# Tüm kayıtlar Godot'un gerçek MP3 çözücüsüyle yüklenebilir olmalı.
	var valid_tracks := 0
	for who in mission.ORDER:
		for line_id in voice.get_lines(who):
			var base: String = voice.AUDIO_DIR + String(who) + "/" + String(line_id)
			var stream = voice._load_audio(base + ".mp3")
			var track: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
			check("recording matches text: %s/%s" % [who, line_id], stream != null and track.get("text") == voice.get_line_text(who, StringName(line_id)))
			valid_tracks += 1
	check("all 65 recordings checked", valid_tracks == 65)

	# En uzun repliği baştan sona gerçek oynatma saatiyle dene.
	mission._pick(7)
	voice.play_line(&"ibn_rushd", &"stage_1")
	await create_timer(8.2).timeout
	check("long speech still plays beyond the former 8 second timeout", voice.is_busy() and voice._player.playing)
	var deadline: int = Time.get_ticks_msec() + 10000
	while voice.is_busy() and Time.get_ticks_msec() < deadline:
		await create_timer(0.2).timeout
	check("long speech finishes naturally", not voice.is_busy() and not voice._player.playing)

	if OS.get_cmdline_user_args().has("--capture"):
		mission._pick(0)
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/philosophy-voice-review.png")
	mission.queue_free()
	await process_frame
	print("PHILOSOPHY VOICE FAILURES: ", failures)
	quit(failures)

func finish_audio(voice) -> void:
	voice._player.seek(maxf(voice._player.stream.get_length() - 0.15, 0.0))
	await create_timer(0.6).timeout
	check("audio reaches its natural finished signal", not voice._player.playing)

func check(label: String, passed: bool) -> void:
	print("OK " if passed else "FAIL ", label)
	if not passed: failures += 1
