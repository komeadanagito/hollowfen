extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const HammerScene = preload("res://scenes/characters/hammer_warrior.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var hammer: CharacterBase = HammerScene.instantiate()
	get_root().add_child(hammer)
	await process_frame

	t.eq(hammer.get_script().resource_path, "res://scripts/characters/hammer_warrior.gd", "hammer scene uses HammerWarrior script")
	t.eq(hammer.move_speed, 400.0, "hammer is slower than knight")
	t.eq(hammer.jump_velocity, -760.0, "hammer jumps a bit farther than archer")
	t.eq(hammer.get_health().max_health, 55, "hammer is sturdy")
	var hitbox := hammer.get_node("MeleeHitbox") as Hitbox
	t.eq(hitbox.damage, 40, "hammer has highest damage")
	hammer.free()
	quit(t.summary("test_hammer_warrior"))
