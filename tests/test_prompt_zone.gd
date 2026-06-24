extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const TutorialLayerScript = preload("res://scripts/ui/tutorial_layer.gd")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var layer := TutorialLayerScript.new()
	var panel := Control.new()
	panel.name = "Panel"
	var inner := Label.new()
	inner.name = "Text"
	panel.add_child(inner)
	layer.add_child(panel)
	get_root().add_child(layer)
	await process_frame

	layer.show_prompt("jump", "按 Space 跳跃")
	t.eq(layer.current_text(), "按 Space 跳跃", "show_prompt 显示文本")

	layer.dismiss("jump")
	t.eq(layer.current_text(), "", "dismiss 后隐藏")
	t.check(layer.is_done("jump"), "dismiss 标记完成")

	layer.show_prompt("jump", "按 Space 跳跃")
	t.eq(layer.current_text(), "", "已完成的 id 不再显示")

	quit(t.summary("test_prompt_zone"))
