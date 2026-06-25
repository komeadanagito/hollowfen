class_name Archer
extends CharacterBase

const ARROW_SCENE := preload("res://scenes/combat/arrow.tscn")

@onready var _muzzle: Marker2D = $Muzzle

func _do_attack() -> void:
	# 朝鼠标方向射击（指向性）；鼠标无效时回退到水平朝向
	var dir := get_global_mouse_position() - global_position
	if dir.length() < 4.0:
		dir = Vector2(_facing, 0.0)
	dir = dir.normalized()
	# 面向瞄准方向
	if absf(dir.x) > 0.05:
		_facing = 1 if dir.x > 0.0 else -1
	# 枪口随朝向镜像
	var muzzle_offset := Vector2(absf(_muzzle.position.x) * _facing, _muzzle.position.y)
	var arrow: Arrow = ARROW_SCENE.instantiate()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(arrow)
	arrow.global_position = global_position + muzzle_offset
	arrow.launch(dir)
