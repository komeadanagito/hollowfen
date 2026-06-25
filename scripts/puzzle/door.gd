class_name Door
extends StaticBody2D

var is_open: bool = false

@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var _sprite: Node = get_node_or_null("Sprite")

func open() -> void:
	if is_open:
		return
	is_open = true
	# 关掉碰撞，墙体向下沉入地面
	if _collision:
		_collision.set_deferred("disabled", true)
	var drop := _drop_distance()
	if is_inside_tree():
		var tw := create_tween()
		tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, "position:y", position.y + drop, 0.7)
	else:
		position.y += drop

func _drop_distance() -> float:
	if _collision and _collision.shape is RectangleShape2D:
		return (_collision.shape as RectangleShape2D).size.y * global_scale.y + 40.0
	return 240.0
