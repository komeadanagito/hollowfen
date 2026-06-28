class_name HomingNote
extends Area2D

@export var speed: float = 520.0
@export var damage: int = 3
@export var lifetime: float = 2.5
@export var turn_rate: float = 8.0
@export var max_pierce: int = 99   # 可穿透命中的敌人数量（穿透追踪）

var _dir: Vector2 = Vector2.RIGHT
var _target: Node2D
var _hits: int = 0
var _hit_boxes: Array = []   # 已命中的 hurtbox，避免重复命中/回头追同一个

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func launch(direction: Vector2) -> void:
	_dir = direction.normalized()
	if _dir.length() == 0.0:
		_dir = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target) or _is_hit_target(_target):
		_target = _find_target()
	if _target:
		var desired := ( _target.global_position - global_position ).normalized()
		_dir = _dir.lerp(desired, clampf(turn_rate * delta, 0.0, 1.0)).normalized()
	global_position += _dir * speed * delta
	rotation = _dir.angle()

func _is_hit_target(target: Node2D) -> bool:
	# 该敌人的 hurtbox 是否已被命中过
	var hb := target.get_node_or_null("Hurtbox")
	return hb != null and _hit_boxes.has(hb)

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node2D and is_instance_valid(node) and not _is_hit_target(node):
			var d := global_position.distance_squared_to((node as Node2D).global_position)
			if d < best_dist:
				best_dist = d
				best = node as Node2D
	return best

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit") and not _hit_boxes.has(area):
		area.receive_hit(damage)
		_hit_boxes.append(area)   # 记录已命中，穿透继续飞向下一个目标
		_hits += 1
		if _hits >= max_pierce:
			queue_free()

func _on_body_entered(_body: Node) -> void:
	queue_free()
