extends SceneTree

func _initialize() -> void:
	var root := Area2D.new()
	root.name = "LevelExit"
	root.set_script(load("res://scripts/world/level_exit.gd"))
	root.collision_layer = 0
	root.collision_mask = 2

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96, 192)
	col.shape = shape
	root.add_child(col)
	col.owner = root

	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = Color(0.4, 0.6, 1.0)
	sprite.size = Vector2(96, 192)
	sprite.position = Vector2(-48, -96)
	sprite.editor_description = "[物料] 类别=出口 | 占位=蓝块96x192 PH_Exit_Gate | 替换=关卡门/传送 | 备注=关卡终点"
	root.add_child(sprite)
	sprite.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/world/level_exit.tscn")
	print("[level_exit] pack=", perr, " save=", serr)
	quit()
