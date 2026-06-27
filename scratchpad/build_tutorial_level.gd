extends SceneTree

const KNIGHT := "res://scenes/characters/knight.tscn"
const ARCHER := "res://scenes/characters/archer.tscn"
const SLIME := "res://scenes/enemies/patrol_enemy.tscn"
const MELEE := "res://scenes/enemies/melee_goblin.tscn"
const RANGED := "res://scenes/enemies/ranged_goblin.tscn"
const SWITCH := "res://scenes/puzzle/switch.tscn"
const DOOR := "res://scenes/puzzle/door.tscn"
const PICKUP := "res://scenes/world/archer_pickup.tscn"
const EXIT := "res://scenes/world/level_exit.tscn"
const HUD := "res://scenes/ui/hud.tscn"

var _root: Node2D
var _font: Font

func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "TutorialLevel"
	_root.set_script(load("res://scripts/world/tutorial_level.gd"))
	_font = _tutorial_font()

	# ===== 背景（平铺地牢大厅，最底层）=====
	_tiled("Background", -500, -120, 8000, 1120, "res://assets/scene/background_far.png", -100)

	# ===== 天花板 + 吊灯（顶部，背景之上、玩法之下）=====
	# 注意：ceiling_decor.png 是坏图(白噪点)，已弃用
	_tiled("Ceiling", -500, 60, 8000, 230, "res://assets/scene/ceiling_stone.png", -40, 2.0)
	for cx in [600, 2400, 4200, 6000]:
		_deco("Chandelier_%d" % cx, cx, 360, "res://assets/scene/chandelier.png", -38)

	# ===== 地面（中间留一个深坑 x:2100~2500，掉下去秒死）=====
	_solid("PH_Terrain_GroundL", 800, 1000, 2600, 400, "res://assets/scene/floor_stone.png", "左侧地面 -500~2100", 2.0)
	_solid("PH_Terrain_GroundR", 5040, 1000, 4920, 400, "res://assets/scene/floor_stone.png", "右侧地面 2580~7500", 2.0)
	_plat("PH_Terrain_JumpBlock", 1000, 720, 160, 160, "跳跃教学")
	# 深坑死亡区（落入即死）；坑宽 480，单跳都过不了，只有剑士二段跳能过
	_death_zone(2340, 1080, 480, 360)

	# ===== SpawnPoint =====
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"; spawn.position = Vector2(200, 740)
	_add(spawn)

	# ===== PartyManager + Knight + Archer =====
	var pm := Node2D.new()
	pm.name = "PartyManager"
	pm.set_script(load("res://scripts/party/party_manager.gd"))
	_add(pm)
	var knight := _inst(KNIGHT); knight.name = "Knight"; knight.position = Vector2(200, 740)
	pm.add_child(knight); knight.owner = _root
	var archer := _inst(ARCHER); archer.name = "Archer"; archer.position = Vector2(200, 740)
	pm.add_child(archer); archer.owner = _root

	# ===== 敌人 =====
	_enemy(SLIME, "Enemy1", 1500)
	_enemy(RANGED, "Enemy2", 4900)
	_enemy(MELEE, "Enemy3", 5500)
	_enemy(SLIME, "Enemy4", 6000)
	_enemy(MELEE, "Enemy5", 6400)

	# ===== 伙伴立绘拾取 =====
	var pickup := _inst(PICKUP)
	pickup.name = "ArcherPickup"; pickup.position = Vector2(2700, 723)
	pickup.party_manager = pm; pickup.target_character = archer
	_add(pickup)

	# ===== 两道开关墙（开关放高处，需瞄准射击）=====
	_switch("Switch_A", 3500, 460)        # 高（在墙顶之上，需往上瞄；相机可见）
	_door("Door_A", 3560)
	_switch("Switch_B", 4450, 420)        # 更高
	_door("Door_B", 4500)

	# ===== 出口 =====
	var exit := _inst(EXIT); exit.name = "LevelExit"; exit.position = Vector2(6800, 704); _add(exit)

	# ===== 相机 + HUD =====
	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.set_script(load("res://scripts/systems/camera_follow.gd"))
	cam.position = Vector2(200, 740); cam.party_manager = pm
	cam.zoom = Vector2(1.5, 1.5)          # 拉近，玩家更大、空白更少
	cam.limit_left = -500                 # 封死左右上下，看不到关卡外
	cam.limit_right = 7500
	cam.limit_top = 120
	cam.limit_bottom = 1000
	_add(cam)
	var hud := _inst(HUD); hud.name = "HUD"; hud.party_manager = pm; _add(hud)

	# ===== 地图手绘指导文字（世界坐标，随相机滚动）=====
	_label("L_Move", 240, 600, "A / D  左右移动")
	_label("L_Jump", 900, 560, "Space  跳跃")
	_label("L_Attack", 1300, 560, "遇到敌人 — 鼠标攻击")
	_label("L_Pit", 2000, 540, "深坑！只有剑士二段跳能过")
	_label("L_Ally", 2470, 430, "遇到伙伴，Tab 替换角色")
	_label("L_Switch", 3020, 520, "鼠标瞄准射箭")
	_label("L_Shoot", 3120, 380, "墙挡路！射高处的开关\n墙会下降")
	_label("L_Shoot2", 4120, 340, "又一道墙\n打更高处的开关")
	_label("L_Goblin", 4780, 540, "小心：哥布林弓箭手")
	_label("L_Exit", 6650, 560, "终点 →")

	_root.party_manager = pm

	var packed := PackedScene.new()
	var perr := packed.pack(_root)
	var serr := ResourceSaver.save(packed, "res://scenes/tutorial_level.tscn")
	print("[tutorial_level] pack=", perr, " save=", serr, " children=", _root.get_child_count())
	quit()

