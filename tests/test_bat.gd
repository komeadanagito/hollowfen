extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const BatScene = preload("res://scenes/enemies/bat.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var bat := BatScene.instantiate()
	get_root().add_child(bat)
	await process_frame

	t.eq(bat.get_script().resource_path, "res://scripts/enemies/bat.gd", "bat uses bat script")
	t.check(bat.get_node_or_null("Hurtbox") is Hurtbox, "bat has hurtbox")
	t.check(bat.get_node_or_null("ContactHitbox") is Hitbox, "bat has contact hitbox")
	var start_x: float = bat.global_position.x
	bat._physics_process(0.5)
	t.check(bat.global_position.x != start_x, "bat patrols in air")
	quit(t.summary("test_bat"))
