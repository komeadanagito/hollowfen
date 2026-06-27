extends SceneTree

const KNIGHT  := "res://scenes/characters/knight.tscn"
const ARCHER  := "res://scenes/characters/archer.tscn"
const MELEE   := "res://scenes/enemies/melee_goblin.tscn"
const RANGED  := "res://scenes/enemies/ranged_goblin.tscn"
const SLIME   := "res://scenes/enemies/patrol_enemy.tscn"
const SWITCH  := "res://scenes/puzzle/switch.tscn"
const DOOR    := "res://scenes/puzzle/door.tscn"
const EXIT    := "res://scenes/world/level_exit.tscn"
const HUD     := "res://scenes/ui/hud.tscn"
const PORTAL  := "res://scenes/entities/props/room_portal.tscn"

var _root: Node2D
var _font: Font

func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "RoomTutorialB"
	_root.set_script(load("res://scripts/systems/room_base.gd"))
	_font = _tutorial_font()

	# Room B starts at x=0, content spans 0~4000
	# === Background ===
	_tiled("Background", -200, -120, 4500, 1120, "res://assets/scene/background_far.png", -100)

	# === Ceiling ===
	_tiled("Ceiling", -200, 60, 4500, 230, "res://assets/scene/ceiling_stone.png", -40, 2.0)
	for cx in [800, 2600]:
		_deco("Chandelier_%d" % cx, cx, 360, "res://assets/scene/chandelier.png", -38)

	# === Ground ===
	# Full ground x=-200~4200 (width 4400, center at 2000)
	_solid("PH_Terrain_Ground", 2000, 1000, 4400, 400, "res://assets/scene/floor_stone.png", "Room B ground", 2.0)

	# Elevated platform for switch
	_plat("PH_Platform_Switch", 2500, 680, 200, 80, "Switch platform")

	# === SpawnPoint (safety net for direct scene opens / missing entry_id) ===
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"; spawn.position = Vector2(200, 700)
	_add(spawn)

	# === Left entry portal (from_a) — where players arrive from Room A ===
	var portal_left := _inst(PORTAL)
	portal_left.name = "Portal_FromA"
	portal_left.position = Vector2(100, 700)
	portal_left.entry_id = "from_a"
	portal_left.target_room = "res://scenes/rooms/room_tutorial_a.tscn"
	portal_left.target_entry = "from_b"
	_add(portal_left)

	# === PartyManager + Knight + Archer ===
	var pm := Node2D.new()
	pm.name = "PartyManager"
	pm.set_script(load("res://scripts/party/party_manager.gd"))
	_add(pm)
	var knight := _inst(KNIGHT); knight.name = "Knight"; knight.position = Vector2(100, 700)
	pm.add_child(knight); knight.owner = _root
	var archer := _inst(ARCHER); archer.name = "Archer"; archer.position = Vector2(100, 700)
	pm.add_child(archer); archer.owner = _root

	# === Enemies: goblins ===
	_enemy(RANGED, "Enemy1", 900)
	_enemy(MELEE,  "Enemy2", 1600)
	_enemy(SLIME,  "Enemy3", 2200)
	_enemy(RANGED, "Enemy4", 3000)
	_enemy(MELEE,  "Enemy5", 3400)

	# === Second switch+door wall ===
	_switch("Switch_B", 2550, 420)
	_door("Door_B", 2600)

	# === Level exit ===
	var exit := _inst(EXIT); exit.name = "LevelExit"; exit.position = Vector2(3800, 704); _add(exit)

	# === Camera + HUD ===
	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.set_script(load("res://scripts/systems/camera_follow.gd"))
	cam.position = Vector2(100, 700); cam.party_manager = pm
	cam.zoom = Vector2(1.5, 1.5)
	cam.limit_left = -200
	cam.limit_right = 4200
	cam.limit_top = 120
	cam.limit_bottom = 1000
	_add(cam)
	var hud := _inst(HUD); hud.name = "HUD"; hud.party_manager = pm; _add(hud)

	# === Labels ===
	_label("L_FromA",   -50,  540, "<- Room A")
	_label("L_Goblins", 800,  540, "Goblins! Watch the arrows")
	_label("L_Switch2", 2180, 520, "Another wall — shoot higher")
	_label("L_Exit",    3600, 540, "Exit ->")

	# === Root exports ===
	_root.party_manager = pm
	_root.default_entry = "from_a"   # default landing point: left portal

	var packed := PackedScene.new()
	var perr := packed.pack(_root)
	var serr := ResourceSaver.save(packed, "res://scenes/rooms/room_tutorial_b.tscn")
	print("[room_tutorial_b] pack=", perr, " save=", serr, " children=", _root.get_child_count())
	quit()

func _tutorial_font() -> Font:
	for ext in ["ttf", "otf", "ttc"]:
		var p := "res://assets/handdrawn." + str(ext)
		if ResourceLoader.exists(p):
			return load(p)
	var sf := SystemFont.new()
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
	lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	lbl.add_theme_constant_override("outline_size", 10)
	lbl.add_theme_constant_override("line_spacing", 4)
	_add(lbl)

func _enemy(scene: String, nm: String, x: float) -> void:
	var e := _inst(scene); e.name = nm; e.position = Vector2(x, 700); _add(e)

func _add(node: Node) -> void:
	_root.add_child(node); node.owner = _root

func _inst(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()

func _switch(nm: String, x: float, y: float) -> void:
	var s := _inst(SWITCH); s.name = nm; s.position = Vector2(x, y); s.scale = Vector2(2, 2); _add(s)

func _door(nm: String, x: float) -> void:
	var d := _inst(DOOR); d.name = nm; d.position = Vector2(x, 580); d.scale = Vector2(2.5, 6); _add(d)

func _plat(nm: String, cx: float, top: float, w: float, h: float, note: String) -> void:
	_solid(nm, cx, top + h / 2.0, w, h, "res://assets/scene/stone_block.png", note)

func _solid(nm: String, cx: float, cy: float, w: float, h: float, tex: String, note: String, tile_scale: float = 1.0) -> void:
	var body := StaticBody2D.new()
	body.name = nm; body.position = Vector2(cx, cy)
	body.editor_description = "[Terrain] tex=" + tex + " note=" + note
	_add(body)
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	body.add_child(c); c.owner = _root
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
