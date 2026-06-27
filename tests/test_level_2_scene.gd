extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const Scene = preload("res://scenes/level_2.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var root := Scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var pm := root.get_node_or_null("PartyManager")
	t.check(pm != null, "Level 2 has PartyManager")
	t.check(root.get_node_or_null("PartyManager/Knight") != null, "Level 2 has Knight")
	t.check(root.get_node_or_null("PartyManager/Archer") != null, "Level 2 has Archer")
	t.check(root.get_node_or_null("PartyManager/OcarinaGirl") != null, "Level 2 has OcarinaGirl")
	t.check(root.get_node_or_null("PartyManager/HammerWarrior") != null, "Level 2 has HammerWarrior")
	t.check(root.get_node_or_null("OcarinaPickup") != null, "Level 2 has ocarina pickup")
	t.check(root.get_node_or_null("HammerPickup") != null, "Level 2 has hammer pickup")
	t.check(root.get_node_or_null("Bonfire_Start") != null, "Level 2 has first bonfire")
	t.check(root.get_node_or_null("Bonfire_Final") != null, "Level 2 has final bonfire")
	t.check(root.get_node_or_null("Bat_1") != null, "Level 2 has bat in parkour")
	t.check(root.get_node_or_null("RevivalTotem_1") != null, "Level 2 has revival totem")
	t.check(root.get_node_or_null("BreakableObstacle") != null, "Level 2 has breakable obstacle")
	t.check(root.get_node_or_null("PushBox") != null, "Level 2 has push box")
	t.check(root.get_node_or_null("LevelExit") != null, "Level 2 has exit")

	var first = pm.get_active_character()
	pm.call("switch_to_index", 2)
	t.eq(pm.get_active_character(), first, "OcarinaGirl starts locked")
	pm.call("switch_to_index", 3)
	t.eq(pm.get_active_character(), first, "HammerWarrior starts locked")

	var ocarina := root.get_node("PartyManager/OcarinaGirl")
	root.get_node("OcarinaPickup")._on_body_entered(first)
	pm.call("switch_to_index", 2)
	t.eq(pm.get_active_character(), ocarina, "Ocarina pickup unlocks slot 3")

	var hammer := root.get_node("PartyManager/HammerWarrior")
	root.get_node("HammerPickup")._on_body_entered(ocarina)
	pm.call("switch_to_index", 3)
	t.eq(pm.get_active_character(), hammer, "Hammer pickup unlocks slot 4")

	root.queue_free()
	quit(t.summary("test_level_2_scene"))
