class_name GoalSink
extends Area2D

signal lit_state_changed(is_lit: bool)

const BeamTypes = preload("res://core/beam_types.gd")
const BeamRenderer = preload("res://scenes/fx/beam_renderer.gd")

@export var required_color: BeamTypes.RayColor = BeamTypes.RayColor.RED:
	set(value):
		required_color = value
		_update_visuals()

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.SINK

var is_lit: bool = false
var _mismatch_flash_timer: float = 0.0
var _pulse_timer: float = 0.0

@onready var receptacle_ring: Node2D = get_node_or_null("ReceptacleRing")
@onready var inner_core: Node2D = get_node_or_null("InnerCore")
@onready var sparkle_particles: CPUParticles2D = get_node_or_null("SparkleParticles")

func _ready() -> void:
	collision_layer = 8 # Layer 4: sensors
	collision_mask = 0
	_update_visuals()

func set_lit(p_lit: bool) -> void:
	if is_lit != p_lit:
		is_lit = p_lit
		_update_visuals()
		if is_lit:
			_on_lit_activated()
		lit_state_changed.emit(is_lit)

func is_currently_lit() -> bool:
	return is_lit

func is_flashing_mismatch() -> bool:
	return _mismatch_flash_timer > 0.0

func trigger_mismatch_feedback() -> void:
	flash_mismatch()

func flash_mismatch() -> void:
	_mismatch_flash_timer = 0.2
	if inner_core is CanvasItem:
		(inner_core as CanvasItem).modulate = Color(1.0, 0.0, 0.0, 1.0)
		(inner_core as CanvasItem).visible = true
	var sm: Node = _get_sound_manager()
	if sm and sm.has_method("play_mismatch"):
		sm.play_mismatch()

func notify_beam_hit(color: BeamTypes.RayColor) -> void:
	if color == required_color:
		_mismatch_flash_timer = 0.0
		set_lit(true)
	elif not is_lit:
		trigger_mismatch_feedback()

func _on_lit_activated() -> void:
	var sm: Node = _get_sound_manager()
	if sm and sm.has_method("play_sink_lit"):
		sm.play_sink_lit(required_color)

	var game_state: Node = _get_game_state()
	if game_state and game_state.has_method("trigger_haptic_micro_tap"):
		game_state.trigger_haptic_micro_tap()
	elif OS.has_feature("mobile") and Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(20)

func _get_sound_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/SoundManager")

func _get_game_state() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/GameState")

func _process(delta: float) -> void:
	if _mismatch_flash_timer > 0.0:
		_mismatch_flash_timer -= delta
		if _mismatch_flash_timer <= 0.0:
			_update_visuals()
	elif is_lit and inner_core != null:
		_pulse_timer += delta
		var pulse_scale: float = 1.0 + sin(_pulse_timer * 8.0) * 0.05
		inner_core.scale = Vector2(pulse_scale, pulse_scale)

func _update_visuals() -> void:
	var color: Color = BeamRenderer.get_palette_color(required_color)
	if receptacle_ring is CanvasItem:
		(receptacle_ring as CanvasItem).modulate = color
	if inner_core != null:
		if is_lit:
			(inner_core as CanvasItem).modulate = Color(1.0, 1.0, 1.0, 1.0)
			(inner_core as CanvasItem).visible = true
		else:
			(inner_core as CanvasItem).modulate = Color(color.r, color.g, color.b, 0.2)
			(inner_core as CanvasItem).visible = false
			inner_core.scale = Vector2.ONE
			_pulse_timer = 0.0

	if sparkle_particles != null:
		sparkle_particles.color = Color(color.r, color.g, color.b, 0.9)
		sparkle_particles.emitting = is_lit
