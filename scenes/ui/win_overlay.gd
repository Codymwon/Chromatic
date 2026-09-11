class_name WinOverlay
extends CanvasLayer

signal next_level_pressed
signal replay_pressed
signal level_select_pressed

@onready var title_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel") as Label
@onready var banner_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BannerLabel") as Label
@onready var next_button: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/NextButton") as Button
@onready var replay_button: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/ReplayButton") as Button
@onready var level_select_button: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/LevelSelectButton") as Button

func _ready() -> void:
	visible = false
	if next_button != null and not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)
	if replay_button != null and not replay_button.pressed.is_connected(_on_replay_button_pressed):
		replay_button.pressed.connect(_on_replay_button_pressed)
	if level_select_button != null and not level_select_button.pressed.is_connected(_on_level_select_button_pressed):
		level_select_button.pressed.connect(_on_level_select_button_pressed)

func show_victory(title: String, is_last_level: bool = false) -> void:
	if title_label == null:
		title_label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel") as Label
	if banner_label == null:
		banner_label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BannerLabel") as Label
	if next_button == null:
		next_button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/NextButton") as Button

	if title_label != null:
		title_label.text = title
	if banner_label != null:
		banner_label.text = "CAMPAIGN COMPLETE!" if is_last_level else "LEVEL COMPLETE!"
	if next_button != null:
		next_button.visible = not is_last_level

	visible = true

func hide_victory() -> void:
	visible = false

func _on_next_button_pressed() -> void:
	hide_victory()
	next_level_pressed.emit()

func _on_replay_button_pressed() -> void:
	hide_victory()
	replay_pressed.emit()

func _on_level_select_button_pressed() -> void:
	hide_victory()
	level_select_pressed.emit()
