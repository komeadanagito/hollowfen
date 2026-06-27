class_name Health
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 30

var current: int = 0

func _ready() -> void:
	current = max_health

func take_damage(amount: int) -> void:
	if current <= 0:
		return
	current = clampi(current - amount, 0, max_health)
	health_changed.emit(current, max_health)
	if current <= 0:
		died.emit()

func heal(amount: int) -> void:
	if current <= 0:
		return
	current = clampi(current + amount, 0, max_health)
	health_changed.emit(current, max_health)

func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)

func is_dead() -> bool:
	return current <= 0

func set_current(value: int) -> void:
	current = clampi(value, 0, max_health)
	health_changed.emit(current, max_health)
