class_name Hitbox
extends Area2D

@export var damage: int = 10

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false  # 默认关闭，攻击时再开

func set_active(on: bool) -> void:
	monitoring = on

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage)
