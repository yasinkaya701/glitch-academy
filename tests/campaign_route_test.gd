extends Node
## YDT-only missions stay outside the core threshold but still count toward the explicit language path.
## Usage: godot --headless --path . tests/campaign_route_test.tscn

const CampaignState = preload("res://scripts/campaign_state.gd")

var failures := 0


func _ready() -> void:
	var campaign = CampaignState.new()
	var catalog := [
		{"id": &"turkish_reading", "subject": "Türkçe", "routes": PackedStringArray(["tyt"])},
		{"id": &"history", "subject": "Tarih", "routes": PackedStringArray(["ayt"])},
		{"id": &"turkish_literature", "subject": "Türk Dili ve Edebiyatı", "routes": PackedStringArray(["ayt"])},
		{"id": &"ydt_english", "subject": "English", "routes": PackedStringArray(["ydt"])},
	]
	for mission_id in [&"turkish_reading", &"history", &"turkish_literature", &"ydt_english"]:
		campaign.completed_ids[mission_id] = true

	var core_count := campaign.completed_subject_count(catalog, false)
	var all_route_count := campaign.completed_subject_count(catalog)
	_check("3 core subjects plus YDT English produce only 3 core subjects", core_count == 3)
	_check("the same completions count as 4 subjects when YDT is included", all_route_count == 4)
	_check("YDT-only completion cannot reach the 4-subject core threshold", core_count < 4)

	# Keep the language gate aligned with ControlCenter._has_finale_evidence.
	var has_language_evidence := campaign.is_completed(&"ydt_english") \
		and campaign.is_completed(&"turkish_reading") \
		and campaign.is_completed(&"history") \
		and campaign.is_completed(&"turkish_literature")
	var language_campaign := all_route_count >= 4 and has_language_evidence
	_check("YDT English plus the explicit Turkish/history evidence still satisfies the language path", language_campaign)

	campaign.free()
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	get_tree().quit(failures)


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok " if ok else "HATA", label])
	if not ok:
		failures += 1
