class_name Wall
extends StaticBody2D

const BeamTypes = preload("res://core/beam_types.gd")

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.WALL
@export var wall_width: float = 40.0:
	set(val):
		wall_width = val
		_update_wall_shape()
@export var wall_height: float = 300.0:
	set(val):
		wall_height = val
		_update_wall_shape()

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_update_wall_shape()

func set_wall_size(p_width: float, p_height: float) -> void:
	wall_width = p_width
	wall_height = p_height
	_update_wall_shape()

func _update_wall_shape() -> void:
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(wall_width, wall_height)
		col.shape = rect
	var vis: ColorRect = get_node_or_null("Visual") as ColorRect
	if vis != null:
		vis.offset_left = -wall_width / 2.0
		vis.offset_top = -wall_height / 2.0
		vis.offset_right = wall_width / 2.0
		vis.offset_bottom = wall_height / 2.0

