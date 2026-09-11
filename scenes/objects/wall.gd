class_name Wall
extends StaticBody2D

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.WALL
@export var size: Vector2 = Vector2(40.0, 300.0):
	set(value):
		size = value
		_update_size()

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var visual: ColorRect = get_node_or_null("Visual") as ColorRect

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_update_size()

func _update_size() -> void:
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = size
	if visual != null:
		visual.offset_left = -size.x / 2.0
		visual.offset_top = -size.y / 2.0
		visual.offset_right = size.x / 2.0
		visual.offset_bottom = size.y / 2.0
