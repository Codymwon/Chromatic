class_name Mirror
extends StaticBody2D

signal transformed

const BeamTypes = preload("res://core/beam_types.gd")

@export var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.MIRROR
@export var is_draggable: bool = true
@export var is_rotatable: bool = true

var initial_position: Vector2 = Vector2.ZERO
var initial_rotation: float = 0.0

@onready var rotation_ring: Node2D = get_node_or_null("RotationRing")

func _init() -> void:
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		transformed.emit()

var _initial_transform_stored: bool = false
var _is_hovered: bool = false
var _is_active: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	store_initial_transform()
	_setup_touch_target()

func _setup_touch_target() -> void:
	var touch_target: Area2D = get_node_or_null("TouchTarget") as Area2D
	if touch_target != null:
		if not touch_target.mouse_entered.is_connected(_on_touch_target_mouse_entered):
			touch_target.mouse_entered.connect(_on_touch_target_mouse_entered)
		if not touch_target.mouse_exited.is_connected(_on_touch_target_mouse_exited):
			touch_target.mouse_exited.connect(_on_touch_target_mouse_exited)

func _on_touch_target_mouse_entered() -> void:
	_is_hovered = true
	_update_rotation_ring()

func _on_touch_target_mouse_exited() -> void:
	_is_hovered = false
	_update_rotation_ring()

func store_initial_transform() -> void:
	if _initial_transform_stored:
		return
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
	_is_active = p_visible
	_update_rotation_ring()

func _update_rotation_ring() -> void:
	if rotation_ring == null:
		rotation_ring = get_node_or_null("RotationRing")
	if rotation_ring != null:
		rotation_ring.visible = is_rotatable and (_is_hovered or _is_active)

func get_facing_normal() -> Vector2:
	return Vector2.UP.rotated(rotation)
