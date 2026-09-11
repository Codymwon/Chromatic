class_name Mirror
extends StaticBody2D

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.MIRROR
@export var size: Vector2 = Vector2(120.0, 16.0):
	set(value):
		size = value
		_update_size()

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var visual_body: ColorRect = get_node_or_null("VisualBody") as ColorRect
@onready var visual_normal: Line2D = get_node_or_null("NormalIndicator") as Line2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_update_size()

func get_facing_normal() -> Vector2:
	return Vector2.UP.rotated(global_rotation).normalized()

func _update_size() -> void:
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = size
	if visual_body != null:
		visual_body.offset_left = -size.x / 2.0
		visual_body.offset_top = -size.y / 2.0
		visual_body.offset_right = size.x / 2.0
		visual_body.offset_bottom = size.y / 2.0
