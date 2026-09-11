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
const HUD_SCRIPT = preload("res://scenes/ui/hud.gd")

enum DragMode { NONE, MOVE, ROTATE }

const PLAYFIELD_MIN: Vector2 = Vector2(64.0, 64.0)
const PLAYFIELD_MAX: Vector2 = Vector2(1856.0, 1016.0)
const INNER_MOVE_ZONE_RADIUS: float = 32.0
const MAX_GRAB_RADIUS: float = 48.0

@onready var beam_renderer: BeamRenderer = get_node_or_null("BeamRenderer") as BeamRenderer
@onready var objects_container: Node2D = get_node_or_null("Objects") as Node2D
@onready var hud: Node = get_node_or_null("HUD")

var is_dirty: bool = true
var is_completed: bool = false
var win_hold_elapsed: float = 0.0

var drag_mode: DragMode = DragMode.NONE
var active_drag_object: Node2D = null
var active_touch_index: int = -1
var drag_offset: Vector2 = Vector2.ZERO
var initial_rotation_offset: float = 0.0
var snap_enabled: bool = true

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
	_connect_hud_signals()
	mark_dirty()

func _connect_hud_signals() -> void:
	if hud == null:
		hud = get_node_or_null("HUD")
	if hud != null:
		if hud.has_signal("snap_toggled") and not hud.snap_toggled.is_connected(_on_hud_snap_toggled):
			hud.snap_toggled.connect(_on_hud_snap_toggled)
		if hud.has_signal("reset_requested") and not hud.reset_requested.is_connected(reset_level):
			hud.reset_requested.connect(reset_level)
		if hud.has_method("set_snap_enabled"):
			hud.set_snap_enabled(snap_enabled)

func _on_hud_snap_toggled(enabled: bool) -> void:
	snap_enabled = enabled

func reset_level() -> void:
	_release_drag()
	win_hold_elapsed = 0.0
	is_completed = false

	for child in _get_objects_children():
		if child is Mirror or child is Prism:
			if child.has_method("reset_transform"):
				child.reset_transform()

	mark_dirty()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)

func get_draggable_object_at(pos: Vector2) -> Node2D:
	if is_inside_tree():
		var world_2d: World2D = get_world_2d()
		if world_2d != null and world_2d.direct_space_state != null:
			var space: PhysicsDirectSpaceState2D = world_2d.direct_space_state
			var params := PhysicsPointQueryParameters2D.new()
			params.position = pos
			params.collision_mask = 16 # Layer 5: touch_targets
			params.collide_with_areas = true
			params.collide_with_bodies = true
			var hits: Array[Dictionary] = space.intersect_point(params)
			for hit in hits:
				var collider: Object = hit.get("collider")
				if collider is Node:
					var node: Node = collider as Node
					if node.name == "TouchTarget" and node.get_parent() is Node2D:
						var parent: Node2D = node.get_parent() as Node2D
						if parent is Mirror or parent is Prism:
							return parent
					elif node is Mirror or node is Prism:
						return node as Node2D

	var closest_piece: Node2D = null
	var closest_dist: float = INF
	for child in _get_objects_children():
		if child is Mirror or child is Prism:
			var piece: Node2D = child as Node2D
			var dist: float = piece.global_position.distance_to(pos)
			if dist <= MAX_GRAB_RADIUS and dist < closest_dist:
				closest_dist = dist
				closest_piece = piece

	return closest_piece

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if drag_mode != DragMode.NONE:
			return

		var piece: Node2D = get_draggable_object_at(event.position)
		if piece == null:
			return

		active_drag_object = piece
		active_touch_index = event.index
		win_hold_elapsed = 0.0

		var dist: float = piece.global_position.distance_to(event.position)
		if dist <= INNER_MOVE_ZONE_RADIUS:
			drag_mode = DragMode.MOVE
			drag_offset = event.position - piece.global_position
		else:
			drag_mode = DragMode.ROTATE
			var touch_angle: float = (event.position - piece.global_position).angle()
			initial_rotation_offset = piece.global_rotation - touch_angle
			if piece.has_method("set_rotation_ring_visible"):
				piece.set_rotation_ring_visible(true)
	else:
		if event.index == active_touch_index:
			_release_drag()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != active_touch_index or active_drag_object == null:
		return

	if drag_mode == DragMode.MOVE:
		var target_pos: Vector2 = event.position - drag_offset
		target_pos.x = clampf(target_pos.x, PLAYFIELD_MIN.x, PLAYFIELD_MAX.x)
		target_pos.y = clampf(target_pos.y, PLAYFIELD_MIN.y, PLAYFIELD_MAX.y)
		active_drag_object.global_position = target_pos
		win_hold_elapsed = 0.0
		mark_dirty()
	elif drag_mode == DragMode.ROTATE:
		var current_angle: float = (event.position - active_drag_object.global_position).angle()
		var raw_angle: float = current_angle + initial_rotation_offset
		if snap_enabled:
			var snap_rad: float = deg_to_rad(GameConstants.ROTATE_SNAP_DEG)
			raw_angle = roundf(raw_angle / snap_rad) * snap_rad
		active_drag_object.global_rotation = raw_angle
		win_hold_elapsed = 0.0
		mark_dirty()

func _release_drag() -> void:
	if active_drag_object != null:
		if active_drag_object.has_method("set_rotation_ring_visible"):
			active_drag_object.set_rotation_ring_visible(false)
	active_drag_object = null
	drag_mode = DragMode.NONE
	active_touch_index = -1

func _connect_object_signals() -> void:
	for child in _get_objects_children():
		if child is Mirror or child is Prism:
			if child.has_method("store_initial_transform") and "_initial_transform_stored" in child and not child._initial_transform_stored:
				child.store_initial_transform()
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
