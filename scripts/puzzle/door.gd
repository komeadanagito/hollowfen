class_name Door
extends StaticBody2D

var is_open: bool = false

@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var _sprite: Node = get_node_or_null("Sprite")

func open() -> void:
	if is_open:
		return
	is_open = true
	if _collision:
		_collision.set_deferred("disabled", true)
	if _sprite:
		_sprite.visible = false
