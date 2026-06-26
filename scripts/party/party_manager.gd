class_name PartyManager
extends Node2D

signal character_switched(character: CharacterBase)
signal character_unlocked(character: CharacterBase)
signal party_wiped   # 全员阵亡

var _characters: Array[CharacterBase] = []
var _locked: Array[bool] = []
var _dead: Array[bool] = []
var _active_index: int = 0

func _ready() -> void:
	for child in get_children():
		if child is CharacterBase:
			_characters.append(child)
			_locked.append(false)
			_dead.append(false)
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
	var next_index := _selectable_index()
	if next_index == _active_index:
		return
	var old := _characters[_active_index]
	_activate(next_index, old.global_position, old.velocity)
	old.set_active(false)

# 角色死亡：标记 + 切到存活角色（接管到死者最近的安全位置）；无人可切则全灭
func notify_death(character: CharacterBase) -> void:
	var idx := _characters.find(character)
	if idx == -1 or _dead[idx]:
		return
	_dead[idx] = true
	var safe := character.get_last_safe_position()
	character.set_active(false)
	if idx == _active_index:
		if not _switch_to_living(safe):
			party_wiped.emit()

func revive_all() -> void:
	for i in _dead.size():
		_dead[i] = false

func reset_to_first() -> void:
	_active_index = 0
	for i in _characters.size():
		_characters[i].set_active(i == 0)
	if not _characters.is_empty():
		character_switched.emit(_characters[0])

func _switch_to_living(at_pos: Vector2) -> bool:
	var n := _characters.size()
	for step in range(1, n + 1):
		var i := (_active_index + step) % n
		if not _dead[i] and not _locked[i]:
			_activate(i, at_pos, Vector2.ZERO)
			return true
	return false

func _activate(i: int, pos: Vector2, vel: Vector2) -> void:
	_active_index = i
	var c := _characters[i]
	c.global_position = pos
	c.velocity = vel
	c.set_active(true)
	character_switched.emit(c)

func _selectable_index() -> int:
	var n := _characters.size()
	for step in range(1, n):
		var i := (_active_index + step) % n
		if not _locked[i] and not _dead[i]:
			return i
	return _active_index
