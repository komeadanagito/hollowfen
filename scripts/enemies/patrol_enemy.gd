class_name PatrolEnemy
extends CharacterBody2D

@export var speed: float = 70.0
@export var patrol_distance: float = 120.0
@export var gravity: float = 1200.0

@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _contact_hitbox: Hitbox = $ContactHitbox
@onready var _sprite: AnimatedSprite2D = $Sprite

var _start_x: float = 0.0
var _dir: int = 1
var _hurt_timer: float = 0.0

func _ready() -> void:
	_start_x = global_position.x
	if _health:
		_health.died.connect(_on_died)
	if _hurtbox:
		_hurtbox.hit_taken.connect(_on_hit_taken)
	if _contact_hitbox:
		_contact_hitbox.set_active(true)  # 接触伤害常开

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		velocity.x = 0.0
		if _sprite:
			_play_animation(&"hurt")
			_sprite.modulate = Color(1.0, 0.3, 0.3, 0.8) # 受伤闪红
	else:
		velocity.x = _dir * speed
		if absf(global_position.x - _start_x) > patrol_distance:
			_dir = -_dir
		
		if _sprite:
			_play_animation(&"walk")
			_sprite.flip_h = (_dir == 1)
			_sprite.modulate = Color.WHITE

	move_and_slide()

func _on_hit_taken(_damage: int) -> void:
	_hurt_timer = 0.25

func _on_died() -> void:
	set_physics_process(false)
	
	# 禁用碰撞和伤害盒，防止残留体伤害玩家或阻挡移动
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	if has_node("ContactHitbox/CollisionShape2D"):
		$ContactHitbox/CollisionShape2D.set_deferred("disabled", true)

	if _sprite:
		_play_animation(&"death")
		await _sprite.animation_finished
	queue_free()

func _play_animation(animation_name: StringName) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(animation_name):
		return
	if _sprite.animation != animation_name or not _sprite.is_playing():
		_sprite.play(animation_name)
