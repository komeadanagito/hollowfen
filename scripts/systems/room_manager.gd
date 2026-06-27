extends Node
# 房间切换：记录"从哪个入口出生"，再换场景（autoload 名 RoomManager）

var pending_entry: String = ""
var pending_room: String = ""
var _change_enabled: bool = true   # 测试时可关掉，避免真正 change_scene

func set_change_enabled(enabled: bool) -> void:
	_change_enabled = enabled

func go_to(room_path: String, entry_id: String) -> void:
	pending_room = room_path
	pending_entry = entry_id
	if _change_enabled:
		get_tree().change_scene_to_file(room_path)

func consume_entry() -> String:
	var e := pending_entry
	pending_entry = ""
	return e
