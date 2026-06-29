class_name PushBox
extends RigidBody2D

var _locked: bool = false

func _ready() -> void:
	lock_rotation = true
	can_sleep = false   # 否则静止后会睡眠，忽略玩家推动的冲量

func is_locked() -> bool:
	return _locked

# 被推进缺口后吸附到与地面齐平的位置并冻结，形成稳定可走的桥面
func lock_into_slot(center: Vector2) -> void:
	if _locked:
		return
	_locked = true
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = center
	freeze = true
