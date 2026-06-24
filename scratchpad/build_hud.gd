extends SceneTree

func _initialize() -> void:
	var root := CanvasLayer.new()
	root.name = "HUD"
	root.set_script(load("res://scripts/ui/hud.gd"))

	var margin := MarginContainer.new()
	margin.name = "Root"
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	root.add_child(margin); margin.owner = root

	var panel := PanelContainer.new()
	panel.name = "Panel"
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.05, 0.05, 0.08, 0.6)
	panel_sb.set_content_margin_all(10)
	panel_sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_sb)
	margin.add_child(panel); panel.owner = root

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox); hbox.owner = root

	var avatar := TextureRect.new()
	avatar.name = "Avatar"
	avatar.texture = load("res://assets/knight_avatar_head.png")
	avatar.custom_minimum_size = Vector2(96, 96)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(avatar); avatar.owner = root

	var info := VBoxContainer.new()
	info.name = "Info"
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(info); info.owner = root

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = "Knight"
	name_label.add_theme_font_size_override("font_size", 22)
	info.add_child(name_label); name_label.owner = root

	var bar := ProgressBar.new()
	bar.name = "HealthBar"
	bar.custom_minimum_size = Vector2(320, 26)
	bar.min_value = 0
	bar.max_value = 40
	bar.value = 40
	bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.05, 0.05)
	bar_bg.set_corner_radius_all(4)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.85, 0.2, 0.25)
	bar_fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bar_bg)
	bar.add_theme_stylebox_override("fill", bar_fill)
	info.add_child(bar); bar.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/ui/hud.tscn")
	print("[hud] pack=", perr, " save=", serr)
	quit()
