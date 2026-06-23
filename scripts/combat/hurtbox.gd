class_name Hurtbox
extends Area2D

signal hit_taken(damage: int)

@export var health: Health
## 受击后无敌时长(秒)。玩家设 >0(如 0.6)，敌人保持 0(可连续命中)。
@export var invincible_time: float = 0.0

var _invincible: float = 0.0

func _physics_process(delta: float) -> void:
	if _invincible > 0.0:
		_invincible = maxf(_invincible - delta, 0.0)

func receive_hit(damage: int) -> void:
	if _invincible > 0.0:
		return
	if invincible_time > 0.0:
		_invincible = invincible_time
	hit_taken.emit(damage)
	if health != null:
		health.take_damage(damage)
