class_name BreakableObstacle
extends StaticBody2D

@export var break_damage_threshold: int = 35

var is_broken: bool = false

func receive_hit(damage: int) -> void:
	if is_broken or damage < break_damage_threshold:
		return
	is_broken = true
	# receive_hit 在物理 flush 中触发（命中 Area 的 area_entered），直接改 disabled 会被 Godot
	# 拒绝（"can't change state while flushing queries"），碰撞不会真正关掉、墙仍挡路。用 deferred。
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)
	visible = false
