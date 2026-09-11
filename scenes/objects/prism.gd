class_name Prism
extends Area2D

signal transformed

const BeamTypes = preload("res://core/beam_types.gd")

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.PRISM

var initial_position: Vector2 = Vector2.ZERO
var initial_rotation: float = 0.0

@onready var rotation_ring: Node2D = get_node_or_null("RotationRing")

func _init() -> void:
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		transformed.emit()

var _initial_transform_stored: bool = false

func _ready() -> void:
	collision_layer = 4 # Layer 3: prisms
	collision_mask = 0
	store_initial_transform()

func store_initial_transform() -> void:
	initial_position = position if not is_inside_tree() else global_position
	initial_rotation = rotation if not is_inside_tree() else global_rotation
	_initial_transform_stored = true

func reset_transform() -> void:
	if not _initial_transform_stored:
		store_initial_transform()
	if is_inside_tree():
		global_position = initial_position
		global_rotation = initial_rotation
	else:
		position = initial_position
		rotation = initial_rotation
	transformed.emit()

func set_rotation_ring_visible(p_visible: bool) -> void:
	if rotation_ring == null:
		rotation_ring = get_node_or_null("RotationRing")
	if rotation_ring != null:
		rotation_ring.visible = p_visible
