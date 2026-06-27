class_name HammerWarrior
extends CharacterBase

@onready var _melee_hitbox: Hitbox = $MeleeHitbox
@onready var _melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D

func _do_attack() -> void:
	_melee_shape.position.x = absf(_melee_shape.position.x) * _facing
	_melee_hitbox.set_active(true)
	await get_tree().create_timer(attack_duration * 0.75).timeout
	if is_instance_valid(_melee_hitbox):
		_melee_hitbox.set_active(false)
