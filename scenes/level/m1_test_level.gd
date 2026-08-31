class_name M1TestLevel
extends Node2D

@onready var light_source: LightSource = $LightSource as LightSource
@onready var beam_renderer: BeamRenderer = $BeamRenderer as BeamRenderer

var is_dirty: bool = true

func _ready() -> void:
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
		if get_world_2d() != null:
			space_state = get_world_2d().direct_space_state
		elif get_tree() != null and get_tree().root != null and get_tree().root.world_2d != null:
			space_state = get_tree().root.world_2d.direct_space_state

	if space_state == null:
		return []

	var initial_excludes: Array[RID] = exclude_rids.duplicate()

	var cast_fn := func(origin: Vector2, direction: Vector2, exclude: Array[RID]) -> BeamTypes.RayHit:
		var params := PhysicsRayQueryParameters2D.create(
			origin,
			origin + direction * GameConstants.MAX_RAY_DISTANCE,
			1, # Collision Layer 1: walls
			exclude
		)
		params.collide_with_areas = true
		params.collide_with_bodies = true

		var result: Dictionary = space_state.intersect_ray(params)
		if result.is_empty():
			return null

		var hit := BeamTypes.RayHit.new(
			result["position"],
			result["normal"],
			BeamTypes.ColliderType.WALL,
			result["collider"],
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
