extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const PortalScript = preload("res://scripts/systems/room_portal.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	# 假 Room：记录 depart 调用
	var fake_room := Node.new()
	fake_room.set_script(GDScript.new())
	# 用一个带 depart 的脚本
	var rs := GDScript.new()
	rs.source_code = "extends Node\nvar called := []\nfunc depart(rp, te):\n\tcalled = [rp, te]\n"
	rs.reload()
	fake_room.set_script(rs)
	fake_room.add_to_group("room")
	get_root().add_child(fake_room)

	var portal := Area2D.new(); portal.set_script(PortalScript)
	portal.entry_id = "from_b"; portal.target_room = "res://scenes/rooms/room_tutorial_b.tscn"; portal.target_entry = "from_a"
	get_root().add_child(portal)
	await process_frame
	var knight := KnightScene.instantiate(); get_root().add_child(knight); await process_frame
	knight.set_active(true)
	portal._on_body_entered(knight)
	t.eq(fake_room.called, ["res://scenes/rooms/room_tutorial_b.tscn", "from_a"], "进入 portal 调用 room.depart(目标房,目标入口)")
	t.eq(portal.get_entry_id(), "from_b", "get_entry_id 返回本入口")
	quit(t.summary("test_room_portal"))
