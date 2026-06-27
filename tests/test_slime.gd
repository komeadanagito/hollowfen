extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const SlimeScene = preload("res://scenes/enemies/slime.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var slime := SlimeScene.instantiate()
	get_root().add_child(slime)
	await process_frame

	t.eq(slime.get_script().resource_path, "res://scripts/enemies/slime.gd", "slime uses slime script")
	t.check(slime.get_node_or_null("Hurtbox") is Hurtbox, "slime has hurtbox")
	t.check(slime.get_node_or_null("ContactHitbox") is Hitbox, "slime has contact hitbox")
	t.check(slime.speed <= 120.0, "slime is normal speed, not fast")
	var start_x: float = slime.global_position.x
	slime._physics_process(0.5)
	t.check(slime.global_position.x != start_x, "slime patrols slowly")
	t.check(slime.is_in_group("enemy"), "slime is in enemy group for revival totem")

	quit(t.summary("test_slime"))
