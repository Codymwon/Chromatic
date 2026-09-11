class_name LevelBase
extends Node2D

signal level_completed

const BeamTypes = preload("res://core/beam_types.gd")
const GameConstants = preload("res://core/constants.gd")
const BeamTracer = preload("res://core/beam_tracer.gd")
const BeamRenderer = preload("res://scenes/fx/beam_renderer.gd")
const LightSource = preload("res://scenes/objects/light_source.gd")
const Mirror = preload("res://scenes/objects/mirror.gd")
const Prism = preload("res://scenes/objects/prism.gd")
const GoalSink = preload("res://scenes/objects/goal_sink.gd")
const Wall = preload("res://scenes/objects/wall.gd")

@onready var beam_renderer: BeamRenderer = get_node_or_null("BeamRenderer") as BeamRenderer
@onready var objects_container: Node2D = get_node_or_null("Objects") as Node2D

var is_dirty: bool = true
var is_completed: bool = false
var win_hold_elapsed: float = 0.0

func get_objects_container() -> Node2D:
	if objects_container == null:
		objects_container = get_node_or_null("Objects") as Node2D
	return objects_container

func get_beam_renderer() -> BeamRenderer:
	if beam_renderer == null:
		beam_renderer = get_node_or_null("BeamRenderer") as BeamRenderer
	return beam_renderer

func _ready() -> void:
	_connect_object_signals()
	mark_dirty()

func _connect_object_signals() -> void:
	var container: Node = get_objects_container()
	if container == null:
		container = self
	for child in container.get_children():
		if child is Mirror or child is Prism:
			if child.has_signal("transformed") and not child.transformed.is_connected(mark_dirty):
				child.transformed.connect(mark_dirty)

func mark_dirty() -> void:
	is_dirty = true

func _process(delta: float) -> void:
	if is_dirty:
		update_beams()
		is_dirty = false

	_evaluate_win_condition(delta)

func _evaluate_win_condition(delta: float) -> void:
	if is_completed:
		return

	var sinks: Array[GoalSink] = get_goal_sinks()
	if sinks.is_empty():
		return

	var all_lit: bool = true
	for sink in sinks:
		if not sink.is_currently_lit():
			all_lit = false
			break

	if all_lit:
		win_hold_elapsed += delta
		if win_hold_elapsed >= GameConstants.WIN_HOLD_TIME:
			is_completed = true
			level_completed.emit()
	else:
		win_hold_elapsed = 0.0

func _get_objects_children() -> Array[Node]:
	var container: Node = get_objects_container()
	if container == null:
		container = self
	return container.get_children()

func get_goal_sinks() -> Array[GoalSink]:
	var sinks: Array[GoalSink] = []
	for child in _get_objects_children():
		if child is GoalSink:
			sinks.append(child)
	return sinks

func get_light_sources() -> Array[LightSource]:
	var sources: Array[LightSource] = []
	for child in _get_objects_children():
		if child is LightSource:
			sources.append(child)
	return sources

func update_beams(
	space_state: PhysicsDirectSpaceState2D = null,
	exclude_rids: Array[RID] = []
) -> Array[BeamTypes.Segment]:
	if beam_renderer == null:
		beam_renderer = get_node_or_null("BeamRenderer") as BeamRenderer

	if space_state == null and is_inside_tree():
		var world_2d: World2D = get_world_2d()
		if world_2d != null:
			space_state = world_2d.direct_space_state

	if space_state == null or beam_renderer == null:
		return []

	var all_segments: Array[BeamTypes.Segment] = []
	var sources: Array[LightSource] = get_light_sources()

	var cast_fn := func(origin: Vector2, direction: Vector2, exclude: Array[RID]) -> BeamTypes.RayHit:
		# Layer 1 = walls (1)
		# Layer 2 = mirrors (2)
		# Layer 3 = prisms (4)
		# Layer 4 = sensors/sinks (8)
		# Collision mask = 1 | 2 | 4 | 8 = 15
		var params := PhysicsRayQueryParameters2D.create(
			origin,
			origin + direction * GameConstants.MAX_RAY_DISTANCE,
			15,
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
		elif collider_obj is Prism:
			collider_type = BeamTypes.ColliderType.PRISM
			normal = Vector2.from_angle(collider_obj.rotation)
		elif collider_obj is GoalSink:
			collider_type = BeamTypes.ColliderType.SINK
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

	for src in sources:
		var origin: Vector2 = src.get_emission_origin()
		var direction: Vector2 = src.get_emission_direction()
		var color: BeamTypes.RayColor = src.beam_color
		var initial_excludes: Array[RID] = exclude_rids.duplicate()

		var segments: Array[BeamTypes.Segment] = BeamTracer.trace(
			cast_fn,
			origin,
			direction,
			color,
			GameConstants.MAX_BOUNCES,
			initial_excludes
		)
		all_segments.append_array(segments)

	beam_renderer.render_segments(all_segments)
	var sinks: Array[GoalSink] = get_goal_sinks()
	_update_sink_illuminations(sinks, all_segments)
	return all_segments

func _update_sink_illuminations(
	sinks: Array[GoalSink],
	segments: Array[BeamTypes.Segment]
) -> void:
	for sink in sinks:
		var matching_hit: bool = false
		var has_hit: bool = false
		for seg in segments:
			if sink.global_position.distance_to(seg.b) <= 26.0:
				has_hit = true
				if seg.color == sink.required_color:
					matching_hit = true
					break

		if matching_hit:
			sink.set_lit(true)
		elif has_hit:
			sink.set_lit(false)
			sink.flash_mismatch()
		else:
			sink.set_lit(false)
