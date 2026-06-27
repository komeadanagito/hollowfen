class_name CameraFollow
extends Camera2D

@export var party_manager: PartyManager
@export var smooth: float = 8.0

func _physics_process(delta: float) -> void:
	if party_manager == null:
		return
	var target := party_manager.get_active_character()
	if target == null:
		return
	var pos := global_position.lerp(target.global_position, clampf(smooth * delta, 0.0, 1.0))
	global_position = _clamp_to_limits(pos)

# 把相机中心夹在 limit 框内（按缩放算可见半幅），保证看不到关卡外
func _clamp_to_limits(pos: Vector2) -> Vector2:
	var vis := get_viewport_rect().size / zoom
	var half := vis * 0.5
	var x := pos.x
	var y := pos.y
	if limit_right - limit_left >= vis.x:
		x = clampf(pos.x, limit_left + half.x, limit_right - half.x)
	else:
		x = (limit_left + limit_right) * 0.5
	if limit_bottom - limit_top >= vis.y:
		y = clampf(pos.y, limit_top + half.y, limit_bottom - half.y)
	else:
		y = (limit_top + limit_bottom) * 0.5
	return Vector2(x, y)
