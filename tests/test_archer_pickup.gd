extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const PickupScript = preload("res://scripts/world/archer_pickup.gd")
const PartyManagerScript = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")
const ArcherPickupScene = preload("res://scenes/world/archer_pickup.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var pm := Node2D.new()
	pm.set_script(PartyManagerScript)
	var knight := KnightScene.instantiate()
	var archer := ArcherScene.instantiate()
	pm.add_child(knight)
	pm.add_child(archer)
	get_root().add_child(pm)
	await process_frame
	pm.set_locked(1, true)

	var pickup := Area2D.new()
	pickup.set_script(PickupScript)
	pickup.party_manager = pm
	pickup.target_character = archer
	var picked := {"hit": false}
	pickup.picked_up.connect(func(): picked["hit"] = true)
	get_root().add_child(pickup)
	await process_frame

	# 直接调用进入逻辑（模拟 body_entered）
	pickup._on_body_entered(knight)
	pm.switch_to_next()
	t.check(pm.get_active_character() == archer, "触碰后 archer 解锁可切")
	t.check(picked["hit"], "发出 picked_up 信号")

	var pickup_scene := ArcherPickupScene.instantiate()
	var sprite := pickup_scene.get_node_or_null("Sprite") as Sprite2D
	t.check(sprite != null, "archer pickup has portrait sprite")
	if sprite:
		t.check(sprite.position.y >= 20.0, "archer pickup portrait is lowered to sit on the ground")
	pickup_scene.free()

	quit(t.summary("test_archer_pickup"))
