class_name HUD
extends CanvasLayer

@export var party_manager: PartyManager

const AVATARS := {
	"Knight": preload("res://assets/character/knight/knight_avatar_head.png"),
	"Archer": preload("res://assets/character/archer/archer_avatar_head.png"),
	"OcarinaGirl": preload("res://assets/character/ocarina_girl/ocarina_girl_avatar_head.png"),
}

@onready var _avatar: TextureRect = $Root/Panel/HBox/Avatar
@onready var _name_label: Label = $Root/Panel/HBox/Info/NameLabel
@onready var _health_bar: ProgressBar = $Root/Panel/HBox/Info/HealthBar
@onready var _vials_label: Label = $Root/Panel/HBox/Info/VialsLabel

func _ready() -> void:
	if party_manager:
		party_manager.character_switched.connect(_on_switched)
		if not party_manager.vials_changed.is_connected(_on_vials_changed):
			party_manager.vials_changed.connect(_on_vials_changed)
		_on_switched(party_manager.get_active_character())
		_refresh_vials()

func _on_switched(character: CharacterBase) -> void:
	if character == null:
		return
	if _name_label:
		_name_label.text = character.name
	if _avatar and AVATARS.has(character.name):
		_avatar.texture = AVATARS[character.name]
	var h := character.get_health()
	if h and not h.health_changed.is_connected(_on_hp_changed):
		h.health_changed.connect(_on_hp_changed)
	_refresh_bar()

func _on_hp_changed(_c: int, _m: int) -> void:
	_refresh_bar()

func _on_vials_changed(_current: int, _maximum: int) -> void:
	_refresh_vials()

func _refresh_bar() -> void:
	if party_manager == null or _health_bar == null:
		return
	var ch := party_manager.get_active_character()
	if ch and ch.get_health():
		var h := ch.get_health()
		_health_bar.max_value = h.max_health
		_health_bar.value = h.current

func _refresh_vials() -> void:
	if party_manager == null or _vials_label == null:
		return
	_vials_label.text = "血瓶 x%d" % party_manager.vials
