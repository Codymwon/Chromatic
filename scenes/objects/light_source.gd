class_name LightSource
extends Node2D

const DEFAULT_EMISSION_OFFSET: float = 24.0

@export var beam_color: BeamTypes.RayColor = BeamTypes.RayColor.WHITE
@export var emission_offset: float = DEFAULT_EMISSION_OFFSET

func get_emission_direction() -> Vector2:
	return Vector2.RIGHT.rotated(global_rotation).normalized()

func get_emission_origin() -> Vector2:
	return global_position + get_emission_direction() * emission_offset
