class_name CharacterBase
extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DASH }

@export_group("Movement")
@export var move_speed: float = 550.0
@export var acceleration: float = 4500.0
@export var friction: float = 5000.0
@export var jump_velocity: float = -1075.0
@export var gravity: float = 3000.0
@export var air_jumps: int = 0          # 额外空中跳跃次数（0=单跳，1=二段跳）
@export_group("Feel")
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1
@export_group("Dash")
@export var dash_enabled: bool = false
@export var dash_speed: float = 1100.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45
@export_group("Combat")
@export var attack_duration: float = 0.25
@export var hurt_duration: float = 0.25
@export var knockback_force: float = 625.0

var state: int = State.IDLE
var _active: bool = false
var _facing: int = 1                 # 1 右, -1 左
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _jumps_left: int = 0             # 剩余空中跳跃次数
var _state_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_was_pressed: bool = false
var _dead: bool = false
var _last_safe: Vector2 = Vector2.ZERO   # 最近一次站在地面的位置（死亡切换接管点）

@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sprite: Node = get_node_or_null("Sprite")

func _ready() -> void:
	add_to_group("player")
	_last_safe = global_position
	if _hurtbox:
		_hurtbox.hit_taken.connect(_on_hit_taken)
	if _health:
		_health.died.connect(_on_died)
	_update_animation()

func set_active(active: bool) -> void:
	_active = active
	visible = active
	set_physics_process(active)
	_set_collision_active(active)

func is_active() -> bool:
	return _active

func get_last_safe_position() -> Vector2:
	return _last_safe

# 中心正下方是否有地面（区分"稳稳站在地上"和"贴着悬边")
func _is_solidly_grounded() -> bool:
	var world := get_world_2d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true
	var from := global_position
	var to := global_position + Vector2(0.0, get_feet_offset_y() + 12.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)  # terrain 层
	query.exclude = [self]
	return not space.intersect_ray(query).is_empty()

func get_feet_global_y() -> float:
	return global_position.y + get_feet_offset_y()

func get_feet_global_y_at(pos: Vector2) -> float:
	return pos.y + get_feet_offset_y()

func get_position_for_feet(pos: Vector2, feet_y: float) -> Vector2:
	return Vector2(pos.x, feet_y - get_feet_offset_y())

func get_feet_offset_y() -> float:
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null or body_shape.shape == null:
		return 0.0
	var shape := body_shape.shape
	if shape is RectangleShape2D:
		return body_shape.position.y + (shape as RectangleShape2D).size.y * 0.5
	if shape is CapsuleShape2D:
		return body_shape.position.y + (shape as CapsuleShape2D).height * 0.5
	if shape is CircleShape2D:
		return body_shape.position.y + (shape as CircleShape2D).radius
	return body_shape.position.y

func get_health() -> Health:
	return _health

func get_facing() -> int:
	return _facing

func _set_collision_active(active: bool) -> void:
	# 用 set_deferred：死亡切换发生在物理 flush 中，直接改碰撞/监听状态会被 Godot 阻止，
	# 导致新角色碰撞没启用而穿地板。
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.set_deferred("disabled", not active)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", active)
		for child in _hurtbox.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", not active)

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
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)
	if is_on_floor():
		_coyote = coyote_time
		_jumps_left = air_jumps
		if _is_solidly_grounded():     # 仅在中心正下方有地面时记录，避免贴边导致接管角色滑进坑
			_last_safe = global_position

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.IDLE, State.RUN, State.JUMP, State.FALL:
			_process_locomotion(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)
		State.DASH:
			_process_dash(delta)

	_update_animation()
	move_and_slide()

func _process_locomotion(delta: float) -> void:
	var dir := 0.0
	if _active:
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = jump_buffer_time
		if _consume_dash_pressed() and _can_dash():
			_enter_dash()
			return
		if Input.is_action_just_pressed("attack"):
			_enter_attack()
			return
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
		_facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if _jump_buffer > 0.0:
		if _coyote > 0.0:                 # 地面跳
			velocity.y = jump_velocity
			_jump_buffer = 0.0
			_coyote = 0.0
		elif _jumps_left > 0:             # 空中跳（二段跳）
			velocity.y = jump_velocity
			_jump_buffer = 0.0
			_jumps_left -= 1

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

func _can_dash() -> bool:
	return dash_enabled and _dash_cooldown <= 0.0

func _consume_dash_pressed() -> bool:
	var pressed := Input.is_action_pressed("dash")
	var just_pressed := pressed and not _dash_was_pressed
	_dash_was_pressed = pressed
	return just_pressed

func _enter_dash() -> void:
	_set_state(State.DASH)
	_state_timer = dash_duration
	_dash_cooldown = dash_cooldown
	velocity.x = _facing * dash_speed
	velocity.y = 0.0

func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_set_state(State.IDLE)

func _process_dash(delta: float) -> void:
	velocity.x = _facing * dash_speed
	velocity.y = 0.0
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
		State.DASH:
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
