extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const RoomScript = preload("res://scripts/systems/room_base.gd")
const PortalScript = preload("res://scripts/systems/room_portal.gd")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	var room := Node2D.new(); room.set_script(RoomScript)
	# 两个入口锚点
	var p1 := Area2D.new(); p1.set_script(PortalScript); p1.entry_id = "from_a"; p1.position = Vector2(300, 700); p1.name = "PortalA"
	var p2 := Area2D.new(); p2.set_script(PortalScript); p2.entry_id = "from_c"; p2.position = Vector2(5000, 700); p2.name = "PortalC"
	room.add_child(p1); room.add_child(p2)
	get_root().add_child(room)
	await process_frame
	t.eq(room._entry_position("from_a"), Vector2(300, 700), "按 entry_id 找到入口位置")
	t.eq(room._entry_position("from_c"), Vector2(5000, 700), "找到另一个入口")
	# depart 会保存状态并请求切换（关掉真正 change）
	# 在 --script 模式下 autoload 名不可直接用作标识符，通过 get_node 访问
	var rm = get_root().get_node("RoomManager")
	rm.set_change_enabled(false)
	room.depart("res://scenes/rooms/room_tutorial_b.tscn", "from_a")
	t.eq(rm.pending_room, "res://scenes/rooms/room_tutorial_b.tscn", "depart 触发 RoomManager.go_to")
	quit(t.summary("test_room_base"))
