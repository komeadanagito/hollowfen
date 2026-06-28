class_name BreakableHitArea
extends Area2D

# 破障墙本体是 StaticBody2D（terrain 层，用于阻挡），武器 Hitbox 检测的是 Area。
# 这个子 Area 放在 puzzle_target 层(128)、可被监测，命中后把伤害转发给父级破障墙。

func receive_hit(damage: int) -> void:
	var p := get_parent()
	if p and p.has_method("receive_hit"):
		p.receive_hit(damage)
