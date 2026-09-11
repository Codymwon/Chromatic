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

@onready var receptacle_ring: Node2D = get_node_or_null("ReceptacleRing")
@onready var inner_core: Node2D = get_node_or_null("InnerCore")

func _ready() -> void:
	collision_layer = 8 # Layer 4: sensors
	collision_mask = 0
	_update_visuals()

func set_lit(p_lit: bool) -> void:
	if is_lit != p_lit:
		is_lit = p_lit
		_update_visuals()
		lit_state_changed.emit(is_lit)

func is_currently_lit() -> bool:
	return is_lit

func flash_mismatch() -> void:
	_mismatch_flash_timer = 0.2
	if inner_core is CanvasItem:
		(inner_core as CanvasItem).modulate = Color(1.0, 0.0, 0.0, 1.0)
		(inner_core as CanvasItem).visible = true

func notify_beam_hit(color: BeamTypes.RayColor) -> void:
	if color == required_color:
		set_lit(true)
	elif not is_lit:
		flash_mismatch()

func _process(delta: float) -> void:
	if _mismatch_flash_timer > 0.0:
		_mismatch_flash_timer -= delta
		if _mismatch_flash_timer <= 0.0:
			_update_visuals()

func _update_visuals() -> void:
	var color: Color = BeamRenderer.get_palette_color(required_color)
	if receptacle_ring is CanvasItem:
		(receptacle_ring as CanvasItem).modulate = color
	if inner_core is CanvasItem:
		if is_lit:
			(inner_core as CanvasItem).modulate = Color(1.0, 1.0, 1.0, 1.0)
			(inner_core as CanvasItem).visible = true
		else:
			(inner_core as CanvasItem).modulate = Color(color.r, color.g, color.b, 0.2)
			(inner_core as CanvasItem).visible = false
