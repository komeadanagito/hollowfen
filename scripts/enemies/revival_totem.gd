class_name RevivalTotem
extends StaticBody2D

@export var radius: float = 520.0
@export var heal_amount: int = 8
@export var revive_amount: int = 12
@export var max_health: int = 45

var is_destroyed: bool = false
var _health: Health

func _ready() -> void:
	add_to_group("enemy")
	_health = get_node_or_null("Health") as Health
	if _health:
		_health.max_health = max_health
		_health.reset()
		_health.died.connect(_on_died)

func get_health() -> Health:
	return _health

func receive_hit(damage: int) -> void:
	if _health:
		_health.take_damage(damage)

func pulse() -> void:
	if is_destroyed:
		return
	var revived_any := false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not (enemy is Node2D):
			continue
		if global_position.distance_to((enemy as Node2D).global_position) > radius:
			continue
		if enemy.has_method("can_revive_from_totem") and enemy.call("can_revive_from_totem"):
			enemy.call("revive_from_totem", revive_amount)
			revived_any = true
	if revived_any:
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not (enemy is Node2D):
			continue
		if global_position.distance_to((enemy as Node2D).global_position) > radius:
			continue
		if enemy.has_method("get_health"):
			var h := enemy.call("get_health") as Health
			if h and not h.is_dead():
				h.heal(heal_amount)

func _on_died() -> void:
	is_destroyed = true
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		cs.disabled = true
