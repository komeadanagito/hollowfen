class_name PromptZone
extends Area2D

@export var prompt_id: String = ""
@export var prompt_text: String = ""
@export var tutorial_layer: TutorialLayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if tutorial_layer == null:
		return
	if body is CharacterBase and (body as CharacterBase).is_active():
		tutorial_layer.show_prompt(prompt_id, prompt_text)

func complete() -> void:
	if tutorial_layer:
		tutorial_layer.dismiss(prompt_id)
