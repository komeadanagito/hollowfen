class_name Bat
extends CharacterBody2D

@export var speed: float = 180.0            # 巡逻速度
@export var patrol_distance: float = 260.0
@export var detect_range: float = 420.0     # 进入此范围开始追击
@export var chase_speed: float = 320.0       # 追击速度（比玩家慢一点，可甩开）
@export var give_up_range: float = 620.0     # 超出此范围放弃追击回到巡逻

@onready var _health: Health = $Health
@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
var _start_x: float = 0.0
var _dir: int = 1
var _chasing: bool = false

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

func _physics_process(_delta: float) -> void:
	var target := _active_player()
	var dist := INF
	if target != null:
		dist = global_position.distance_to(target.global_position)

	# 进入侦测范围开始追击；只有飞出放弃范围才解除
	if not _chasing and dist <= detect_range:
		_chasing = true
	elif _chasing and dist > give_up_range:
		_chasing = false

	if _chasing and target != null:
		var to := (target.global_position - global_position).normalized()
		velocity = to * chase_speed
		_dir = 1 if to.x >= 0.0 else -1
	else:
		# 巡逻：左右往返 + 上下轻微浮动
		if absf(global_position.x - _start_x) > patrol_distance:
			_dir = -_dir
		velocity = Vector2(_dir * speed, sin(Time.get_ticks_msec() / 160.0) * 30.0)

	if _sprite:
		_sprite.flip_h = _dir < 0
	move_and_slide()

# 当前被操控的玩家角色（队伍切换时只有一个 active）
func _active_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is CharacterBase and (p as CharacterBase).is_active():
			return p as Node2D
	return null

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
	# 先播死亡动画，播完再移除
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"death"):
		_sprite.play(&"death")
		await _sprite.animation_finished
	queue_free()
