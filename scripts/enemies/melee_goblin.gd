class_name MeleeGoblin
extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

@export var speed: float = 160.0
@export var chase_speed: float = 240.0
@export var detect_range: float = 450.0
@export var attack_range: float = 95.0
@export var vertical_tolerance: float = 120.0
@export var patrol_distance: float = 250.0
@export var gravity: float = 3000.0
@export var attack_windup: float = 0.3
@export var attack_active_time: float = 0.15
@export var attack_cooldown: float = 0.8

@onready var _health: Health = $Health
@onready var _hitbox: Hitbox = get_node_or_null("MeleeHitbox")
@onready var _hitbox_shape: CollisionShape2D = get_node_or_null("MeleeHitbox/CollisionShape2D")
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")

var state: int = State.PATROL
var _start_x: float = 0.0
var _dir: int = 1
var _facing: int = 1
var _cooldown: float = 0.0
var _attack_timer: float = 0.0

func _ready() -> void:
	_start_x = global_position.x
	if _health:
		_health.died.connect(queue_free)
	if _hitbox:
		_hitbox.set_active(false)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_cooldown = maxf(_cooldown - delta, 0.0)

	var player := _find_player()
	match state:
		State.PATROL:
			_do_patrol()
			if player and _can_see(player):
				state = State.CHASE
		State.CHASE:
			if player == null or not _can_see(player):
				state = State.PATROL
			else:
				var dx: float = player.global_position.x - global_position.x
				if absf(dx) > 12.0:                       # 死区，避免朝向抖动
					_facing = 1 if dx >= 0.0 else -1
				if absf(dx) <= attack_range:
					velocity.x = move_toward(velocity.x, 0.0, chase_speed)  # 站定，不来回抽搐
					if _cooldown <= 0.0:
						_enter_attack()
				else:
					velocity.x = _facing * chase_speed
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				state = State.CHASE

	move_and_slide()
	_update_anim()

func _update_anim() -> void:
	if _sprite == null:
		return
	_sprite.flip_h = _facing < 0   # 贴图默认朝右
	if state == State.ATTACK:
		_sprite.play("attack")
	elif absf(velocity.x) > 5.0:
		_sprite.play("walk")
	else:
		_sprite.play("idle")

func _do_patrol() -> void:
	velocity.x = _dir * speed
	_facing = _dir
	if absf(global_position.x - _start_x) > patrol_distance:
		_dir = -_dir

func _can_see(player: Node2D) -> bool:
	var d: Vector2 = player.global_position - global_position
	return absf(d.x) <= detect_range and absf(d.y) <= vertical_tolerance

func _enter_attack() -> void:
	state = State.ATTACK
	_attack_timer = attack_windup + attack_active_time
	_cooldown = attack_cooldown
	velocity.x = 0.0
	_swing()

func _swing() -> void:
	if _hitbox_shape:
		_hitbox_shape.position.x = absf(_hitbox_shape.position.x) * _facing
	await get_tree().create_timer(attack_windup).timeout
	if not is_instance_valid(self):
		return
	if _hitbox:
		_hitbox.set_active(true)
	await get_tree().create_timer(attack_active_time).timeout
	if not is_instance_valid(self):
		return
	if _hitbox:
		_hitbox.set_active(false)

func _find_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is CharacterBase and (p as CharacterBase).is_active():
			return p as Node2D
	return null
