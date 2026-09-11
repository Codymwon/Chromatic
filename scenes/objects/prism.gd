class_name Prism
extends Area2D

signal transformed

const BeamTypes = preload("res://core/beam_types.gd")

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.PRISM

func _init() -> void:
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		transformed.emit()

func _ready() -> void:
	collision_layer = 4 # Layer 3: prisms
	collision_mask = 0
