extends SceneTree

func _initialize() -> void:
	_build_tutorial_layer()
	_build_prompt_zone()
	quit()

func _own(root: Node, node: Node) -> void:
	node.owner = root

func _build_tutorial_layer() -> void:
	var root := CanvasLayer.new()
	root.name = "TutorialLayer"
	root.set_script(load("res://scripts/ui/tutorial_layer.gd"))

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.2
	panel.anchor_right = 0.8
	panel.anchor_top = 0.84
	panel.anchor_bottom = 0.94
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	root.add_child(panel)
	_own(root, panel)

	var label := Label.new()
	label.name = "Text"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	_own(root, label)

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/ui/tutorial_layer.tscn")
	print("[tutorial_layer] pack=", perr, " save=", serr)

func _build_prompt_zone() -> void:
	var root := Area2D.new()
	root.name = "PromptZone"
	root.set_script(load("res://scripts/ui/prompt_zone.gd"))
	root.collision_layer = 0
	root.collision_mask = 2  # 只检测 player_body

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(200, 400)
	col.shape = shape
	root.add_child(col)
	_own(root, col)

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/world/prompt_zone.tscn")
	print("[prompt_zone] pack=", perr, " save=", serr)
