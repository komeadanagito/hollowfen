class_name PartyManager
extends Node2D

signal character_switched(character: CharacterBase)
signal character_unlocked(character: CharacterBase)

var _characters: Array[CharacterBase] = []
var _locked: Array[bool] = []
var _active_index: int = 0

func _ready() -> void:
	for child in get_children():
		if child is CharacterBase:
			_characters.append(child)
			_locked.append(false)
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

func set_locked(index: int, locked: bool) -> void:
	if index < 0 or index >= _locked.size():
		return
	_locked[index] = locked

func unlock(character: CharacterBase) -> void:
	var idx := _characters.find(character)
	if idx == -1 or not _locked[idx]:
		return
	_locked[idx] = false
	character_unlocked.emit(character)

func switch_to_next() -> void:
	if _characters.size() < 2:
		return
	var next_index := _next_unlocked_index()
	if next_index == _active_index:
		return
	var old := _characters[_active_index]
	_active_index = next_index
	var new_char := _characters[_active_index]
	new_char.global_position = old.global_position
	new_char.velocity = old.velocity
	old.set_active(false)
	new_char.set_active(true)
	character_switched.emit(new_char)

func _next_unlocked_index() -> int:
	var n := _characters.size()
	for step in range(1, n):
		var i := (_active_index + step) % n
		if not _locked[i]:
			return i
	return _active_index
