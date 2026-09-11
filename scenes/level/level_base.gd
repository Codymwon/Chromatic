class_name LevelBase
extends Node2D

signal level_completed
signal level_select_requested

const BeamTypes = preload("res://core/beam_types.gd")
const GameConstants = preload("res://core/constants.gd")
const BeamTracer = preload("res://core/beam_tracer.gd")
const BeamRenderer = preload("res://scenes/fx/beam_renderer.gd")
const LightSource = preload("res://scenes/objects/light_source.gd")
const Mirror = preload("res://scenes/objects/mirror.gd")
const Prism = preload("res://scenes/objects/prism.gd")
const GoalSink = preload("res://scenes/objects/goal_sink.gd")
const Wall = preload("res://scenes/objects/wall.gd")
const HUD = preload("res://scenes/ui/hud.gd")
const WinOverlay = preload("res://scenes/ui/win_overlay.gd")
const LevelManagerNode = preload("res://autoload/level_manager.gd")

const LIGHT_SOURCE_SCENE: PackedScene = preload("res://scenes/objects/light_source.tscn")
const MIRROR_SCENE: PackedScene = preload("res://scenes/objects/mirror.tscn")
const PRISM_SCENE: PackedScene = preload("res://scenes/objects/prism.tscn")
const GOAL_SINK_SCENE: PackedScene = preload("res://scenes/objects/goal_sink.tscn")
const WALL_SCENE: PackedScene = preload("res://scenes/objects/wall.tscn")

enum DragMode { NONE, MOVE, ROTATE }

const PLAYFIELD_MIN: Vector2 = Vector2(64.0, 64.0)
const PLAYFIELD_MAX: Vector2 = Vector2(1856.0, 1016.0)
const INNER_MOVE_ZONE_RADIUS: float = 32.0
const MAX_GRAB_RADIUS: float = 48.0

@onready var beam_renderer: BeamRenderer = get_node_or_null("BeamRenderer") as BeamRenderer
@onready var objects_container: Node2D = get_node_or_null("Objects") as Node2D
@onready var hud: HUD = get_node_or_null("HUD") as HUD
@onready var win_overlay: WinOverlay = get_node_or_null("WinOverlay") as WinOverlay

var is_dirty: bool = true
var is_completed: bool = false
var win_hold_elapsed: float = 0.0

var drag_mode: DragMode = DragMode.NONE
var active_drag_object: Node2D = null
var active_touch_index: int = -1
var drag_offset: Vector2 = Vector2.ZERO
var initial_rotation_offset: float = 0.0
var snap_enabled: bool = true
var current_level_dict: Dictionary = {}

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
	_connect_win_overlay_signals()
	mark_dirty()

func _connect_win_overlay_signals() -> void:
	if win_overlay == null:
		win_overlay = get_node_or_null("WinOverlay")
	if win_overlay != null:
		if win_overlay.has_signal("next_level_pressed") and not win_overlay.next_level_pressed.is_connected(_on_win_overlay_next_level):
			win_overlay.next_level_pressed.connect(_on_win_overlay_next_level)
		if win_overlay.has_signal("replay_pressed") and not win_overlay.replay_pressed.is_connected(_on_win_overlay_replay):
			win_overlay.replay_pressed.connect(_on_win_overlay_replay)
		if win_overlay.has_signal("level_select_pressed") and not win_overlay.level_select_pressed.is_connected(_on_win_overlay_level_select):
			win_overlay.level_select_pressed.connect(_on_win_overlay_level_select)

func _get_level_manager() -> LevelManagerNode:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("LevelManager") as LevelManagerNode
	return null

func _on_win_overlay_next_level() -> void:
	var lm: LevelManagerNode = _get_level_manager()
	if lm != null and lm.has_next_level():
		lm.complete_current_level()
		lm.load_next_level()
		load_level(lm.get_current_level_data())

