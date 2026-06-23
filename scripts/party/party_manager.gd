class_name PartyManager
extends Node2D

signal character_switched(character: CharacterBase)

var _characters: Array[CharacterBase] = []
var _active_index: int = 0

func _ready() -> void:
	for child in get_children():
		if child is CharacterBase:
			_characters.append(child)
	for i in _characters.size():
		_characters[i].set_active(i == 0)
	_active_index = 0
	if not _characters.is_empty():
		character_switched.emit(_characters[0])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_character"):
		switch_to_next()

func get_active_character() -> CharacterBase:
	if _characters.is_empty():
		return null
	return _characters[_active_index]

func switch_to_next() -> void:
	if _characters.size() < 2:
		return
	var old := _characters[_active_index]
	_active_index = (_active_index + 1) % _characters.size()
	var new_char := _characters[_active_index]
	new_char.global_position = old.global_position
	new_char.velocity = old.velocity
	old.set_active(false)
	new_char.set_active(true)
	character_switched.emit(new_char)
