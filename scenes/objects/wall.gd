class_name Wall
extends StaticBody2D

const BeamTypes = preload("res://core/beam_types.gd")

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.WALL

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

