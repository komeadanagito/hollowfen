class_name CharacterPickup
extends Area2D

signal picked_up(character: CharacterBase)

@export var party_manager: PartyManager
@export var target_character: CharacterBase

var _used: bool = false

@onready var _sprite: Node = get_node_or_null("Sprite")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used or party_manager == null or target_character == null:
		return
	if not (body is CharacterBase) or not (body as CharacterBase).is_active():
		return
	_used = true
	party_manager.unlock(target_character)
	picked_up.emit(target_character)
	if _sprite and _sprite is CanvasItem:
		(_sprite as CanvasItem).visible = false
