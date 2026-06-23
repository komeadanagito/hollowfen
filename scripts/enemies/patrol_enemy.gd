class_name PatrolEnemy
extends CharacterBody2D

@export var speed: float = 70.0
@export var patrol_distance: float = 120.0
@export var gravity: float = 1200.0

@onready var _health: Health = $Health
@onready var _contact_hitbox: Hitbox = $ContactHitbox

var _start_x: float = 0.0
var _dir: int = 1

func _ready() -> void:
	_start_x = global_position.x
	if _health:
		_health.died.connect(queue_free)
	if _contact_hitbox:
		_contact_hitbox.set_active(true)  # 接触伤害常开

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = _dir * speed
	if absf(global_position.x - _start_x) > patrol_distance:
		_dir = -_dir
	move_and_slide()
