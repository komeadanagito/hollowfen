extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const PushBoxScene = preload("res://scenes/world/push_box.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var box := PushBoxScene.instantiate()
	get_root().add_child(box)
	await process_frame

	t.check(box is RigidBody2D, "push box is a rigid body")
	t.eq(box.mass, 8.0, "push box has stable mass")
	t.eq(box.collision_layer, 1, "push box sits on terrain layer")
	t.check(box.get_node_or_null("CollisionShape2D") is CollisionShape2D, "push box has collision")
	quit(t.summary("test_push_box"))
