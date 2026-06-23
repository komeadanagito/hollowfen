class_name Hurtbox
extends Area2D

signal hit_taken(damage: int)

@export var health: Health

func receive_hit(damage: int) -> void:
	hit_taken.emit(damage)
	if health != null:
		health.take_damage(damage)
