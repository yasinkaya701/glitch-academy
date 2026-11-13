extends "res://scripts/mission_definition.gd"
class_name YksMissionDefinition
## One self-contained, source-backed YKS micro-mission.

@export var field_tags: PackedStringArray = PackedStringArray()
@export var source_note: String
@export var learning_target: String
@export var instruction: String
@export_multiline var prompt: String
@export var visual_theme: StringName = &"reading"
@export_enum("choice", "sequence", "pair") var mode := "choice"
@export var options: PackedStringArray = PackedStringArray()
@export var correct_option: String
@export var sequence_items: PackedStringArray = PackedStringArray()
@export var correct_sequence: PackedStringArray = PackedStringArray()
@export var pair_left: PackedStringArray = PackedStringArray()
@export var pair_right: PackedStringArray = PackedStringArray()
## Each entry is the matching right-side label for the left-side item at the same index.
@export var pair_targets: PackedStringArray = PackedStringArray()
@export var feedback_wrong: String
@export var feedback_success: String


func has_valid_answer_set() -> bool:
	if id == &"" or title.is_empty() or subject.is_empty() or curriculum.is_empty():
		return false
	if routes.is_empty() or grade <= 0 or scene == null or field_tags.is_empty():
		return false
	for route_name in routes:
		if route_name not in ["tyt", "ayt", "ydt"]:
			return false
	for tag in field_tags:
		if tag not in ["sayisal", "ea", "sozel", "ydt"]:
			return false
	if not source_url.begins_with("https://") or source_note.is_empty():
		return false
	if learning_target.is_empty() or prompt.is_empty() or visual_theme == &"":
		return false
	if instruction.is_empty() or feedback_wrong.is_empty() or feedback_success.is_empty():
		return false
	match mode:
		"choice":
			return _has_unique_values(options) and options.size() >= 2 and options.has(correct_option)
		"sequence":
			return _has_unique_values(sequence_items) and sequence_items.size() >= 2 \
				and sequence_items.size() == correct_sequence.size() \
				and _same_members(sequence_items, correct_sequence)
		"pair":
			return _has_unique_values(pair_left) and _has_unique_values(pair_right) \
				and pair_left.size() >= 2 and pair_left.size() == pair_targets.size() \
				and pair_right.size() == pair_targets.size() \
				and _has_unique_values(pair_targets) and _same_members(pair_right, pair_targets)
	return false


func correct_answer() -> Variant:
	match mode:
		"choice":
			return correct_option
		"sequence":
			return correct_sequence.duplicate()
		"pair":
			var pairs: Dictionary = {}
			for index in pair_left.size():
				pairs[pair_left[index]] = pair_targets[index]
			return pairs
	return null


func _has_unique_values(values: PackedStringArray) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if value.strip_edges().is_empty() or seen.has(value):
			return false
		seen[value] = true
	return true


func _same_members(first: PackedStringArray, second: PackedStringArray) -> bool:
	if first.size() != second.size():
		return false
	for value in first:
		if not second.has(value):
			return false
	return true
