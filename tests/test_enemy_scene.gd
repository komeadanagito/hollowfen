extends SceneTree

# 敌人接线烟测：加载、Health、落地、巡逻移动、接触命中盒开启

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()

	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var fcol := CollisionShape2D.new()
	var fshape := RectangleShape2D.new()
	fshape.size = Vector2(600, 20)
	fcol.shape = fshape
	floor_body.add_child(fcol)
	floor_body.position = Vector2(0, 120)
	get_root().add_child(floor_body)

	var EnemyScene: PackedScene = load("res://scenes/enemies/patrol_enemy.tscn")
	t.check(EnemyScene != null, "patrol_enemy.tscn loads")
	var enemy: Node2D = EnemyScene.instantiate()
	enemy.position = Vector2(0, 80)
	get_root().add_child(enemy)
	await process_frame

	var health: Health = enemy.get_node("Health")
	t.eq(health.max_health, 30, "enemy max_health == 30")
	var contact: Hitbox = enemy.get_node("ContactHitbox")
	t.check(contact.monitoring, "contact hitbox is active after _ready")

	var x0: float = enemy.global_position.x
	for i in 30:
		await physics_frame
	t.check(enemy.is_on_floor(), "enemy stands on floor")
	t.check(absf(enemy.global_position.x - x0) > 5.0, "enemy patrols (moves horizontally)")

	floor_body.free()
	enemy.free()
	quit(t.summary("enemy_scene"))
