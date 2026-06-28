class_name BreakableObstacle
extends StaticBody2D

@export var break_damage_threshold: int = 35

var is_broken: bool = false

func receive_hit(damage: int) -> void:
	if is_broken or damage < break_damage_threshold:
		return
	is_broken = true
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = true
	if self is CanvasItem:
		(self as CanvasItem).visible = false