func _tutorial_font() -> Font:
	# 用户把手绘字体丢到 assets/handdrawn.(ttf|otf|ttc) 即自动启用
	for ext in ["ttf", "otf", "ttc"]:
		var p := "res://assets/handdrawn." + str(ext)
		if ResourceLoader.exists(p):
			return load(p)
	var sf := SystemFont.new()   # 暂用：拉丁手写体 + 中文回退
	sf.font_names = PackedStringArray(["Chalkduster", "Hiragino Sans GB", "PingFang SC", "Heiti SC"])
	return sf

func _label(nm: String, x: float, y: float, text: String) -> void:
	var lbl := Label.new()
	lbl.name = nm
	lbl.text = text
	lbl.position = Vector2(x, y)
	lbl.z_index = 10
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))   # 米白"粉笔"色
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	lbl.add_theme_constant_override("outline_size", 10)
	lbl.add_theme_constant_override("line_spacing", 4)
	_add(lbl)

func _enemy(scene: String, nm: String, x: float) -> void:
	var e := _inst(scene); e.name = nm; e.position = Vector2(x, 700); _add(e)

func _death_zone(cx: float, cy: float, w: float, h: float) -> void:
	var a := Area2D.new(); a.name = "DeathZone"
	a.collision_layer = 0
	a.collision_mask = 2          # 只检测玩家 body
	a.position = Vector2(cx, cy)
	_add(a)
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	a.add_child(c); c.owner = _root

func _add(node: Node) -> void:
	_root.add_child(node); node.owner = _root

func _inst(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()

func _switch(nm: String, x: float, y: float) -> void:
	var s := _inst(SWITCH); s.name = nm; s.position = Vector2(x, y); s.scale = Vector2(2, 2); _add(s)

func _door(nm: String, x: float) -> void:
	# 高墙：碰撞跨 y 340~820，盖过剑士二段跳脚部峰值(~398)，单跳/二段都跳不过；开关在墙左侧仍可射
	var d := _inst(DOOR); d.name = nm; d.position = Vector2(x, 580); d.scale = Vector2(2.5, 6); _add(d)

func _plat(nm: String, cx: float, top: float, w: float, h: float, note: String) -> void:
	_solid(nm, cx, top + h / 2.0, w, h, "res://assets/scene/stone_block.png", note)

func _solid(nm: String, cx: float, cy: float, w: float, h: float, tex: String, note: String, tile_scale: float = 1.0) -> void:
	var body := StaticBody2D.new()
	body.name = nm; body.position = Vector2(cx, cy)
	body.editor_description = "[物料] 类别=地形 | 贴图=" + tex + " | 备注=" + note
	_add(body)
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	body.add_child(c); c.owner = _root
	# 平铺贴图填满该实体；tile_scale 放大每块砖（缩放精灵 + 缩小采样区域，覆盖不变）
	var s := Sprite2D.new(); s.name = "Sprite"
	s.texture = load(tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.centered = false
	s.scale = Vector2(tile_scale, tile_scale)
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, w / tile_scale, h / tile_scale)
	s.position = Vector2(-w / 2.0, -h / 2.0)
	body.add_child(s); s.owner = _root

func _tiled(nm: String, x: float, y: float, w: float, h: float, tex: String, z: int, tile_scale: float = 1.0) -> void:
	var s := Sprite2D.new(); s.name = nm
	s.texture = load(tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.centered = false
	s.scale = Vector2(tile_scale, tile_scale)
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, w / tile_scale, h / tile_scale)
	s.position = Vector2(x, y)
	s.z_index = z
	_add(s)

func _deco(nm: String, cx: float, cy: float, tex: String, z: int) -> void:
	var s := Sprite2D.new(); s.name = nm
	s.texture = load(tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = Vector2(cx, cy)
	s.z_index = z
	_add(s)
