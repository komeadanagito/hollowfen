class_name BreakableObstacle
extends StaticBody2D

@export var break_damage_threshold: int = 35
@export var passable_at_frame: int = 4   # 坍塌动画到第5帧（索引4）之后即可通行

var is_broken: bool = false
var _passable: bool = false

@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D")

func receive_hit(damage: int) -> void:
	if is_broken or damage < break_damage_threshold:
		return
	is_broken = true
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"collapse"):
		_sprite.play(&"collapse")
		_sprite.frame_changed.connect(_on_collapse_frame)
	else:
		_make_passable()

# 坍塌播放到第5帧后开启通行（之后的帧是碎石落定，仅作表现）
func _on_collapse_frame() -> void:
	if not _passable and _sprite and _sprite.frame >= passable_at_frame:
		_make_passable()

func _make_passable() -> void:
	if _passable:
		return
	_passable = true
	# receive_hit 在物理 flush 中触发，直接改 disabled 会被拒绝，用 deferred
	if _collision:
		_collision.set_deferred("disabled", true)
