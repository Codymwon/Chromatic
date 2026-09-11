class_name HUD
extends CanvasLayer

signal snap_toggled(enabled: bool)
signal reset_requested

@export var level_title: String = "Chromatic":
	set(value):
		level_title = value
		_update_title_label()

var snap_enabled: bool = true

@onready var title_label: Label = get_node_or_null("TopBar/HBoxContainer/TitleLabel") as Label
@onready var snap_button: Button = get_node_or_null("TopBar/HBoxContainer/SnapButton") as Button
@onready var reset_button: Button = get_node_or_null("TopBar/HBoxContainer/ResetButton") as Button

func _ready() -> void:
	_update_title_label()
	_update_snap_button()
	if snap_button != null and not snap_button.pressed.is_connected(_on_snap_button_pressed):
		snap_button.pressed.connect(_on_snap_button_pressed)
	if reset_button != null and not reset_button.pressed.is_connected(_on_reset_button_pressed):
		reset_button.pressed.connect(_on_reset_button_pressed)

func _update_title_label() -> void:
	if title_label != null:
		title_label.text = level_title

func _update_snap_button() -> void:
	if snap_button != null:
		snap_button.text = "Snap: ON" if snap_enabled else "Snap: OFF"

func set_snap_enabled(enabled: bool) -> void:
	if snap_enabled != enabled:
		snap_enabled = enabled
		_update_snap_button()

func _on_snap_button_pressed() -> void:
	snap_enabled = not snap_enabled
	_update_snap_button()
	snap_toggled.emit(snap_enabled)

func _on_reset_button_pressed() -> void:
	reset_requested.emit()
