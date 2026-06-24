extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const ExitScript = preload("res://scripts/world/level_exit.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var knight := KnightScene.instantiate()
	get_root().add_child(knight)
	await process_frame
	knight.set_active(true)

	var exit := Area2D.new()
	exit.set_script(ExitScript)
	var reached := {"count": 0}
	exit.reached.connect(func(): reached["count"] += 1)
	get_root().add_child(exit)
	await process_frame

	exit._on_body_entered(knight)
	exit._on_body_entered(knight)
	t.eq(reached["count"], 1, "出口只触发一次")

	quit(t.summary("test_level_exit"))