func _on_win_overlay_replay() -> void:
	if not current_level_dict.is_empty():
		load_level(current_level_dict)
	else:
		reset_level()

func _on_win_overlay_level_select() -> void:
	level_select_requested.emit()
	if is_inside_tree() and get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

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

static func is_valid_piece_type(p_type: String) -> bool:
	match p_type.to_lower():
		"mirror", "prism", "sink", "wall":
			return true
		_:
			return false

static func _parse_color_string(color_str: String) -> BeamTypes.RayColor:
	match color_str.to_lower():
		"red": return BeamTypes.RayColor.RED
		"green": return BeamTypes.RayColor.GREEN
		"blue": return BeamTypes.RayColor.BLUE
		"white": return BeamTypes.RayColor.WHITE
		_: return BeamTypes.RayColor.WHITE

func load_level(level_dict: Dictionary) -> void:
	current_level_dict = level_dict
	_release_drag()
	is_completed = false
	win_hold_elapsed = 0.0

	var container: Node2D = get_objects_container()
	if container != null:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()

	for child in get_children():
		if child is LightSource:
			remove_child(child)
			child.queue_free()

	# Spawn LightSource
	var source_data: Dictionary = level_dict.get("source", {})
	if not source_data.is_empty():
		var light_source: LightSource = LIGHT_SOURCE_SCENE.instantiate() as LightSource
		light_source.position = Vector2(source_data.get("x", 200.0), source_data.get("y", 540.0))
		light_source.rotation = deg_to_rad(source_data.get("rot_deg", 0.0))
		if container != null:
			container.add_child(light_source)
		else:
			add_child(light_source)

	# Spawn Objects
	var objects_data: Array = level_dict.get("objects", [])
	for obj_entry in objects_data:
		var obj_dict: Dictionary = obj_entry as Dictionary
		var obj_type: String = str(obj_dict.get("type", "")).to_lower()
		assert(is_valid_piece_type(obj_type), "Unknown optical piece type in levels.json: " + str(obj_type))
		var node: Node2D = null

		match obj_type:
			"mirror":
				var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
				mirror.position = Vector2(obj_dict.get("x", 0.0), obj_dict.get("y", 0.0))
				mirror.rotation = deg_to_rad(obj_dict.get("rot_deg", 0.0))
				mirror.is_draggable = obj_dict.get("draggable", true)
				mirror.is_rotatable = obj_dict.get("rotatable", true)
				node = mirror
			"prism":
				var prism: Prism = PRISM_SCENE.instantiate() as Prism
				prism.position = Vector2(obj_dict.get("x", 0.0), obj_dict.get("y", 0.0))
				prism.rotation = deg_to_rad(obj_dict.get("rot_deg", 0.0))
				prism.is_draggable = obj_dict.get("draggable", true)
				prism.is_rotatable = obj_dict.get("rotatable", true)
				node = prism
			"sink":
				var sink: GoalSink = GOAL_SINK_SCENE.instantiate() as GoalSink
				sink.position = Vector2(obj_dict.get("x", 0.0), obj_dict.get("y", 0.0))
				sink.rotation = deg_to_rad(obj_dict.get("rot_deg", 0.0))
				sink.required_color = _parse_color_string(str(obj_dict.get("color", "red")))
				node = sink
			"wall":
				var wall: Wall = WALL_SCENE.instantiate() as Wall
				wall.position = Vector2(obj_dict.get("x", 0.0), obj_dict.get("y", 0.0))
				wall.rotation = deg_to_rad(obj_dict.get("rot_deg", 0.0))
				var w: float = float(obj_dict.get("width", 40.0))
				var h: float = float(obj_dict.get("height", 300.0))
				wall.set_wall_size(w, h)
				node = wall

		if node != null:
			if container != null:
				container.add_child(node)
			else:
				add_child(node)

	_connect_object_signals()

	var title: String = level_dict.get("title", "")
	if hud != null and hud.has_method("set_title"):
		hud.set_title(title)

	mark_dirty()
	update_beams()

