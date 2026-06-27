extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const BonfireScene = preload("res://scenes/world/bonfire.tscn")
const PartyManagerScript = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")

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

	knight.get_health().take_damage(20)
	archer.get_health().take_damage(10)
	pm.use_vial()
	t.eq(pm.vials, 1, "setup consumed one vial")

	var bonfire := BonfireScene.instantiate()
	bonfire.party_manager = pm
	bonfire.global_position = Vector2(320, 700)
	get_root().add_child(bonfire)
	await process_frame

	t.check(bonfire.has_method("activate"), "bonfire exposes activate")
	bonfire.activate()
	t.eq(knight.get_health().current, knight.get_health().max_health, "bonfire heals knight")
	t.eq(archer.get_health().current, archer.get_health().max_health, "bonfire heals archer")
	t.eq(pm.vials, pm.max_vials, "bonfire refills vials")
	t.eq(pm.get_respawn_position(), bonfire.global_position, "bonfire records respawn position")
	t.check(pm.get_unlocked_bonfires().has(bonfire.global_position), "bonfire unlocks travel point")

	quit(t.summary("test_bonfire"))
