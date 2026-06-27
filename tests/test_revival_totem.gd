extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const TotemScene = preload("res://scenes/enemies/revival_totem.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var totem := TotemScene.instantiate()
	get_root().add_child(totem)
	await process_frame

	var enemy := DummyRevivableEnemy.new()
	enemy.global_position = Vector2(20, 0)
	get_root().add_child(enemy)
	await process_frame
	enemy.health.take_damage(20)
	totem.pulse()
	t.check(enemy.health.current > 10, "totem heals living enemy in range")
	enemy.health.take_damage(999)
	t.check(enemy.health.is_dead(), "enemy can be killed before revive")
	totem.pulse()
	t.check(not enemy.health.is_dead(), "totem revives corpse in range")
	t.eq(enemy.revived, true, "totem calls revive hook")
	totem.receive_hit(999)
	t.eq(totem.is_destroyed, true, "totem can be destroyed")
	var after_destroy := enemy.health.current
	enemy.health.take_damage(5)
	totem.pulse()
	t.eq(enemy.health.current, after_destroy - 5, "destroyed totem stops pulsing")
	quit(t.summary("test_revival_totem"))

class DummyRevivableEnemy extends Node2D:
	var health := Health.new()
	var revived := false

	func _ready() -> void:
		add_to_group("enemy")
		add_child(health)
		health.max_health = 30
		health.reset()

	func get_health() -> Health:
		return health

	func can_revive_from_totem() -> bool:
		return health.is_dead()

	func revive_from_totem(amount: int) -> void:
		revived = true
		health.current = clampi(amount, 1, health.max_health)
		health.health_changed.emit(health.current, health.max_health)
