class_name BoxSlot
extends Node2D

# 当推箱被推到缺口内（x 进入区间）时，把它吸附到与地面齐平的位置并冻结，
# 避免刚体悬在边缘卡住或翻倒，保证玩家能平滑走过。

@export var box: PushBox
@export var x_min: float = 4970.0          # 箱子中心进入此区间即视为"已推进缺口"
@export var x_max: float = 5040.0
@export var center_x: float = 5005.0       # 吸附后箱子居中的 x（缺口正中，两侧均匀）
@export var flush_center_y: float = 870.0  # 齐平时箱子中心的 y（顶面与地面同高）

func _physics_process(_delta: float) -> void:
	if box == null or box.is_locked():
		return
	var x := box.global_position.x
	if x >= x_min and x <= x_max:
		box.lock_into_slot(Vector2(center_x, flush_center_y))
