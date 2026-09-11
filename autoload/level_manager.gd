class_name LevelManagerNode
extends Node

signal level_changed(index: int, level_data: Dictionary)
signal progression_updated(unlocked_level: int, completed_levels: Array[String])

const DEFAULT_LEVELS_PATH: String = "res://scenes/level/levels.json"
const DEFAULT_SAVE_PATH: String = "user://save.cfg"

var save_path: String = DEFAULT_SAVE_PATH
var levels_path: String = DEFAULT_LEVELS_PATH

var levels_data: Array[Dictionary] = []
var levels_version: int = 1
var current_level_index: int = 0
var unlocked_level: int = 1
var completed_levels: Array[String] = []

func _ready() -> void:
	load_levels_json(levels_path)
	load_save_data()

func load_levels_json(path: String = DEFAULT_LEVELS_PATH) -> bool:
	levels_path = path
	levels_data.clear()
	if not FileAccess.file_exists(path):
		printerr("[LevelManager] Levels JSON file not found: ", path)
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("[LevelManager] Failed to open levels JSON: ", path)
		return false

	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		printerr("[LevelManager] Invalid JSON root format in: ", path)
		return false

	var dict: Dictionary = parsed as Dictionary
	levels_version = int(dict.get("version", 1))
	assert(levels_version == 1, "[LevelManager] Unsupported schema version: " + str(levels_version))
	var raw_levels: Array = dict.get("levels", [])
	for lvl in raw_levels:
		if lvl is Dictionary:
			levels_data.append(lvl as Dictionary)

	return true

func get_level_count() -> int:
	return levels_data.size()

func get_level_data(index: int) -> Dictionary:
	if index >= 0 and index < levels_data.size():
		return levels_data[index]
	return {}

func get_level_data_by_id(id: String) -> Dictionary:
	for lvl in levels_data:
		if lvl.get("id") == id:
			return lvl
	return {}

func get_current_level_data() -> Dictionary:
	return get_level_data(current_level_index)

func set_current_level(index: int) -> bool:
	if index >= 0 and index < levels_data.size():
		current_level_index = index
		level_changed.emit(current_level_index, get_current_level_data())
		return true
	return false

func load_save_data() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(save_path)
	if err == OK:
		unlocked_level = int(config.get_value("progression", "unlocked_level", 1))
		var saved_completed: Variant = config.get_value("progression", "completed_levels", [])
		completed_levels.clear()
		if saved_completed is Array:
			for item in (saved_completed as Array):
				completed_levels.append(str(item))
	else:
		unlocked_level = 1
		completed_levels.clear()
	progression_updated.emit(unlocked_level, completed_levels)

func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("progression", "unlocked_level", unlocked_level)
	config.set_value("progression", "completed_levels", completed_levels)
	var err: Error = config.save(save_path)
	if err != OK:
		printerr("[LevelManager] Failed to write save file: ", save_path, " error: ", err)
	progression_updated.emit(unlocked_level, completed_levels)

func complete_current_level() -> void:
	var cur: Dictionary = get_current_level_data()
	var cur_id: String = cur.get("id", "")
	if cur_id != "" and not completed_levels.has(cur_id):
		completed_levels.append(cur_id)

	# Unlock next level if currently on highest unlocked stage
	if current_level_index + 1 >= unlocked_level and unlocked_level < get_level_count():
		unlocked_level = current_level_index + 2

	save_game()

func load_next_level() -> bool:
	if current_level_index + 1 < get_level_count():
		current_level_index += 1
		level_changed.emit(current_level_index, get_current_level_data())
		return true
	return false

func has_next_level() -> bool:
	return current_level_index + 1 < get_level_count()
