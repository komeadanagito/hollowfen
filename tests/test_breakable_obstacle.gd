extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const ObstacleScene = preload("res://scenes/world/breakable_obstacle.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var obstacle := ObstacleScene.instantiate()
	get_root().add_child(obstacle)
	await process_frame

	t.check(obstacle.has_method("receive_hit"), "breakable obstacle can receive hits")
	t.eq(obstacle.is_broken, false, "obstacle starts intact")
	obstacle.receive_hit(10)
	t.eq(obstacle.is_broken, false, "weak hit does not break obstacle")
	obstacle.receive_hit(28)
	t.eq(obstacle.is_broken, true, "hammer-strength hit breaks obstacle")
	var shape := obstacle.get_node("CollisionShape2D") as CollisionShape2D
	t.eq(shape.disabled, true, "broken obstacle disables collision")
	quit(t.summary("test_breakable_obstacle"))
