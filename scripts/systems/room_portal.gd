class_name RoomPortal
extends Area2D

@export var entry_id: String = ""
@export var target_room: String = ""
@export var target_entry: String = ""
@export var required_ability: String = ""   # 能力门禁（本期不判定，仅占位）

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func get_entry_id() -> String:
	return entry_id

func _on_body_entered(body: Node) -> void:
	if _used or target_room == "":
		return
	if not (body is CharacterBase and (body as CharacterBase).is_active()):
		return
	var room := get_tree().get_first_node_in_group("room")
	if room and room.has_method("depart"):
		_used = true
		room.depart(target_room, target_entry)