func reset_level() -> void:
	_release_drag()
	win_hold_elapsed = 0.0
	is_completed = false

	for child in _get_objects_children():
		if child.has_method("reset_transform"):
			child.reset_transform()

	mark_dirty()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var st := InputEventScreenTouch.new()
			st.position = mb.position
			st.pressed = mb.pressed
			st.index = 0
			_handle_screen_touch(st)
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var sd := InputEventScreenDrag.new()
			sd.position = mm.position
			sd.relative = mm.relative
			sd.index = 0
			_handle_screen_drag(sd)

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
			var hits: Array[Dictionary] = space.intersect_point(params, 32)
			var candidates: Array[Node2D] = []
			for hit in hits:
				var collider: Object = hit.get("collider")
				if collider is Node:
					var node: Node = collider as Node
					var piece: Node2D = null
					if node.has_method("reset_transform") and node is Node2D:
						piece = node as Node2D
					elif node.get_parent() != null and node.get_parent().has_method("reset_transform") and node.get_parent() is Node2D:
						piece = node.get_parent() as Node2D
					if piece != null and not candidates.has(piece):
						candidates.append(piece)

			if candidates.size() > 0:
				# Sort by visual layering: highest z_index first, then highest child index in tree
				candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
					if a.z_index != b.z_index:
						return a.z_index > b.z_index
					return a.get_index() > b.get_index()
				)
				return candidates[0]
			return null

	# Fallback for headless tests running without an active 2D physics world
	var candidate_pieces: Array[Node2D] = []
	for child in _get_objects_children():
		if child.has_method("reset_transform") and child is Node2D:
			var piece: Node2D = child as Node2D
			var dist: float = piece.global_position.distance_to(pos)
			if dist <= MAX_GRAB_RADIUS:
				candidate_pieces.append(piece)

	if candidate_pieces.size() > 0:
		candidate_pieces.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			var dist_a: float = a.global_position.distance_to(pos)
			var dist_b: float = b.global_position.distance_to(pos)
			if absf(dist_a - dist_b) < 1.0:
				if a.z_index != b.z_index:
					return a.z_index > b.z_index
				return a.get_index() > b.get_index()
			return dist_a < dist_b
		)
		return candidate_pieces[0]

	return null

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if drag_mode != DragMode.NONE:
			return

		var piece: Node2D = get_draggable_object_at(event.position)
		if piece == null:
			return

		var dist: float = piece.global_position.distance_to(event.position)
		var can_drag: bool = piece.get("is_draggable") if "is_draggable" in piece else true
		var can_rotate: bool = piece.get("is_rotatable") if "is_rotatable" in piece else true

		if dist <= INNER_MOVE_ZONE_RADIUS:
			if not can_drag:
				return
			active_drag_object = piece
			active_touch_index = event.index
			win_hold_elapsed = 0.0
			drag_mode = DragMode.MOVE
			drag_offset = event.position - piece.global_position
		else:
			if not can_rotate:
				return
			active_drag_object = piece
			active_touch_index = event.index
			win_hold_elapsed = 0.0
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
		if child.has_method("store_initial_transform"):
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
			_show_win_modal()
	else:
		win_hold_elapsed = 0.0

func _show_win_modal() -> void:
	if win_overlay == null:
		win_overlay = get_node_or_null("WinOverlay") as WinOverlay
	if win_overlay == null:
		return

	var lm: LevelManagerNode = _get_level_manager()
	var lvl_title: String = current_level_dict.get("title", "Level Complete")
	var is_last: bool = false

	if lm != null:
		var cur_data: Dictionary = lm.get_current_level_data()
		if not cur_data.is_empty():
			lvl_title = cur_data.get("title", lvl_title)
		is_last = not lm.has_next_level()
		if is_last:
			lm.complete_current_level()

	win_overlay.show_victory(lvl_title, is_last)

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
