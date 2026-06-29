extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const HudScene = preload("res://scenes/ui/hud.tscn")
const PartyManagerScript = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var pm := Node2D.new()
	pm.set_script(PartyManagerScript)
	var knight := KnightScene.instantiate(); knight.name = "Knight"
	var archer := ArcherScene.instantiate(); archer.name = "Archer"
	pm.add_child(knight)
	pm.add_child(archer)
	get_root().add_child(pm)
	await process_frame

	var hud := HudScene.instantiate()
	hud.party_manager = pm
	get_root().add_child(hud)
	await process_frame

	var avatar := hud.get_node("Root/Panel/HBox/Avatar") as TextureRect
	var bar := hud.get_node("Root/Panel/HBox/Info/HealthBar") as ProgressBar
	var vials_label := hud.get_node("Root/Panel/HBox/Info/VialRow/VialsLabel") as Label

	# 初始：Knight 头像 + 满血
	t.check(avatar.texture.resource_path.contains("knight"), "初始显示 Knight 头像")
	t.eq(int(bar.max_value), 40, "血条 max = Knight max_health")
	t.eq(int(bar.value), 40, "血条满")
	t.eq(vials_label.text, "x2", "HUD shows initial blood vials")

	# 切换到 Archer → 头像变 Archer，血条变 Archer 数值
	pm.switch_to_next()
	await process_frame
	t.check(avatar.texture.resource_path.contains("archer"), "切换后显示 Archer 头像")
	t.eq(int(bar.max_value), 25, "血条 max = Archer max_health")

	# Archer 扣血 → 血条 value 下降
	archer.get_health().take_damage(10)
	await process_frame
	t.eq(int(bar.value), 15, "Archer 扣血后血条下降")
	pm.use_vial()
	await process_frame
	t.eq(vials_label.text, "x1", "HUD updates after using a vial")

	quit(t.summary("test_hud"))
