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
const PROMPT := "res://scenes/world/prompt_zone.tscn"
const HUD := "res://scenes/ui/hud.tscn"
const TLAYER := "res://scenes/ui/tutorial_layer.tscn"

var _root: Node2D

func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "TutorialLevel"
	_root.set_script(load("res://scripts/world/tutorial_level.gd"))

	# ===== 地形 =====
	_solid("PH_Terrain_Ground", 6100, 832, 12600, 64, Color(0.13, 0.13, 0.16),
		"[物料] 类别=地形 | 占位=深灰长条 | 替换=沼泽地面 | 备注=连续地面顶面y=800")
	# 段1 跳跃教学块
	_plat("PH_Terrain_JumpBlock", 1000, 720, 160, 160, "跳跃教学")
	# 三个谜题平台（站此与对应 Switch 同高 y=580，射箭位）
	_plat("PH_Terrain_PlatformA", 3300, 650, 300, 150, "谜题A射箭平台")
	_plat("PH_Terrain_PlatformB", 5050, 650, 300, 150, "谜题B射箭平台")
	_plat("PH_Terrain_PlatformC", 9100, 650, 300, 150, "谜题C射箭平台")
	# 段5 弓手掩体柱
	_plat("PH_Terrain_Cover1", 6200, 560, 70, 240, "掩体: 躲弓手")
	# 段6 垂直平台
	_plat("PH_Terrain_Platform6", 7650, 600, 250, 200, "混战垂直平台")
	# 段8 跳跃高低差（两块带间隙）
	_plat("PH_Terrain_Step8a", 10000, 640, 180, 160, "跳台a")
	_plat("PH_Terrain_Step8b", 10450, 640, 180, 160, "跳台b")

	# ===== SpawnPoint =====
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(200, 740)
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

	# ===== 敌人（混编 史莱姆/剑哥布林/弓哥布林）=====
	var enemies := [
		[SLIME, 2300], [SLIME, 10250],
		[MELEE, 4500], [MELEE, 7400], [MELEE, 8700], [MELEE, 11000],
		[RANGED, 6700], [RANGED, 7900], [RANGED, 11300],
	]
	var ei := 0
	for e in enemies:
		ei += 1
		var node := _inst(e[0])
		node.name = "Enemy%d" % ei
		node.position = Vector2(e[1], 700)
		_add(node)

	# ===== 三个开关-门谜题 =====
	_switch("Switch_A", 3850); _door("Door_A", 3600)
	_switch("Switch_B", 5600); _door("Door_B", 5350)
	_switch("Switch_C", 9650); _door("Door_C", 9400)

	# ===== 解锁点 =====
	var pickup := _inst(PICKUP)
	pickup.name = "ArcherPickup"; pickup.position = Vector2(3450, 740)
	pickup.party_manager = pm; pickup.target_character = archer
	_add(pickup)

	# ===== 出口 =====
	var exit := _inst(EXIT); exit.name = "LevelExit"; exit.position = Vector2(11900, 704); _add(exit)

	# ===== 教程提示层 + 提示区 =====
	var tlayer := _inst(TLAYER); tlayer.name = "TutorialLayer"; _add(tlayer)
	_prompt("PZ_Move", 250, 700, "move", "← → 移动", tlayer)
	_prompt("PZ_Jump", 1000, 640, "jump", "Space 跳跃", tlayer)
	_prompt("PZ_Attack", 2300, 640, "attack", "J 攻击", tlayer)
	_prompt("PZ_Switch", 3450, 640, "switch", "Shift / Tab 切换角色", tlayer)
	_prompt("PZ_Shoot", 3300, 560, "shoot", "J 射箭（瞄准对面开关）", tlayer)

	# ===== 相机 + HUD =====
	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.set_script(load("res://scripts/world/camera_follow.gd"))
	cam.position = Vector2(200, 740)
	cam.party_manager = pm
	_add(cam)
	var hud := _inst(HUD); hud.name = "HUD"; hud.party_manager = pm; _add(hud)

	_root.party_manager = pm
	_root.tutorial_layer = tlayer

	var packed := PackedScene.new()
	var perr := packed.pack(_root)
	var serr := ResourceSaver.save(packed, "res://scenes/tutorial_level.tscn")
	print("[tutorial_level] pack=", perr, " save=", serr, " children=", _root.get_child_count())
	quit()

func _add(node: Node) -> void:
	_root.add_child(node)
	node.owner = _root

func _inst(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()

func _switch(nm: String, x: float) -> void:
	var s := _inst(SWITCH); s.name = nm; s.position = Vector2(x, 580); s.scale = Vector2(2, 2); _add(s)

func _door(nm: String, x: float) -> void:
	var d := _inst(DOOR); d.name = nm; d.position = Vector2(x, 700); d.scale = Vector2(2, 2.5); _add(d)

func _plat(nm: String, cx: float, top: float, w: float, h: float, note: String) -> void:
	_solid(nm, cx, top + h / 2.0, w, h, Color(0.18, 0.18, 0.22),
		"[物料] 类别=地形 | 占位=平台块 | 替换=石台 | 备注=" + note)

func _solid(nm: String, cx: float, cy: float, w: float, h: float, col: Color, desc: String) -> void:
	var body := StaticBody2D.new()
	body.name = nm
	body.position = Vector2(cx, cy)
	body.editor_description = desc
	_add(body)
	var c := CollisionShape2D.new()
	c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h)
	c.shape = r
	body.add_child(c); c.owner = _root
	var s := ColorRect.new()
	s.name = "Sprite"; s.color = col; s.size = Vector2(w, h); s.position = Vector2(-w / 2.0, -h / 2.0)
	body.add_child(s); s.owner = _root

func _prompt(nm: String, cx: float, cy: float, id: String, text: String, tlayer: Node) -> void:
	var pz := _inst(PROMPT)
	pz.name = nm; pz.position = Vector2(cx, cy)
	pz.prompt_id = id; pz.prompt_text = text; pz.tutorial_layer = tlayer
	_add(pz)
