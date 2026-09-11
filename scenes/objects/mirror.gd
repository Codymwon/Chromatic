class_name Mirror
extends StaticBody2D

signal transformed

const BeamTypes = preload("res://core/beam_types.gd")

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.MIRROR

func _init() -> void:
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		transformed.emit()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0

func get_facing_normal() -> Vector2:
	return Vector2.UP.rotated(rotation)
