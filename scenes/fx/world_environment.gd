class_name GameWorldEnvironment
extends WorldEnvironment

func _ready() -> void:
	_sync_glow_with_game_state()
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and game_state.has_signal("glow_toggled"):
		if not game_state.glow_toggled.is_connected(_on_glow_toggled):
			game_state.glow_toggled.connect(_on_glow_toggled)

func _sync_glow_with_game_state() -> void:
	if environment == null:
		return
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state and "glow_enabled" in game_state:
		environment.glow_enabled = bool(game_state.glow_enabled)

func _on_glow_toggled(p_enabled: bool) -> void:
	if environment != null:
		environment.glow_enabled = p_enabled
