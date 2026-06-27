class_name Slime
extends CharacterBody2D

@export var speed: float = 100.0
@export var patrol_distance: float = 220.0
@export var gravity: float = 3000.0

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
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_wall() or absf(global_position.x - _start_x) > patrol_distance:
		_dir = -_dir
	velocity.x = _dir * speed
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
