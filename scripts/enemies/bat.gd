class_name Bat
extends CharacterBody2D

@export var speed: float = 180.0
@export var patrol_distance: float = 260.0

@onready var _health: Health = $Health
var _start_x: float = 0.0
var _dir: int = 1

func _ready() -> void:
	_start_x = global_position.x
	add_to_group("enemy")
	if _health:
		_health.died.connect(_on_died)
	var contact := get_node_or_null("ContactHitbox") as Hitbox
	if contact:
		contact.set_active(true)

func get_health() -> Health:
	return _health

func _physics_process(delta: float) -> void:
	if absf(global_position.x - _start_x) > patrol_distance:
		_dir = -_dir
	velocity = Vector2(_dir * speed, sin(Time.get_ticks_msec() / 160.0) * 30.0)
	move_and_slide()

func _on_died() -> void:
	set_physics_process(false)
	var contact := get_node_or_null("ContactHitbox") as Hitbox
	if contact:
		contact.set_active(false)
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		cs.set_deferred("disabled", true)
	var hcs := get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
	if hcs:
		hcs.set_deferred("disabled", true)
	queue_free()
