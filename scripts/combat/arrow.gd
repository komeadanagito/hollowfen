class_name Arrow
extends Area2D

@export var speed: float = 1300.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var _dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)  # 撞墙(StaticBody)消失
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func launch(direction: Vector2) -> void:
	_dir = direction.normalized()
	rotation = _dir.angle()

func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage)
		queue_free()

func _on_body_entered(_body: Node) -> void:
	queue_free()
