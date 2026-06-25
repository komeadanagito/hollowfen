class_name RangedGoblin
extends CharacterBody2D

const ENEMY_ARROW := preload("res://scenes/combat/enemy_arrow.tscn")

@export var fire_range: float = 750.0
@export var min_distance: float = 220.0
@export var retreat_speed: float = 180.0
@export var fire_interval: float = 1.6
@export var vertical_tolerance: float = 100.0
@export var gravity: float = 3000.0
@export var arrow_damage: int = 8

@onready var _health: Health = $Health
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")

var _fire_cd: float = 0.0
var _attack_anim: float = 0.0
var _facing: int = -1

func _ready() -> void:
	if _health:
		_health.died.connect(_on_died)

func _on_died() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	var cs := get_node_or_null("CollisionShape2D")
	if cs:
		cs.set_deferred("disabled", true)
	var hcs := get_node_or_null("Hurtbox/CollisionShape2D")
	if hcs:
		hcs.set_deferred("disabled", true)
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"death"):
		_sprite.play(&"death")
		await _sprite.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	_attack_anim = maxf(_attack_anim - delta, 0.0)
	velocity.x = 0.0

	var player := _find_player()
	if player and _in_range(player):
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) > 12.0:                       # 死区，避免朝向抖动
			_facing = 1 if dx >= 0.0 else -1
		if absf(dx) < min_distance:
			velocity.x = -_facing * retreat_speed   # 玩家太近 → 后退保持距离
		if _fire_cd <= 0.0:
			_fire()
			_fire_cd = fire_interval

	move_and_slide()
	_update_anim()

func _update_anim() -> void:
	if _sprite == null:
		return
	_sprite.flip_h = _facing < 0   # 贴图默认朝右
	if _attack_anim > 0.0:
		_sprite.play("attack")
	elif absf(velocity.x) > 5.0:
		_sprite.play("walk")
	else:
		_sprite.play("idle")

func _in_range(player: Node2D) -> bool:
	var d: Vector2 = player.global_position - global_position
	return absf(d.x) <= fire_range and absf(d.y) <= vertical_tolerance

func _fire() -> void:
	_attack_anim = 0.4
	var arrow := ENEMY_ARROW.instantiate()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(arrow)
	arrow.global_position = global_position + Vector2(_facing * 35.0, -10.0)
	arrow.set("damage", arrow_damage)
	arrow.launch(Vector2(_facing, 0.0))

func _find_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is CharacterBase and (p as CharacterBase).is_active():
			return p as Node2D
	return null
