class_name M2TestLevel
extends Node2D

const BeamTypes = preload("res://core/beam_types.gd")
const GameConstants = preload("res://core/constants.gd")
const BeamTracer = preload("res://core/beam_tracer.gd")
const BeamRenderer = preload("res://scenes/fx/beam_renderer.gd")
const LightSource = preload("res://scenes/objects/light_source.gd")
const Mirror = preload("res://scenes/objects/mirror.gd")
const Wall = preload("res://scenes/objects/wall.gd")

@onready var light_source: LightSource = get_node_or_null("LightSource") as LightSource
@onready var beam_renderer: BeamRenderer = get_node_or_null("BeamRenderer") as BeamRenderer

var is_dirty: bool = true

func _ready() -> void:
	for child in get_children():
		if child is Mirror:
			child.transformed.connect(mark_dirty)
	mark_dirty()

func mark_dirty() -> void:
	is_dirty = true

func _process(_delta: float) -> void:
	if is_dirty:
		update_beam()
		is_dirty = false

func update_beam(
	space_state: PhysicsDirectSpaceState2D = null,
	exclude_rids: Array[RID] = []
) -> Array[BeamTypes.Segment]:
	if light_source == null:
		light_source = get_node_or_null("LightSource") as LightSource
	if beam_renderer == null:
		beam_renderer = get_node_or_null("BeamRenderer") as BeamRenderer

	if light_source == null or beam_renderer == null:
		return []

	if space_state == null and is_inside_tree():
		var world_2d: World2D = get_world_2d()
		if world_2d != null:
			space_state = world_2d.direct_space_state

	if space_state == null:
		return []

	var initial_excludes: Array[RID] = exclude_rids.duplicate()

	var cast_fn := func(origin: Vector2, direction: Vector2, exclude: Array[RID]) -> BeamTypes.RayHit:
		# Layer 1 = walls (bit 1 = 1)
		# Layer 2 = mirrors (bit 2 = 2)
		# Collision mask = 1 | 2 = 3
		var params := PhysicsRayQueryParameters2D.create(
			origin,
			origin + direction * GameConstants.MAX_RAY_DISTANCE,
			3,
			exclude
		)
		params.collide_with_areas = true
		params.collide_with_bodies = true

		var result: Dictionary = space_state.intersect_ray(params)
		if result.is_empty():
			return null

		var collider_obj: Object = result.get("collider")
		var collider_type: BeamTypes.ColliderType = BeamTypes.ColliderType.WALL
		var normal: Vector2 = result.get("normal", Vector2.ZERO)

		if collider_obj is Mirror:
			collider_type = BeamTypes.ColliderType.MIRROR
			normal = collider_obj.get_facing_normal()
		elif collider_obj != null and "collider_type" in collider_obj:
			collider_type = collider_obj.collider_type
			if collider_type == BeamTypes.ColliderType.MIRROR and collider_obj.has_method("get_facing_normal"):
				normal = collider_obj.get_facing_normal()

		var hit := BeamTypes.RayHit.new(
			result["position"],
			normal,
			collider_type,
			collider_obj,
			result["rid"]
		)
		return hit

	var origin: Vector2 = light_source.get_emission_origin()
	var direction: Vector2 = light_source.get_emission_direction()
	var color: BeamTypes.RayColor = light_source.beam_color

	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(
		cast_fn,
		origin,
		direction,
		color,
		GameConstants.MAX_BOUNCES,
		initial_excludes
	)
	beam_renderer.render_segments(segments)
	return segments
