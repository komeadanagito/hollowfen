class_name PushBox
extends RigidBody2D

func _ready() -> void:
	lock_rotation = true
	can_sleep = false   # 否则静止后会睡眠，忽略玩家推动的冲量
