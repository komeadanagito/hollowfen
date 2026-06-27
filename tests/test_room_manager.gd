extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const RM = preload("res://scripts/systems/room_manager.gd")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	var rm = RM.new(); get_root().add_child(rm)
	# go_to 记录入口与房间（不真正切场景：用 set_change_enabled(false) 禁用 _change_enabled）
	rm.set_change_enabled(false)
	rm.go_to("res://scenes/rooms/room_tutorial_b.tscn", "from_a")
	t.eq(rm.pending_room, "res://scenes/rooms/room_tutorial_b.tscn", "记录目标房间")
	t.eq(rm.consume_entry(), "from_a", "consume_entry 取出入口")
	t.eq(rm.consume_entry(), "", "再次取出为空")
	quit(t.summary("test_room_manager"))
