class_name PauseMenu
extends CanvasLayer

signal resume_requested
signal restart_requested
signal level_select_requested

@onready var backdrop: ColorRect = get_node_or_null("Backdrop") as ColorRect
@onready var title_label: Label = get_node_or_null("CenterContainer/Panel/VBoxContainer/TitleLabel") as Label
@onready var glow_button: Button = get_node_or_null("CenterContainer/Panel/VBoxContainer/GlowButton") as Button
@onready var sfx_button: Button = get_node_or_null("CenterContainer/Panel/VBoxContainer/SFXButton") as Button
@onready var resume_button: Button = get_node_or_null("CenterContainer/Panel/VBoxContainer/ResumeButton") as Button
@onready var restart_button: Button = get_node_or_null("CenterContainer/Panel/VBoxContainer/RestartButton") as Button
@onready var level_select_button: Button = get_node_or_null("CenterContainer/Panel/VBoxContainer/LevelSelectButton") as Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_connect_buttons()
	_update_toggle_buttons()

	if is_inside_tree():
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state != null:
			if game_state.has_signal("glow_toggled") and not game_state.glow_toggled.is_connected(_on_glow_toggled):
				game_state.glow_toggled.connect(_on_glow_toggled)
			if game_state.has_signal("sfx_toggled") and not game_state.sfx_toggled.is_connected(_on_sfx_toggled):
				game_state.sfx_toggled.connect(_on_sfx_toggled)

func _connect_buttons() -> void:
	if glow_button and not glow_button.pressed.is_connected(_on_glow_pressed):
		glow_button.pressed.connect(_on_glow_pressed)
	if sfx_button and not sfx_button.pressed.is_connected(_on_sfx_pressed):
		sfx_button.pressed.connect(_on_sfx_pressed)
	if resume_button and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if level_select_button and not level_select_button.pressed.is_connected(_on_level_select_pressed):
		level_select_button.pressed.connect(_on_level_select_pressed)

func show_menu() -> void:
	_update_toggle_buttons()
	visible = true

func hide_menu() -> void:
	visible = false

func _update_toggle_buttons() -> void:
	var glow_on: bool = true
	var sfx_on: bool = true
	if is_inside_tree():
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state != null:
			if "glow_enabled" in game_state:
				glow_on = bool(game_state.glow_enabled)
			if "sfx_enabled" in game_state:
				sfx_on = bool(game_state.sfx_enabled)

	if glow_button != null:
		glow_button.text = "Glow: ON" if glow_on else "Glow: OFF"
	if sfx_button != null:
		sfx_button.text = "SFX: ON" if sfx_on else "SFX: OFF"

func _on_glow_toggled(_enabled: bool) -> void:
	_update_toggle_buttons()

func _on_sfx_toggled(_enabled: bool) -> void:
	_update_toggle_buttons()

func _on_glow_pressed() -> void:
	if is_inside_tree():
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state and game_state.has_method("set_glow_enabled"):
			var cur: bool = bool(game_state.glow_enabled)
			game_state.set_glow_enabled(not cur)
	_update_toggle_buttons()

func _on_sfx_pressed() -> void:
	if is_inside_tree():
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state and game_state.has_method("set_sfx_enabled"):
			var cur: bool = bool(game_state.sfx_enabled)
			game_state.set_sfx_enabled(not cur)
	_update_toggle_buttons()

func _on_resume_pressed() -> void:
	hide_menu()
	resume_requested.emit()

func _on_restart_pressed() -> void:
	hide_menu()
	restart_requested.emit()

func _on_level_select_pressed() -> void:
	hide_menu()
	level_select_requested.emit()
