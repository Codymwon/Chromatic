class_name GameStateNode
extends Node

signal glow_toggled(enabled: bool)
signal sfx_toggled(enabled: bool)
signal sfx_volume_changed(volume: float)
signal haptics_toggled(enabled: bool)

const DEFAULT_SETTINGS_PATH: String = "user://settings.cfg"

var save_path: String = DEFAULT_SETTINGS_PATH

var glow_enabled: bool = true
var sfx_enabled: bool = true
var sfx_volume: float = 1.0
var haptics_enabled: bool = true

func _ready() -> void:
	load_settings()

func set_glow_enabled(p_enabled: bool) -> void:
	if glow_enabled != p_enabled:
		glow_enabled = p_enabled
		glow_toggled.emit(glow_enabled)
		save_settings()

func set_sfx_enabled(p_enabled: bool) -> void:
	if sfx_enabled != p_enabled:
		sfx_enabled = p_enabled
		sfx_toggled.emit(sfx_enabled)
		save_settings()

func set_sfx_volume(p_volume: float) -> void:
	var clamped: float = clampf(p_volume, 0.0, 1.0)
	if not is_equal_approx(sfx_volume, clamped):
		sfx_volume = clamped
		sfx_volume_changed.emit(sfx_volume)
		save_settings()

func set_haptics_enabled(p_enabled: bool) -> void:
	if haptics_enabled != p_enabled:
		haptics_enabled = p_enabled
		haptics_toggled.emit(haptics_enabled)
		save_settings()

func load_settings(path: String = "") -> void:
	if path != "":
		save_path = path

	var config := ConfigFile.new()
	var err: Error = config.load(save_path)
	if err == OK:
		glow_enabled = bool(config.get_value("graphics", "glow_enabled", true))
		sfx_enabled = bool(config.get_value("audio", "sfx_enabled", true))
		sfx_volume = float(config.get_value("audio", "sfx_volume", 1.0))
		haptics_enabled = bool(config.get_value("audio", "haptics_enabled", true))
	else:
		glow_enabled = true
		sfx_enabled = true
		sfx_volume = 1.0
		haptics_enabled = true

	glow_toggled.emit(glow_enabled)
	sfx_toggled.emit(sfx_enabled)
	sfx_volume_changed.emit(sfx_volume)
	haptics_toggled.emit(haptics_enabled)

func save_settings(path: String = "") -> void:
	if path != "":
		save_path = path

	var config := ConfigFile.new()
	config.set_value("graphics", "glow_enabled", glow_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "haptics_enabled", haptics_enabled)

	var err: Error = config.save(save_path)
	if err != OK:
		printerr("[GameState] Failed to write settings file: ", save_path, " error: ", err)
