extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const OcarinaScene = preload("res://scenes/characters/ocarina_girl.tscn")
const NoteScene = preload("res://scenes/combat/homing_note.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var girl: CharacterBase = OcarinaScene.instantiate()
	get_root().add_child(girl)
	await process_frame

	t.eq(girl.get_script().resource_path, "res://scripts/characters/ocarina_girl.gd", "ocarina girl scene uses OcarinaGirl script")
	t.eq(girl.move_speed, 300.0, "ocarina girl is slow")
	t.eq(girl.jump_velocity, -520.0, "ocarina girl has low jump")
	t.eq(girl.get_health().max_health, 30, "ocarina girl health")
	girl.get_health().take_damage(20)
	girl._do_attack()
	t.check(girl.get_health().current > 10, "ocarina attack heals self")

	var note := NoteScene.instantiate()
	t.eq(note.get_script().resource_path, "res://scripts/combat/homing_note.gd", "homing note scene uses HomingNote script")
	t.eq(note.damage, 3, "homing note low damage")
	note.free()
	girl.free()
	quit(t.summary("test_ocarina_girl"))
