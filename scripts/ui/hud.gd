class_name HUD
extends CanvasLayer

@export var party_manager: PartyManager

@onready var _active_label: Label = $Root/ActiveLabel
@onready var _hp_label: Label = $Root/HpLabel

func _ready() -> void:
	if party_manager:
		party_manager.character_switched.connect(_on_switched)
		_on_switched(party_manager.get_active_character())

func _on_switched(character: CharacterBase) -> void:
	if character == null:
		return
	_active_label.text = "当前: " + character.name
	_refresh_hp()
	var h := character.get_health()
	if h and not h.health_changed.is_connected(_on_hp_changed):
		h.health_changed.connect(_on_hp_changed)

func _on_hp_changed(_c: int, _m: int) -> void:
	_refresh_hp()

func _refresh_hp() -> void:
	if party_manager == null:
		return
	var c := party_manager.get_active_character()
	if c and c.get_health():
		var h := c.get_health()
		_hp_label.text = "HP: %d/%d" % [h.current, h.max_health]
