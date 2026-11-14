extends Control
## A short, local MERİDYEN transmission between experiments. No network dependency.

signal dismissed

var _continue_action: Callable
var _return_action: Callable
var heading: Label
var message: Label
var continue_button: Button
var return_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 40
	mouse_filter = Control.MOUSE_FILTER_STOP
	var wash := ColorRect.new()
	wash.color = Color(UITheme.BG, 0.94)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wash)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = "ConsolePanel"
	card.custom_minimum_size = Vector2(620, 0)
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	card.add_child(content)
	var speaker := Label.new()
	speaker.text = "MERİDYEN"
	speaker.theme_type_variation = "SectionLabel"
	content.add_child(speaker)
	heading = Label.new()
	heading.theme_type_variation = "HeadlineLabel"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.x = 570
	content.add_child(heading)
	message = Label.new()
	message.custom_minimum_size.x = 570
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 20)
	content.add_child(message)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	continue_button = Button.new()
	continue_button.theme_type_variation = "PrimaryButton"
	continue_button.custom_minimum_size.y = 48
	continue_button.pressed.connect(_continue)
	actions.add_child(continue_button)
	return_button = Button.new()
	return_button.text = "Merkeze dön"
	return_button.custom_minimum_size.y = 48
	return_button.pressed.connect(_return)
	actions.add_child(return_button)
	hide()

func present(title: String, text: String, action_text: String, on_continue: Callable, on_return: Callable = Callable()) -> void:
	heading.text = title
	message.text = text
	continue_button.text = action_text
	_continue_action = on_continue
	_return_action = on_return
	return_button.visible = on_return.is_valid()
	show()
	continue_button.grab_focus()

func _continue() -> void:
	var action := _continue_action
	hide()
	_continue_action = Callable()
	_return_action = Callable()
	if action.is_valid(): action.call()
	dismissed.emit()

func _return() -> void:
	var action := _return_action
	hide()
	_continue_action = Callable()
	_return_action = Callable()
	if action.is_valid(): action.call()
	dismissed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _return_action.is_valid(): _return()
		else: _continue()
		get_viewport().set_input_as_handled()
