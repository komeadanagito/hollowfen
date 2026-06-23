class_name Switch
extends Area2D

signal activated

var is_activated: bool = false

@onready var _sprite: Node = get_node_or_null("Sprite")

func receive_hit(_damage: int) -> void:
	if is_activated:
		return
	is_activated = true
	if _sprite and _sprite is CanvasItem:
		(_sprite as CanvasItem).modulate = Color.LIME_GREEN  # 触发后变色
	activated.emit()
