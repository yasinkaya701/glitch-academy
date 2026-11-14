extends SceneTree
## Gerçek sürücüyle çalıştır; Dummy sürücü bu testi geçemez.
## Godot --path . --rendering-method gl_compatibility --script res://tests/philosophy_audio_output_test.gd

class QuotaVoice extends PhilosophyVoicePlayer:
 var queued := false
 func _queue_local_tts(_mp3: String, _json: String) -> void:
  queued = true

var failures := 0
var rendered := false
var capture := AudioEffectCapture.new()
var center

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 root.size = Vector2i(1280, 720)
 root.content_scale_size = Vector2i(1280, 720)
 RenderingServer.frame_post_draw.connect(func() -> void: rendered = true)
 print("DRIVER: ", AudioServer.get_driver_name(), " DEVICE: ", AudioServer.output_device)
 check("real output driver", AudioServer.get_driver_name() != "Dummy")
 check("master is audible", not AudioServer.is_bus_mute(0) and AudioServer.get_bus_volume_db(0) > -20.0)
 capture.buffer_length = 12.0
 AudioServer.add_bus_effect(0, capture)
 center = load("res://scenes/control_center.tscn").instantiate()
 root.add_child(center)
 var intro = center.get_node_or_null("Intro")
 if intro: center._finish_intro(intro)
 center._select_route(&"class")
 for candidate in center.visible_missions:
  if candidate.id == &"philosophy": center.selected_mission = candidate

 capture.clear_buffer()
 rendered = false
 center._start_mission()
 var mission = center.active_mission
 var voice = mission.stage.voice
 check("first entry reserves the opening before playback", voice.is_busy() and not voice._player.playing)
 var started_after_render := [false]
 voice.line_started.connect(func(_id: StringName, _text: String) -> void: started_after_render[0] = rendered)
 await create_timer(1.8).timeout
 check("opening starts after the scene is drawn", started_after_render[0])
 check_capture("cold hub entry: Sokrates", true)
 check("opening bypasses live services", voice._tts_thread == null and voice._pending_live_hash == "")

 for index in range(1, mission.ORDER.size()):
  capture.clear_buffer()
  mission._pick(index)
  await create_timer(1.5).timeout
  check_capture("opening: " + String(mission.ORDER[index]))

 voice.stop()
 voice.replay()
 await create_timer(0.3).timeout
 check("replay restarts the same spoken line", voice._player.playing and voice._active_id == &"stage_0")
 voice.set_volume(0.5)
 check("voice volume applies without muting master", voice._player.volume_db < voice._track_gain_db - 5.9 and not AudioServer.is_bus_mute(0))
 voice.stop()

 # Kota yanıtı, anahtarı tekrar Python'a denetmeden doğrudan yedeğe gitmeli.
 var quota_voice := QuotaVoice.new()
 root.add_child(quota_voice)
 quota_voice._active_id = &"quota"
 quota_voice._pending_live_hash = "quota-test"
 quota_voice._set_busy(true)
 quota_voice._on_live_tts_completed(0, 401, PackedStringArray(), "{}".to_utf8_buffer())
 check("quota error selects local fallback for subsequent replies", quota_voice.queued and quota_voice._local_only)
 quota_voice.queue_free()

 # Ağsız Türkçe WAV yedeğini gerçek üreticiyle oluşturup oynat.
 var native_path := "/tmp/philosophy-native-check.mp3"
 var output := []
 var native_code: int = OS.execute(voice._resolve_python(), PackedStringArray([
  ProjectSettings.globalize_path(voice.GEN_VOICES_SCRIPT), "--engine=macos", "--who=socrates",
  "--text=Zihnim sis içinde. Şimdi sesimi duyabiliyor musun?", "--out=" + native_path,
 ]), output, true)
 check("native Turkish generation succeeds without network", native_code == 0)
 check("native fallback file exists", FileAccess.file_exists(native_path.get_basename() + ".wav"))
 capture.clear_buffer()
 voice._active_id = &"offline"
 voice._set_busy(true)
 voice._on_local_tts_ready(native_path, native_path.get_basename() + ".json", "Yerel Türkçe ses", voice._generation, 0)
 await create_timer(1.5).timeout
 check_capture("offline Turkish fallback")
 voice.stop()

 # Gerçek Python işçisi ve önbellek üzerinden yeni bir serbest yanıtı uçtan uca çal.
 capture.clear_buffer()
 voice.set_volume(1.0)
 voice._local_only = true
 voice.speak_live(&"ibn_rushd", "Hakikati akıl yoluyla ararım. Düşüncelerimizi birlikte sorgulayalım.", &"live_output_test")
 var deadline: int = Time.get_ticks_msec() + 22000
 while voice.is_busy() and not voice._player.playing and Time.get_ticks_msec() < deadline:
  await create_timer(0.1).timeout
 check("live worker produces playable audio", voice._player.playing)
 await create_timer(1.5).timeout
 check_capture("live response after service quota fallback")
 voice.stop()

 center._return_to_hub()
 capture.clear_buffer()
 center._start_mission()
 await create_timer(1.8).timeout
 check_capture("fresh mission after returning to hub")
 check("new mission begins at full game volume", center.active_mission._volume_slider.value == 100)
 if OS.get_cmdline_user_args().has("--capture"):
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/philosophy-audio-controls.png")
 center.queue_free()
 AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
 await process_frame
 print("PHILOSOPHY AUDIO OUTPUT FAILURES: ", failures)
 quit(failures)

func check_capture(label: String, save := false) -> void:
 var frames: PackedVector2Array = capture.get_buffer(capture.get_frames_available())
 var peak := 0.0
 var energy := 0.0
 for frame in frames:
  peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
  energy += frame.length_squared() * 0.5
 print("MIX ", label, " frames=", frames.size(), " peak_db=", linear_to_db(peak), " rms_db=", linear_to_db(sqrt(energy / maxi(frames.size(), 1))))
 check(label + " produces real mixer samples", peak > 0.03 and energy > 0.1)
 check(label + " has clipping headroom", peak < 0.99)
 if save:
  var bytes := PackedByteArray()
  bytes.resize(frames.size() * 4)
  for i in frames.size():
   bytes.encode_s16(i * 4, clampi(int(frames[i].x * 32767), -32768, 32767))
   bytes.encode_s16(i * 4 + 2, clampi(int(frames[i].y * 32767), -32768, 32767))
  var wav := AudioStreamWAV.new()
  wav.format = AudioStreamWAV.FORMAT_16_BITS
  wav.stereo = true
  wav.mix_rate = int(AudioServer.get_mix_rate())
  wav.data = bytes
  wav.save_to_wav("/tmp/philosophy-coreaudio-opening.wav")

func check(label: String, passed: bool) -> void:
 print("OK " if passed else "FAIL ", label)
 if not passed: failures += 1
