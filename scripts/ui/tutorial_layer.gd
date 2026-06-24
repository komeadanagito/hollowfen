class_name TutorialLayer
extends CanvasLayer

var _done: Dictionary = {}
var _current_id: String = ""

@onready var _panel: Control = get_node_or_null("Panel")
@onready var _text: Label = get_node_or_null("Panel/Text")

func _ready() -> void:
	_hide()

func show_prompt(id: String, text: String) -> void:
	if _done.get(id, false):
		return
	_current_id = id
	if _text:
		_text.text = text
	if _panel:
		_panel.visible = true

func dismiss(id: String) -> void:
	_done[id] = true
	if id == _current_id:
		_hide()

func is_done(id: String) -> bool:
	return _done.get(id, false)

func current_text() -> String:
	if _panel and not _panel.visible:
		return ""
	return _text.text if _text else ""

func _hide() -> void:
	_current_id = ""
	if _panel:
		_panel.visible = false
	if _text:
		_text.text = ""
