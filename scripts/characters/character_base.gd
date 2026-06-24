class_name CharacterBase
extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT }

@export_group("Movement")
@export var move_speed: float = 550.0
@export var acceleration: float = 4500.0
@export var friction: float = 5000.0
@export var jump_velocity: float = -1075.0
@export var gravity: float = 3000.0
@export_group("Feel")
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1
@export_group("Combat")
@export var attack_duration: float = 0.25
@export var hurt_duration: float = 0.25
@export var knockback_force: float = 625.0

var state: int = State.IDLE
var _active: bool = false
var _facing: int = 1                 # 1 右, -1 左
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _state_timer: float = 0.0
var _dead: bool = false

@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sprite: Node = get_node_or_null("Sprite")

func _ready() -> void:
	add_to_group("player")
	if _hurtbox:
		_hurtbox.hit_taken.connect(_on_hit_taken)
	if _health:
		_health.died.connect(_on_died)
	_update_animation()

func set_active(active: bool) -> void:
	_active = active
	visible = active
	set_physics_process(active)

func is_active() -> bool:
	return _active

func get_health() -> Health:
	return _health

func get_facing() -> int:
	return _facing

func respawn(pos: Vector2) -> void:
	_dead = false
	global_position = pos
	velocity = Vector2.ZERO
	_set_state(State.IDLE)
	if _health:
		_health.reset()

func _physics_process(delta: float) -> void:
	if _dead:
		_update_animation()
		return

	_coyote = maxf(_coyote - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if is_on_floor():
		_coyote = coyote_time

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.IDLE, State.RUN, State.JUMP, State.FALL:
			_process_locomotion(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)

	_update_animation()
	move_and_slide()

func _process_locomotion(delta: float) -> void:
	var dir := 0.0
	if _active:
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = jump_buffer_time
		if Input.is_action_just_pressed("attack"):
			_enter_attack()
			return
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
		_facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0

	# 状态判定
	if not is_on_floor():
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)
	elif absf(velocity.x) > 5.0:
		_set_state(State.RUN)
	else:
		_set_state(State.IDLE)

func _enter_attack() -> void:
	_set_state(State.ATTACK)
	_state_timer = attack_duration
	velocity.x = 0.0
	_do_attack()

func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_set_state(State.IDLE)

func _process_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_set_state(State.IDLE)

func _on_hit_taken(_damage: int) -> void:
	if _dead:
		return
	# Hurtbox 只在非无敌时发出 hit_taken，所以这里每次都是真实命中
	_set_state(State.HURT)
	_state_timer = hurt_duration
	velocity = Vector2(-_facing * knockback_force, -120.0)

func _on_died() -> void:
	_dead = true
	velocity = Vector2.ZERO
	_play_animation(&"death")

func _set_state(new_state: int) -> void:
	if _dead:
		return
	state = new_state
	_update_animation()

func _update_animation() -> void:
	if _sprite == null or not (_sprite is AnimatedSprite2D):
		return
	
	var anim_sprite := _sprite as AnimatedSprite2D
	
	# 左右翻转
	anim_sprite.flip_h = (_facing == -1)
	
	# 受伤闪红
	if state == State.HURT:
		anim_sprite.modulate = Color(1.0, 0.3, 0.3, 0.8)
	else:
		anim_sprite.modulate = Color.WHITE

	if _dead:
		_play_animation(&"death")
		return

	# 状态动画切换
	match state:
		State.IDLE:
			_play_animation(&"idle")
		State.RUN, State.JUMP, State.FALL:
			_play_animation(&"walk")
		State.ATTACK:
			_play_animation(&"attack")
		State.HURT:
			_play_animation(&"idle")

func _play_animation(animation_name: StringName) -> void:
	if _sprite == null or not (_sprite is AnimatedSprite2D):
		return
	var anim_sprite := _sprite as AnimatedSprite2D
	if anim_sprite.sprite_frames == null:
		return
	if not anim_sprite.sprite_frames.has_animation(animation_name):
		return
	if anim_sprite.animation != animation_name or not anim_sprite.is_playing():
		anim_sprite.play(animation_name)

# 由子类覆盖
func _do_attack() -> void:
	pass
