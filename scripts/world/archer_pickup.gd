class_name ArcherPickup
extends Area2D

signal picked_up

@export var party_manager: PartyManager
@export var target_character: CharacterBase

var _used: bool = false

@onready var _sprite: Node = get_node_or_null("Sprite")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used or party_manager == null or target_character == null:
		return
	if not (body is CharacterBase):
		return
	_used = true
	party_manager.unlock(target_character)
	picked_up.emit()
	if _sprite and _sprite is CanvasItem:
		(_sprite as CanvasItem).visible = false
