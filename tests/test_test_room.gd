extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var room_script := load("res://scripts/world/test_room.gd")
	t.check(room_script != null, "test room script loads")
	if room_script == null:
		quit(t.summary("test_room"))
		return

	var room := Node2D.new()
	room.name = "TestRoom"
	room.set_script(room_script)

	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(32, 64)
	room.add_child(spawn)

	var manager := PartyManager.new()
	manager.name = "PartyManager"
	room.add_child(manager)
	var character := _make_char()
	character.global_position = Vector2(200, 64)
	manager.add_child(character)
	room.set("party_manager", manager)

	get_root().add_child(room)
	await process_frame

	var health := character.get_health()
	health.take_damage(999)
	t.eq(character.global_position, spawn.global_position, "dead character respawns at spawn point")
	t.eq(health.current, health.max_health, "dead character respawns with full health")
	room.free()

	var packed := load("res://scenes/test_room.tscn") as PackedScene
	t.check(packed != null, "test room scene loads")
	if packed:
		var scene: Node = packed.instantiate()
		t.check(scene.get_node_or_null("SpawnPoint") != null, "scene has SpawnPoint")
		t.check(scene.get_node_or_null("PartyManager") != null, "scene has PartyManager")
		t.check(scene.get_node_or_null("Switch") != null, "scene has Switch")
		t.check(scene.get_node_or_null("Door") != null, "scene has Door")
		t.check(scene.get_node_or_null("HUD") != null, "scene has HUD")
		get_root().add_child(scene)
		await process_frame
		var scene_switch := scene.get_node("Switch") as Switch
		var scene_door := scene.get_node("Door") as Door
		scene_switch.receive_hit(1)
		t.eq(scene_door.is_open, true, "scene switch opens scene door")
		scene.free()
		await process_frame

	t.eq(ProjectSettings.get_setting("application/run/main_scene", ""), "res://scenes/test_room.tscn", "main scene points to test room")
	quit(t.summary("test_room"))

func _make_char() -> CharacterBase:
	var c := CharacterBase.new()
	var h := Health.new()
	h.name = "Health"
	h.max_health = 20
	c.add_child(h)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.health = h
	c.add_child(hb)
	return c
