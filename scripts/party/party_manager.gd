class_name PartyManager
extends Node2D

signal character_switched(character: CharacterBase)
signal character_unlocked(character: CharacterBase)
signal vials_changed(current: int, maximum: int)
signal party_wiped   # 全员阵亡

@export var max_vials: int = 2
@export_range(0.0, 1.0) var vial_heal_ratio: float = 0.5

var vials: int = 2
var _characters: Array[CharacterBase] = []
var _locked: Array[bool] = []
var _dead: Array[bool] = []
var _active_index: int = 0
var _respawn_position: Vector2 = Vector2.ZERO
var _unlocked_bonfires: Array[Vector2] = []

func _ready() -> void:
	vials = max_vials
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
	if event.is_action_pressed("select_character_1"):
		switch_to_index(0)
	elif event.is_action_pressed("select_character_2"):
		switch_to_index(1)
	elif event.is_action_pressed("select_character_3"):
		switch_to_index(2)
	elif event.is_action_pressed("select_character_4"):
		switch_to_index(3)

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

func use_vial() -> bool:
	if vials <= 0:
		return false
	var character := get_active_character()
	if character == null or character.get_health() == null:
		return false
	var health := character.get_health()
	if health.is_dead() or health.current >= health.max_health:
		return false
	vials -= 1
	var amount := maxi(1, int(round(health.max_health * vial_heal_ratio)))
	health.heal(amount)
	vials_changed.emit(vials, max_vials)
	return true

func refill_vials() -> void:
	vials = max_vials
	vials_changed.emit(vials, max_vials)

func heal_all() -> void:
	for character in _characters:
		var health := character.get_health()
		if health:
			health.reset()

func activate_bonfire(position: Vector2) -> void:
	_respawn_position = position
	if not _unlocked_bonfires.has(position):
		_unlocked_bonfires.append(position)
	heal_all()
	refill_vials()

func get_respawn_position() -> Vector2:
	return _respawn_position

func get_unlocked_bonfires() -> Array[Vector2]:
	return _unlocked_bonfires.duplicate()

func travel_to_bonfire(position: Vector2) -> bool:
	if not _unlocked_bonfires.has(position):
		return false
	var active := get_active_character()
	for character in _characters:
		character.global_position = position
		character.velocity = Vector2.ZERO
	if active:
		active.global_position = position
	return true

func switch_to_next() -> void:
	if _characters.size() < 2:
		return
	var next_index := _selectable_index()
	if next_index == _active_index:
		return
	var old := _characters[_active_index]
	_activate_at_feet(next_index, old.global_position, old.velocity, old.get_feet_global_y())
	old.set_active(false)

func switch_to_index(index: int) -> void:
	if index < 0 or index >= _characters.size():
		return
	if _locked[index] or _dead[index] or index == _active_index:
		return
	var old := _characters[_active_index]
	_activate_at_feet(index, old.global_position, old.velocity, old.get_feet_global_y())
	old.set_active(false)

# 角色死亡：标记 + 切到存活角色（接管到死者最近的安全位置）；无人可切则全灭
func notify_death(character: CharacterBase) -> void:
	var idx := _characters.find(character)
	if idx == -1 or _dead[idx]:
		return
	_dead[idx] = true
	var safe := character.get_last_safe_position()
	var safe_feet_y := character.get_feet_global_y_at(safe)
	character.set_active(false)
	if idx == _active_index:
		if not _switch_to_living(safe, safe_feet_y):
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

func _switch_to_living(at_pos: Vector2, feet_y: float) -> bool:
	var n := _characters.size()
	for step in range(1, n + 1):
		var i := (_active_index + step) % n
		if not _dead[i] and not _locked[i]:
			_activate_at_feet(i, at_pos, Vector2.ZERO, feet_y)
			return true
	return false

func _activate_at_feet(i: int, pos: Vector2, vel: Vector2, feet_y: float) -> void:
	var c := _characters[i]
	_activate(i, c.get_position_for_feet(pos, feet_y), vel)

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

func get_characters() -> Array[CharacterBase]:
	return _characters.duplicate()

func is_unlocked(character: CharacterBase) -> bool:
	var idx := _characters.find(character)
	return idx != -1 and not _locked[idx]

func set_unlocked(character: CharacterBase, unlocked: bool) -> void:
	var idx := _characters.find(character)
	if idx != -1:
		_locked[idx] = not unlocked
