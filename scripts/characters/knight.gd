class_name Knight
extends CharacterBase

@onready var _melee_hitbox: Hitbox = $MeleeHitbox
@onready var _melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D

func _do_attack() -> void:
	# 把命中盒形状摆到面朝方向并短暂开启
	_melee_shape.position.x = absf(_melee_shape.position.x) * _facing
	_melee_hitbox.set_active(true)
	await get_tree().create_timer(attack_duration * 0.6).timeout
	if is_instance_valid(_melee_hitbox):
		_melee_hitbox.set_active(false)
