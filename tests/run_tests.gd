extends SceneTree

const GameConstants = preload("res://core/constants.gd")
const BeamTypes = preload("res://core/beam_types.gd")
const BeamTracer = preload("res://core/beam_tracer.gd")
const BeamRenderer = preload("res://scenes/fx/beam_renderer.gd")
const LightSource = preload("res://scenes/objects/light_source.gd")
const Wall = preload("res://scenes/objects/wall.gd")
const WALL_SCENE: PackedScene = preload("res://scenes/objects/wall.tscn")
const Mirror = preload("res://scenes/objects/mirror.gd")
const MIRROR_SCENE: PackedScene = preload("res://scenes/objects/mirror.tscn")
const M1TestLevel = preload("res://scenes/level/m1_test_level.gd")
const M1_LEVEL_SCENE: PackedScene = preload("res://scenes/level/m1_test_level.tscn")
const M2TestLevel = preload("res://scenes/level/m2_test_level.gd")
const M2_LEVEL_SCENE: PackedScene = preload("res://scenes/level/m2_test_level.tscn")

var _passed_count: int = 0
var _failed_count: int = 0
var _current_test_name: String = ""
var _failures: Array[String] = []

func _init() -> void:
	print("==================================================")
	print(" Running Headless Test Suite (res://tests/run_tests.gd)")
	print("==================================================")
	
	_run_all_tests()
	
	print("\n--------------------------------------------------")
	print(" Test Results: %d passed, %d failed" % [_passed_count, _failed_count])
	print("--------------------------------------------------")
	
	if _failed_count > 0:
		print("Failures:")
		for failure in _failures:
			print("  [FAIL] %s" % failure)
		quit(1)
	else:
		print("All tests passed successfully!")
		quit(0)

func _run_all_tests() -> void:
	var test_methods: Array[String] = []
	for method_info in get_method_list():
		var method_name: String = method_info["name"]
		if method_name.begins_with("test_"):
			test_methods.append(method_name)
	
	test_methods.sort()
	
	for method_name in test_methods:
		_current_test_name = method_name
		print("\n[RUN] %s" % method_name)
		call(method_name)

# --- Assertion Utilities ---

func assert_true(condition: bool, message: String = "") -> bool:
	if condition:
		_passed_count += 1
		return true
	else:
		_failed_count += 1
		var fail_msg := "%s: Expected true, got false. %s" % [_current_test_name, message]
		_failures.append(fail_msg)
		printerr("  Assertion Failed: ", fail_msg)
		return false

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	if actual == expected:
		_passed_count += 1
		return true
	else:
		_failed_count += 1
		var fail_msg := "%s: Expected %s, got %s. %s" % [_current_test_name, str(expected), str(actual), message]
		_failures.append(fail_msg)
		printerr("  Assertion Failed: ", fail_msg)
		return false

func assert_vector_approx(actual: Vector2, expected: Vector2, tolerance: float = 0.001, message: String = "") -> bool:
	var diff := (actual - expected).length()
	if diff <= tolerance:
		_passed_count += 1
		return true
	else:
		_failed_count += 1
		var fail_msg := "%s: Expected %s approx %s (diff %f > tol %f). %s" % [
			_current_test_name, str(actual), str(expected), diff, tolerance, message
		]
		_failures.append(fail_msg)
		printerr("  Assertion Failed: ", fail_msg)
		return false

# --- Smoke Tests for M1 Issue 01 ---

func test_game_constants() -> void:
	assert_eq(GameConstants.MAX_BOUNCES, 24, "MAX_BOUNCES must be 24")
	assert_eq(GameConstants.PRISM_HALF_ANGLE_DEG, 12.0, "PRISM_HALF_ANGLE_DEG must be 12.0")
	assert_eq(GameConstants.BEAM_WIDTH, 6.0, "BEAM_WIDTH must be 6.0")
	assert_eq(GameConstants.ROTATE_SNAP_DEG, 15.0, "ROTATE_SNAP_DEG must be 15.0")
	assert_eq(GameConstants.WIN_HOLD_TIME, 0.5, "WIN_HOLD_TIME must be 0.5")
	assert_eq(GameConstants.TOUCH_TARGET_MIN, 48.0, "TOUCH_TARGET_MIN must be 48.0")
	assert_eq(GameConstants.GLANCING_DOT_THRESHOLD, 0.05, "GLANCING_DOT_THRESHOLD must be 0.05")
	assert_eq(GameConstants.RAY_STEP_NUDGE, 0.5, "RAY_STEP_NUDGE must be 0.5")
	assert_eq(GameConstants.MAX_RAY_DISTANCE, 3000.0, "MAX_RAY_DISTANCE must be 3000.0")

func test_beam_types_enums() -> void:
	assert_eq(BeamTypes.RayColor.WHITE, 0, "RayColor.WHITE should be 0")
	assert_eq(BeamTypes.RayColor.RED, 1, "RayColor.RED should be 1")
	assert_eq(BeamTypes.RayColor.GREEN, 2, "RayColor.GREEN should be 2")
	assert_eq(BeamTypes.RayColor.BLUE, 3, "RayColor.BLUE should be 3")

	assert_eq(BeamTypes.ColliderType.WALL, 0, "ColliderType.WALL should be 0")
	assert_eq(BeamTypes.ColliderType.MIRROR, 1, "ColliderType.MIRROR should be 1")
	assert_eq(BeamTypes.ColliderType.PRISM, 2, "ColliderType.PRISM should be 2")
	assert_eq(BeamTypes.ColliderType.SINK, 3, "ColliderType.SINK should be 3")

func test_beam_types_ray_hit() -> void:
	var default_hit: BeamTypes.RayHit = BeamTypes.RayHit.new()
	assert_vector_approx(default_hit.point, Vector2.ZERO, 0.001, "Default RayHit point should be Vector2.ZERO")
	assert_vector_approx(default_hit.normal, Vector2.ZERO, 0.001, "Default RayHit normal should be Vector2.ZERO")
	assert_eq(default_hit.collider_type, BeamTypes.ColliderType.WALL, "Default RayHit collider_type should be WALL")
	assert_eq(default_hit.collider, null, "Default RayHit collider should be null")

	var custom_point := Vector2(100.5, 200.25)
	var custom_normal := Vector2(0.0, -1.0)
	var custom_hit: BeamTypes.RayHit = BeamTypes.RayHit.new(
		custom_point,
		custom_normal,
		BeamTypes.ColliderType.MIRROR,
		null,
		RID()
	)
	assert_vector_approx(custom_hit.point, custom_point, 0.001, "Custom RayHit point mismatch")
	assert_vector_approx(custom_hit.normal, custom_normal, 0.001, "Custom RayHit normal mismatch")
	assert_eq(custom_hit.collider_type, BeamTypes.ColliderType.MIRROR, "Custom RayHit collider_type mismatch")

func test_beam_types_segment() -> void:
	var default_segment: BeamTypes.Segment = BeamTypes.Segment.new()
	assert_vector_approx(default_segment.a, Vector2.ZERO, 0.001, "Default Segment a should be Vector2.ZERO")
	assert_vector_approx(default_segment.b, Vector2.ZERO, 0.001, "Default Segment b should be Vector2.ZERO")
	assert_eq(default_segment.color, BeamTypes.RayColor.WHITE, "Default Segment color should be WHITE")

	var custom_a := Vector2(10.0, 20.0)
	var custom_b := Vector2(300.0, 400.0)
	var custom_segment: BeamTypes.Segment = BeamTypes.Segment.new(custom_a, custom_b, BeamTypes.RayColor.GREEN)
	assert_vector_approx(custom_segment.a, custom_a, 0.001, "Custom Segment a mismatch")
	assert_vector_approx(custom_segment.b, custom_b, 0.001, "Custom Segment b mismatch")
	assert_eq(custom_segment.color, BeamTypes.RayColor.GREEN, "Custom Segment color mismatch")

func test_assertion_utilities() -> void:
	assert_true(true, "assert_true should succeed for true")
	assert_eq(123, 123, "assert_eq should succeed for equal values")
	assert_vector_approx(Vector2(1.0001, 2.0001), Vector2(1.0, 2.0), 0.01, "assert_vector_approx should succeed within tolerance")

# --- Unit Tests for BeamTracer (M1 Issue 02) ---

func test_beam_tracer_open_ray_hits_nothing() -> void:
	var mock_cast := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		return null
	
	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_cast, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segments.size(), 1, "Open ray should produce exactly 1 segment")
	if segments.size() > 0:
		assert_vector_approx(segments[0].a, Vector2.ZERO, 0.001, "Open ray segment start should be origin")
		assert_vector_approx(segments[0].b, Vector2(GameConstants.MAX_RAY_DISTANCE, 0.0), 0.001, "Open ray segment end should be origin + dir * MAX_RAY_DISTANCE")
		assert_eq(segments[0].color, BeamTypes.RayColor.WHITE, "Open ray default color should be WHITE")

	var custom_origin := Vector2(100.0, 50.0)
	var custom_dir := Vector2.DOWN
	var red_segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_cast, custom_origin, custom_dir, BeamTypes.RayColor.RED)
	assert_eq(red_segments.size(), 1, "Red open ray should produce 1 segment")
	if red_segments.size() > 0:
		assert_vector_approx(red_segments[0].a, custom_origin, 0.001, "Red ray start mismatch")
		assert_vector_approx(red_segments[0].b, custom_origin + custom_dir * GameConstants.MAX_RAY_DISTANCE, 0.001, "Red ray end mismatch")
		assert_eq(red_segments[0].color, BeamTypes.RayColor.RED, "Red ray color mismatch")

func test_beam_tracer_ray_stops_on_wall() -> void:
	var hit_point := Vector2(250.0, 0.0)
	var mock_cast := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		return BeamTypes.RayHit.new(
			hit_point,
			Vector2.LEFT,
			BeamTypes.ColliderType.WALL,
			null,
			RID()
		)
	
	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_cast, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segments.size(), 1, "Wall hit should produce exactly 1 segment terminating at wall")
	if segments.size() > 0:
		assert_vector_approx(segments[0].a, Vector2.ZERO, 0.001, "Wall ray segment start should be origin")
		assert_vector_approx(segments[0].b, hit_point, 0.001, "Wall ray segment end should be hit.point")
		assert_eq(segments[0].color, BeamTypes.RayColor.WHITE, "Wall ray segment color should match incident color")

func test_beam_tracer_max_bounces_limit() -> void:
	var call_count: Array[int] = [0]
	var mock_infinite_cast := func(origin: Vector2, dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		call_count[0] += 1
		return BeamTypes.RayHit.new(
			origin + dir * 50.0,
			-dir,
			BeamTypes.ColliderType.WALL,
			null,
			RID()
		)
	
	var max_b: int = 5
	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_infinite_cast, Vector2.ZERO, Vector2.RIGHT, BeamTypes.RayColor.BLUE, max_b)
	assert_eq(call_count[0], 1, "Wall hit terminates ray tracing")
	assert_eq(segments.size(), 1, "Should generate segment up to hit point")

	var zero_segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_infinite_cast, Vector2.ZERO, Vector2.RIGHT, BeamTypes.RayColor.BLUE, 0)
	assert_eq(zero_segments.size(), 0, "max_bounces = 0 should return empty segments")

func test_beam_tracer_direction_normalized() -> void:
	var mock_cast := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		return null
	
	var unnormalized_dir := Vector2(100.0, 0.0)
	var origin := Vector2(50.0, 50.0)
	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_cast, origin, unnormalized_dir)
	assert_eq(segments.size(), 1, "Unnormalized direction should still produce 1 segment")
	if segments.size() > 0:
		assert_vector_approx(segments[0].a, origin, 0.001, "Origin mismatch")
		assert_vector_approx(segments[0].b, origin + Vector2.RIGHT * GameConstants.MAX_RAY_DISTANCE, 0.001, "Endpoint should use normalized direction")

func test_beam_tracer_zero_direction() -> void:
	var mock_cast := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		return null
	
	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_cast, Vector2.ZERO, Vector2.ZERO)
	assert_eq(segments.size(), 0, "Zero direction vector should produce empty segments")

# --- Unit Tests for BeamRenderer (M1 Issue 03) ---

func test_beam_renderer_pool_initialization() -> void:
	var renderer: BeamRenderer = BeamRenderer.new()
	renderer._init_pool()
	
	assert_eq(renderer.get_child_count(), 64, "BeamRenderer pool should have 64 total Line2D children (32 pairs)")
	assert_eq(renderer._halo_lines.size(), 32, "BeamRenderer should have 32 halo lines")
	assert_eq(renderer._core_lines.size(), 32, "BeamRenderer should have 32 core lines")

	if renderer._halo_lines.size() > 0:
		var halo: Line2D = renderer._halo_lines[0]
		assert_eq(halo.width, GameConstants.BEAM_WIDTH, "Halo line width should equal GameConstants.BEAM_WIDTH (6.0)")
		assert_true(halo.material is CanvasItemMaterial, "Halo line should use CanvasItemMaterial")
		var mat: CanvasItemMaterial = halo.material as CanvasItemMaterial
		assert_eq(mat.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "Halo material blend mode should be BLEND_MODE_ADD")
		assert_eq(halo.visible, false, "Pooled halo lines should initially be hidden")

	if renderer._core_lines.size() > 0:
		var core: Line2D = renderer._core_lines[0]
		assert_eq(core.width, 2.0, "Core line width should be 2.0")
		assert_eq(core.default_color, Color.WHITE, "Core line default color should be pure WHITE")
		assert_eq(core.visible, false, "Pooled core lines should initially be hidden")

	renderer.free()

func test_beam_renderer_render_segments() -> void:
	var renderer: BeamRenderer = BeamRenderer.new()
	
	var seg0 := BeamTypes.Segment.new(Vector2(0, 0), Vector2(100, 0), BeamTypes.RayColor.RED)
	var seg1 := BeamTypes.Segment.new(Vector2(100, 0), Vector2(200, 100), BeamTypes.RayColor.BLUE)
	var segments: Array[BeamTypes.Segment] = [seg0, seg1]

	renderer.render_segments(segments)

	var halo0: Line2D = renderer._halo_lines[0]
	var core0: Line2D = renderer._core_lines[0]
	assert_eq(halo0.visible, true, "Active halo 0 should be visible")
	assert_eq(core0.visible, true, "Active core 0 should be visible")
	assert_eq(halo0.points.size(), 2, "Halo 0 points size should be 2")
	assert_vector_approx(halo0.points[0], seg0.a, 0.001, "Halo 0 start point mismatch")
	assert_vector_approx(halo0.points[1], seg0.b, 0.001, "Halo 0 end point mismatch")
	assert_eq(halo0.default_color, BeamRenderer.COLOR_PALETTE[BeamTypes.RayColor.RED], "Halo 0 color should match RED palette")
	assert_eq(core0.default_color, Color.WHITE, "Core 0 color should remain pure white")

	var halo1: Line2D = renderer._halo_lines[1]
	var core1: Line2D = renderer._core_lines[1]
	assert_eq(halo1.visible, true, "Active halo 1 should be visible")
	assert_eq(core1.visible, true, "Active core 1 should be visible")
	assert_eq(halo1.default_color, BeamRenderer.COLOR_PALETTE[BeamTypes.RayColor.BLUE], "Halo 1 color should match BLUE palette")

	var halo2: Line2D = renderer._halo_lines[2]
	var core2: Line2D = renderer._core_lines[2]
	assert_eq(halo2.visible, false, "Inactive halo 2 should be hidden")
	assert_eq(core2.visible, false, "Inactive core 2 should be hidden")

	renderer.free()

func test_beam_renderer_surplus_hiding() -> void:
	var renderer: BeamRenderer = BeamRenderer.new()
	
	var segs: Array[BeamTypes.Segment] = [
		BeamTypes.Segment.new(Vector2.ZERO, Vector2(50, 0), BeamTypes.RayColor.WHITE),
		BeamTypes.Segment.new(Vector2(50, 0), Vector2(100, 0), BeamTypes.RayColor.GREEN),
		BeamTypes.Segment.new(Vector2(100, 0), Vector2(150, 0), BeamTypes.RayColor.RED),
	]
	renderer.render_segments(segs)
	assert_eq(renderer._halo_lines[2].visible, true, "Halo 2 should be visible when 3 segments rendered")

	var single_seg: Array[BeamTypes.Segment] = [
		BeamTypes.Segment.new(Vector2.ZERO, Vector2(50, 0), BeamTypes.RayColor.WHITE),
	]
	renderer.render_segments(single_seg)
	assert_eq(renderer._halo_lines[0].visible, true, "Halo 0 should be visible")
	assert_eq(renderer._halo_lines[1].visible, false, "Halo 1 should be hidden after count reduction")
	assert_eq(renderer._halo_lines[2].visible, false, "Halo 2 should be hidden after count reduction")

	renderer.free()

func test_beam_renderer_zero_allocations() -> void:
	var renderer: BeamRenderer = BeamRenderer.new()
	renderer._init_pool()
	var initial_child_count: int = renderer.get_child_count()
	assert_eq(initial_child_count, 64, "Initial child count should be 64")

	for cycle in range(5):
		var segs: Array[BeamTypes.Segment] = []
		for s in range(cycle + 1):
			segs.append(BeamTypes.Segment.new(Vector2(s * 10, 0), Vector2((s + 1) * 10, 0), BeamTypes.RayColor.WHITE))
		renderer.render_segments(segs)

	assert_eq(renderer.get_child_count(), initial_child_count, "Child count must remain constant across render_segments calls")
	renderer.free()

# --- Unit Tests for LightSource (M1 Issue 04) ---

func test_light_source_defaults() -> void:
	var light_source: LightSource = LightSource.new()
	assert_eq(light_source.beam_color, BeamTypes.RayColor.WHITE, "LightSource default beam_color should be WHITE")
	assert_eq(light_source.emission_offset, LightSource.DEFAULT_EMISSION_OFFSET, "LightSource default emission_offset should match DEFAULT_EMISSION_OFFSET")
	light_source.free()

func test_light_source_emission_direction() -> void:
	var light_source: LightSource = LightSource.new()
	
	light_source.rotation = 0.0
	assert_vector_approx(light_source.get_emission_direction(), Vector2.RIGHT, 0.001, "Emission direction at rot 0 should be Vector2.RIGHT")

	light_source.rotation = PI / 2.0
	assert_vector_approx(light_source.get_emission_direction(), Vector2.DOWN, 0.001, "Emission direction at rot 90deg should be Vector2.DOWN")

	light_source.rotation = PI
	assert_vector_approx(light_source.get_emission_direction(), Vector2.LEFT, 0.001, "Emission direction at rot 180deg should be Vector2.LEFT")

	light_source.rotation = -PI / 2.0
	assert_vector_approx(light_source.get_emission_direction(), Vector2.UP, 0.001, "Emission direction at rot -90deg should be Vector2.UP")

	light_source.free()

func test_light_source_emission_origin() -> void:
	var light_source: LightSource = LightSource.new()
	light_source.position = Vector2(100.0, 200.0)
	
	light_source.rotation = 0.0
	assert_vector_approx(light_source.get_emission_origin(), Vector2(124.0, 200.0), 0.001, "Emission origin at rot 0 mismatch")

	light_source.rotation = PI / 2.0
	assert_vector_approx(light_source.get_emission_origin(), Vector2(100.0, 224.0), 0.001, "Emission origin at rot 90deg mismatch")

	light_source.emission_offset = 30.0
	light_source.rotation = 0.0
	assert_vector_approx(light_source.get_emission_origin(), Vector2(130.0, 200.0), 0.001, "Emission origin with custom offset mismatch")

	light_source.free()

func test_light_source_scene_instantiation() -> void:
	var scene_res: PackedScene = load("res://scenes/objects/light_source.tscn")
	assert_true(scene_res != null, "res://scenes/objects/light_source.tscn should load")
	if scene_res != null:
		var instance: Node = scene_res.instantiate()
		assert_true(instance is LightSource, "Scene root should be instance of LightSource")
		var body_visual: Node = instance.get_node_or_null("BodyVisual")
		assert_true(body_visual != null, "LightSource scene should have BodyVisual node")
		var nozzle_visual: Node = instance.get_node_or_null("NozzleVisual")
		assert_true(nozzle_visual != null, "LightSource scene should have NozzleVisual node")
		instance.free()

# --- End-to-End Integration Tests (M1 Issue 05) ---

func test_m1_test_level_scene_structure() -> void:
	var instance: Node = M1_LEVEL_SCENE.instantiate()
	assert_true(instance is M1TestLevel, "Scene root should be instance of M1TestLevel")

	var beam_renderer_node: Node = instance.get_node_or_null("BeamRenderer")
	assert_true(beam_renderer_node is BeamRenderer, "Level should contain BeamRenderer")

	var light_source_node: Node = instance.get_node_or_null("LightSource")
	assert_true(light_source_node is LightSource, "Level should contain LightSource")

	var wall_node: StaticBody2D = instance.get_node_or_null("Wall") as StaticBody2D
	assert_true(wall_node != null, "Level should contain Wall")
	if wall_node != null:
		assert_eq(wall_node.collision_layer, 1, "Wall collision layer should be 1")

	instance.free()

func test_m1_test_level_beam_tracing_physics() -> void:
	var level: M1TestLevel = M1_LEVEL_SCENE.instantiate() as M1TestLevel
	var space: PhysicsDirectSpaceState2D = root.world_2d.direct_space_state

	var body_rid: RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(body_rid, root.world_2d.space)
	var shape_rid: RID = PhysicsServer2D.rectangle_shape_create()
	PhysicsServer2D.shape_set_data(shape_rid, Vector2(20.0, 150.0))
	PhysicsServer2D.body_add_shape(body_rid, shape_rid, Transform2D(0.0, Vector2(800.0, 540.0)))
	PhysicsServer2D.body_set_collision_layer(body_rid, 1)

	var segments: Array[BeamTypes.Segment] = level.update_beam(space)
	assert_eq(segments.size(), 1, "Should produce 1 segment from light source to wall")
	if segments.size() > 0:
		var seg: BeamTypes.Segment = segments[0]
		assert_vector_approx(seg.a, Vector2(224.0, 540.0), 0.001, "Segment start should match light source aperture origin")
		assert_vector_approx(seg.b, Vector2(780.0, 540.0), 1.0, "Segment end should terminate at wall face (x=780)")
		assert_eq(seg.color, BeamTypes.RayColor.WHITE, "Beam color should be WHITE")

	PhysicsServer2D.free_rid(shape_rid)
	PhysicsServer2D.free_rid(body_rid)
	level.free()

func test_m1_test_level_open_space_tracing() -> void:
	var level: M1TestLevel = M1_LEVEL_SCENE.instantiate() as M1TestLevel
	var space: PhysicsDirectSpaceState2D = root.world_2d.direct_space_state

	var segments: Array[BeamTypes.Segment] = level.update_beam(space)
	assert_eq(segments.size(), 1, "Should produce 1 open ray segment")
	if segments.size() > 0:
		var seg: BeamTypes.Segment = segments[0]
		assert_vector_approx(seg.a, Vector2(224.0, 540.0), 0.001, "Segment start should be aperture origin")
		assert_vector_approx(seg.b, Vector2(224.0 + GameConstants.MAX_RAY_DISTANCE, 540.0), 1.0, "Segment should reach MAX_RAY_DISTANCE")

	level.free()

func test_m1_test_level_dirty_flag() -> void:
	var level: M1TestLevel = M1_LEVEL_SCENE.instantiate() as M1TestLevel
	assert_eq(level.is_dirty, true, "Level should start in dirty state")
	level._process(0.016)
	assert_eq(level.is_dirty, false, "Level should clear dirty flag after process frame")
	level.mark_dirty()
	assert_eq(level.is_dirty, true, "mark_dirty() should set is_dirty to true")
	level.free()

# --- Unit Tests for Wall (M2 Issue 01) ---

func test_wall_scene_instantiation() -> void:
	var wall: Wall = WALL_SCENE.instantiate() as Wall
	assert_true(wall != null, "Wall scene should instantiate as Wall")
	if wall != null:
		assert_eq(wall.collision_layer, 1, "Wall should be on collision layer 1 (walls)")
		assert_eq(wall.collision_mask, 0, "Wall collision_mask should be 0")
		var col_shape: CollisionShape2D = wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
		assert_true(col_shape != null, "Wall should have CollisionShape2D")
		if col_shape != null:
			assert_true(col_shape.shape is RectangleShape2D, "Wall shape should be RectangleShape2D")
		var visual: ColorRect = wall.get_node_or_null("Visual") as ColorRect
		assert_true(visual != null, "Wall should have Visual ColorRect")
		wall.free()

func test_wall_properties() -> void:
	var wall: Wall = Wall.new()
	assert_eq(wall.collider_type, BeamTypes.ColliderType.WALL, "Wall collider_type should be BeamTypes.ColliderType.WALL")
	wall._ready()
	assert_eq(wall.collision_layer, 1, "Wall should default to collision layer 1")
	assert_eq(wall.collision_mask, 0, "Wall should default to collision mask 0")
	wall.free()

func test_wall_ray_termination() -> void:
	var hit_point := Vector2(300.0, 100.0)
	var mock_cast := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		return BeamTypes.RayHit.new(
			hit_point,
			Vector2.LEFT,
			BeamTypes.ColliderType.WALL,
			null,
			RID()
		)

	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(mock_cast, Vector2(50.0, 100.0), Vector2.RIGHT)
	assert_eq(segments.size(), 1, "Ray hitting Wall must terminate with exactly 1 segment")
	if segments.size() > 0:
		assert_vector_approx(segments[0].a, Vector2(50.0, 100.0), 0.001, "Segment start should be ray origin")
		assert_vector_approx(segments[0].b, hit_point, 0.001, "Segment end should terminate at Wall hit point")
		assert_eq(segments[0].color, BeamTypes.RayColor.WHITE, "Segment color should match incident ray color")

# --- Unit Tests for Mirror Optical Object & Reflection (M2 Issue 02) ---

func test_mirror_scene_instantiation() -> void:
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	assert_true(mirror != null, "Mirror scene should instantiate as Mirror")
	if mirror != null:
		assert_eq(mirror.collision_layer, 2, "Mirror should be on collision layer 2 (mirrors)")
		assert_eq(mirror.collision_mask, 0, "Mirror collision_mask should be 0")
		var col_shape: CollisionShape2D = mirror.get_node_or_null("CollisionShape2D") as CollisionShape2D
		assert_true(col_shape != null, "Mirror should have CollisionShape2D")
		if col_shape != null:
			assert_true(col_shape.shape is RectangleShape2D, "Mirror shape should be RectangleShape2D")
			var rect_shape: RectangleShape2D = col_shape.shape as RectangleShape2D
			assert_vector_approx(rect_shape.size, Vector2(120.0, 16.0), 0.001, "Mirror shape size should be (120, 16)")
		var visual_body: ColorRect = mirror.get_node_or_null("VisualBody") as ColorRect
		assert_true(visual_body != null, "Mirror should have VisualBody ColorRect")
		var normal_ind: Line2D = mirror.get_node_or_null("NormalIndicator") as Line2D
		assert_true(normal_ind != null, "Mirror should have NormalIndicator Line2D")
		mirror.free()

func test_mirror_properties_and_normal() -> void:
	var mirror: Mirror = Mirror.new()
	assert_eq(mirror.collider_type, BeamTypes.ColliderType.MIRROR, "Mirror collider_type should be MIRROR")
	mirror._ready()
	assert_eq(mirror.collision_layer, 2, "Mirror should default to collision layer 2")
	assert_eq(mirror.collision_mask, 0, "Mirror should default to collision mask 0")

	var signal_emitted: Array[bool] = [false]
	mirror.transformed.connect(func(): signal_emitted[0] = true)
	mirror.rotation = 0.5
	mirror._notification(CanvasItem.NOTIFICATION_TRANSFORM_CHANGED)
	assert_true(signal_emitted[0], "Mirror should emit transformed signal upon transform change")

	mirror.rotation = 0.0
	assert_vector_approx(mirror.get_facing_normal(), Vector2.UP, 0.001, "Normal at rot 0 should be Vector2.UP")

	mirror.rotation = PI / 2.0
	assert_vector_approx(mirror.get_facing_normal(), Vector2.RIGHT, 0.001, "Normal at rot 90deg should be Vector2.RIGHT")

	mirror.rotation = PI
	assert_vector_approx(mirror.get_facing_normal(), Vector2.DOWN, 0.001, "Normal at rot 180deg should be Vector2.DOWN")

	mirror.rotation = -PI / 2.0
	assert_vector_approx(mirror.get_facing_normal(), Vector2.LEFT, 0.001, "Normal at rot -90deg should be Vector2.LEFT")

	mirror.rotation = deg_to_rad(45.0)
	var expected_45 := Vector2.UP.rotated(deg_to_rad(45.0)).normalized()
	assert_vector_approx(mirror.get_facing_normal(), expected_45, 0.001, "Normal at rot 45deg mismatch")

	mirror.free()

func test_mirror_90_degree_reflection() -> void:
	# Ray travelling RIGHT hits a -45° mirror (reflecting UP)
	var mirror_normal_neg := Vector2.UP.rotated(deg_to_rad(-45.0)).normalized()
	var fake_cast_up := func(origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		if origin == Vector2.ZERO:
			var hit := BeamTypes.RayHit.new()
			hit.point = Vector2(100, 0)
			hit.normal = mirror_normal_neg
			hit.collider_type = BeamTypes.ColliderType.MIRROR
			return hit
		return null

	var segments_up: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast_up, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segments_up.size(), 2, "90-degree reflection should produce 2 segments")
	if segments_up.size() >= 2:
		assert_vector_approx(segments_up[0].a, Vector2.ZERO, 0.001, "Incoming segment start should be origin")
		assert_vector_approx(segments_up[0].b, Vector2(100, 0), 0.001, "Incoming segment end should be mirror hit point")
		assert_vector_approx(segments_up[1].a, Vector2(100, 0), 1.0, "Outgoing segment start should be near hit point")
		var out_dir: Vector2 = (segments_up[1].b - segments_up[1].a).normalized()
		assert_vector_approx(out_dir, Vector2.UP, 0.001, "Reflected direction off -45deg mirror should be UP (0, -1)")

	# Ray travelling RIGHT hits a +45° mirror (reflecting DOWN)
	var mirror_normal_pos := Vector2.UP.rotated(deg_to_rad(45.0)).normalized()
	var fake_cast_down := func(origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		if origin == Vector2.ZERO:
			var hit := BeamTypes.RayHit.new()
			hit.point = Vector2(100, 0)
			hit.normal = mirror_normal_pos
			hit.collider_type = BeamTypes.ColliderType.MIRROR
			return hit
		return null

	var segments_down: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast_down, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segments_down.size(), 2, "90-degree reflection should produce 2 segments")
	if segments_down.size() >= 2:
		var out_dir_down: Vector2 = (segments_down[1].b - segments_down[1].a).normalized()
		assert_vector_approx(out_dir_down, Vector2.DOWN, 0.001, "Reflected direction off +45deg mirror should be DOWN (0, 1)")

func test_mirror_two_sided_reflection() -> void:
	# Facing normal is UP (0, -1)
	var normal := Vector2.UP
	var fake_cast_two_sided := func(origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		if origin == Vector2(0, -100) or origin == Vector2(0, 100):
			var hit := BeamTypes.RayHit.new()
			hit.point = Vector2(100, 0)
			hit.normal = normal
			hit.collider_type = BeamTypes.ColliderType.MIRROR
			return hit
		return null

	# Ray A strikes "front" face from top-left (dir = (1, 1).normalized())
	var dir_front := Vector2(1, 1).normalized()
	var segs_front: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast_two_sided, Vector2(0, -100), dir_front)
	assert_eq(segs_front.size(), 2, "Front face hit should produce 2 segments")
	if segs_front.size() >= 2:
		var out_front: Vector2 = (segs_front[1].b - segs_front[1].a).normalized()
		var expected_out_front := Vector2(1, -1).normalized()
		assert_vector_approx(out_front, expected_out_front, 0.001, "Front face reflection angle mismatch")

	# Ray B strikes "back" face from bottom-left (dir = (1, -1).normalized())
	var dir_back := Vector2(1, -1).normalized()
	var segs_back: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast_two_sided, Vector2(0, 100), dir_back)
	assert_eq(segs_back.size(), 2, "Back face hit should produce 2 segments")
	if segs_back.size() >= 2:
		var out_back: Vector2 = (segs_back[1].b - segs_back[1].a).normalized()
		var expected_out_back := Vector2(1, 1).normalized()
		assert_vector_approx(out_back, expected_out_back, 0.001, "Back face reflection angle mismatch")

func test_mirror_double_bounce_z_path() -> void:
	# Origin (0, 100) -> Mirror 1 at (200, 100) rotated 45° (reflects DOWN)
	# Mirror 2 at (200, 300) rotated 45° (parallel mirror, reflects DOWN to RIGHT) -> Open space
	var m1_normal := Vector2.UP.rotated(deg_to_rad(45.0)).normalized()
	var m2_normal := Vector2.UP.rotated(deg_to_rad(45.0)).normalized()

	var fake_cast := func(origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		if (origin - Vector2(0, 100)).length() < 1.0:
			var hit := BeamTypes.RayHit.new()
			hit.point = Vector2(200, 100)
			hit.normal = m1_normal
			hit.collider_type = BeamTypes.ColliderType.MIRROR
			return hit
		elif (origin - Vector2(200, 100)).length() < 2.0:
			var hit := BeamTypes.RayHit.new()
			hit.point = Vector2(200, 300)
			hit.normal = m2_normal
			hit.collider_type = BeamTypes.ColliderType.MIRROR
			return hit
		return null

	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast, Vector2(0, 100), Vector2.RIGHT)
	assert_eq(segments.size(), 3, "Z-path across two mirrors should produce exactly 3 segments")
	if segments.size() >= 3:
		# Segment 0: horizontal to Mirror 1
		assert_vector_approx(segments[0].a, Vector2(0, 100), 0.001, "Seg 0 start mismatch")
		assert_vector_approx(segments[0].b, Vector2(200, 100), 0.001, "Seg 0 end mismatch")
		var dir0: Vector2 = (segments[0].b - segments[0].a).normalized()
		assert_vector_approx(dir0, Vector2.RIGHT, 0.001, "Seg 0 direction should be RIGHT")

		# Segment 1: vertical down to Mirror 2
		assert_vector_approx(segments[1].a, Vector2(200, 100), 1.0, "Seg 1 start mismatch")
		assert_vector_approx(segments[1].b, Vector2(200, 300), 0.001, "Seg 1 end mismatch")
		var dir1: Vector2 = (segments[1].b - segments[1].a).normalized()
		assert_vector_approx(dir1, Vector2.DOWN, 0.001, "Seg 1 direction should be DOWN")

		# Segment 2: horizontal to open space
		assert_vector_approx(segments[2].a, Vector2(200, 300), 1.0, "Seg 2 start mismatch")
		var dir2: Vector2 = (segments[2].b - segments[2].a).normalized()
		assert_vector_approx(dir2, Vector2.RIGHT, 0.001, "Seg 2 direction should be RIGHT")

# --- Unit Tests for Glancing Absorption & Loop Safety (M2 Issue 03) ---

func test_glancing_hit_absorbed() -> void:
	# Near-parallel normal -> |dot(d, n)| < 0.05 -> absorbed
	var fake_cast := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		var hit := BeamTypes.RayHit.new()
		hit.point = Vector2(100, 0)
		hit.normal = Vector2(0.01, 0.9999).normalized()
		hit.collider_type = BeamTypes.ColliderType.MIRROR
		return hit

	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segments.size(), 1, "Glancing hit (|d.n| < 0.05) must terminate immediately with 1 segment")
	if segments.size() > 0:
		assert_vector_approx(segments[0].a, Vector2.ZERO, 0.001, "Segment start should be origin")
		assert_vector_approx(segments[0].b, Vector2(100, 0), 0.001, "Segment end should be hit point")

func test_glancing_angle_boundary() -> void:
	# Test just below threshold (0.04 -> absorbed)
	var fake_cast_sub := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		var hit := BeamTypes.RayHit.new()
		hit.point = Vector2(100, 0)
		hit.normal = Vector2(0.04, 0.9992).normalized()
		hit.collider_type = BeamTypes.ColliderType.MIRROR
		return hit

	var segs_sub: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast_sub, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segs_sub.size(), 1, "Incidence with dot 0.04 (< 0.05) must be absorbed")

	# Test just above threshold (0.06 -> reflected)
	var call_idx: Array[int] = [0]
	var fake_cast_sup := func(_origin: Vector2, _dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		call_idx[0] += 1
		if call_idx[0] == 1:
			var hit := BeamTypes.RayHit.new()
			hit.point = Vector2(100, 0)
			hit.normal = Vector2(0.06, 0.9982).normalized()
			hit.collider_type = BeamTypes.ColliderType.MIRROR
			return hit
		return null

	var segs_sup: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast_sup, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segs_sup.size(), 2, "Incidence with dot 0.06 (>= 0.05) must reflect and produce 2 segments")

func test_parallel_mirrors_infinite_loop_safety() -> void:
	# Two parallel mirrors reflecting back and forth
	var fake_cast := func(origin: Vector2, dir: Vector2, _exclude: Array[RID]) -> BeamTypes.RayHit:
		var hit := BeamTypes.RayHit.new()
		hit.point = origin + dir * 100.0
		hit.normal = -dir
		hit.collider_type = BeamTypes.ColliderType.MIRROR
		return hit

	var segments: Array[BeamTypes.Segment] = BeamTracer.trace(fake_cast, Vector2.ZERO, Vector2.RIGHT)
	assert_eq(segments.size(), GameConstants.MAX_BOUNCES, "Parallel mirrors must safely terminate at exactly MAX_BOUNCES (24)")

# --- Integration Tests for Multi-Mirror Test Level (M2 Issue 04) ---

func test_m2_test_level_scene_structure() -> void:
	var instance: Node = M2_LEVEL_SCENE.instantiate()
	assert_true(instance != null, "M2 test level should instantiate")
	if instance == null:
		return

	var renderer_node: Node = instance.get_node_or_null("BeamRenderer")
	assert_true(renderer_node is BeamRenderer, "Level should contain BeamRenderer")

	var light_source_node: Node = instance.get_node_or_null("LightSource")
	assert_true(light_source_node is LightSource, "Level should contain LightSource")
	if light_source_node is LightSource:
		assert_vector_approx((light_source_node as LightSource).position, Vector2(200, 300), 0.001, "LightSource position mismatch")

	var mirror1_node: Node = instance.get_node_or_null("Mirror1")
	assert_true(mirror1_node is Mirror, "Level should contain Mirror1")
	if mirror1_node is Mirror:
		assert_eq((mirror1_node as Mirror).collision_layer, 2, "Mirror1 collision layer should be 2")
		assert_vector_approx((mirror1_node as Mirror).position, Vector2(600, 300), 0.001, "Mirror1 position mismatch")

	var mirror2_node: Node = instance.get_node_or_null("Mirror2")
	assert_true(mirror2_node is Mirror, "Level should contain Mirror2")
	if mirror2_node is Mirror:
		assert_eq((mirror2_node as Mirror).collision_layer, 2, "Mirror2 collision layer should be 2")
		assert_vector_approx((mirror2_node as Mirror).position, Vector2(600, 700), 0.001, "Mirror2 position mismatch")

	var wall_node: Node = instance.get_node_or_null("Wall")
	assert_true(wall_node is Wall, "Level should contain Wall")
	if wall_node is Wall:
		assert_eq((wall_node as Wall).collision_layer, 1, "Wall collision layer should be 1")
		assert_vector_approx((wall_node as Wall).position, Vector2(1200, 700), 0.001, "Wall position mismatch")

	var p_top: Node = instance.get_node_or_null("PerimeterTop")
	assert_true(p_top is Wall, "Level should contain PerimeterTop")
	var p_bot: Node = instance.get_node_or_null("PerimeterBottom")
	assert_true(p_bot is Wall, "Level should contain PerimeterBottom")
	var p_left: Node = instance.get_node_or_null("PerimeterLeft")
	assert_true(p_left is Wall, "Level should contain PerimeterLeft")
	var p_right: Node = instance.get_node_or_null("PerimeterRight")
	assert_true(p_right is Wall, "Level should contain PerimeterRight")

	instance.free()

func test_m2_test_level_dirty_flag() -> void:
	var level: M2TestLevel = M2_LEVEL_SCENE.instantiate() as M2TestLevel
	level._ready()
	assert_eq(level.is_dirty, true, "Level should start in dirty state")
	level._process(0.016)
	assert_eq(level.is_dirty, false, "Level should clear dirty flag after process frame")
	var m1: Mirror = level.get_node("Mirror1") as Mirror
	assert_true(m1 != null, "Mirror1 should exist in level")
	if m1 != null:
		m1.rotation += 0.1
		m1._notification(CanvasItem.NOTIFICATION_TRANSFORM_CHANGED)
		assert_eq(level.is_dirty, true, "Rotating mirror in level should invalidate dirty state")
	level.free()

func test_m2_test_level_physics_reflection() -> void:
	var level: M2TestLevel = M2_LEVEL_SCENE.instantiate() as M2TestLevel
	var space: PhysicsDirectSpaceState2D = root.world_2d.direct_space_state

	# Create Mirror 1 in physics space
	var mirror1: Mirror = Mirror.new()
	mirror1.rotation = deg_to_rad(45.0)
	var m1_body_rid: RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(m1_body_rid, root.world_2d.space)
	PhysicsServer2D.body_attach_object_instance_id(m1_body_rid, mirror1.get_instance_id())
	var m1_shape_rid: RID = PhysicsServer2D.rectangle_shape_create()
	PhysicsServer2D.shape_set_data(m1_shape_rid, Vector2(60.0, 8.0))
	PhysicsServer2D.body_add_shape(m1_body_rid, m1_shape_rid, Transform2D(deg_to_rad(45.0), Vector2(600.0, 300.0)))
	PhysicsServer2D.body_set_collision_layer(m1_body_rid, 2)

	# Create Wall in physics space to catch reflected ray
	var wall: Wall = Wall.new()
	var wall_body_rid: RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(wall_body_rid, root.world_2d.space)
	PhysicsServer2D.body_attach_object_instance_id(wall_body_rid, wall.get_instance_id())
	var wall_shape_rid: RID = PhysicsServer2D.rectangle_shape_create()
	PhysicsServer2D.shape_set_data(wall_shape_rid, Vector2(20.0, 20.0))
	PhysicsServer2D.body_add_shape(wall_body_rid, wall_shape_rid, Transform2D(0.0, Vector2(600.0, 700.0)))
	PhysicsServer2D.body_set_collision_layer(wall_body_rid, 1)

	var segments: Array[BeamTypes.Segment] = level.update_beam(space)
	assert_eq(segments.size(), 2, "Physics reflection should produce 2 segments (incident + reflected to wall)")
	if segments.size() >= 2:
		assert_vector_approx(segments[0].a, Vector2(224.0, 300.0), 0.001, "Segment 0 start should be aperture origin")
		assert_vector_approx(segments[0].b, Vector2(600.0, 300.0), 15.0, "Segment 0 end should hit mirror near (600, 300)")
		var out_dir: Vector2 = (segments[1].b - segments[1].a).normalized()
		assert_vector_approx(out_dir, Vector2.DOWN, 0.001, "Segment 1 direction should be vertically DOWN")
		assert_vector_approx(segments[1].b, Vector2(600.0, 700.0), 25.0, "Segment 1 end should terminate at wall near y=700")

	PhysicsServer2D.free_rid(m1_shape_rid)
	PhysicsServer2D.free_rid(m1_body_rid)
	PhysicsServer2D.free_rid(wall_shape_rid)
	PhysicsServer2D.free_rid(wall_body_rid)
	mirror1.free()
	wall.free()
	level.free()

func test_m2_test_level_z_path_physics() -> void:
	var level: M2TestLevel = M2_LEVEL_SCENE.instantiate() as M2TestLevel
	var space: PhysicsDirectSpaceState2D = root.world_2d.direct_space_state

	# Mirror 1 at (600, 300) rotated 45° (reflects RIGHT to DOWN)
	var mirror1: Mirror = Mirror.new()
	mirror1.rotation = deg_to_rad(45.0)
	var m1_body: RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(m1_body, root.world_2d.space)
	PhysicsServer2D.body_attach_object_instance_id(m1_body, mirror1.get_instance_id())
	var m1_shape: RID = PhysicsServer2D.rectangle_shape_create()
	PhysicsServer2D.shape_set_data(m1_shape, Vector2(60.0, 8.0))
	PhysicsServer2D.body_add_shape(m1_body, m1_shape, Transform2D(deg_to_rad(45.0), Vector2(600.0, 300.0)))
	PhysicsServer2D.body_set_collision_layer(m1_body, 2)

	# Mirror 2 at (600, 700) rotated 45° (reflects DOWN to RIGHT)
	var mirror2: Mirror = Mirror.new()
	mirror2.rotation = deg_to_rad(45.0)
	var m2_body: RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(m2_body, root.world_2d.space)
	PhysicsServer2D.body_attach_object_instance_id(m2_body, mirror2.get_instance_id())
	var m2_shape: RID = PhysicsServer2D.rectangle_shape_create()
	PhysicsServer2D.shape_set_data(m2_shape, Vector2(60.0, 8.0))
	PhysicsServer2D.body_add_shape(m2_body, m2_shape, Transform2D(deg_to_rad(45.0), Vector2(600.0, 700.0)))
	PhysicsServer2D.body_set_collision_layer(m2_body, 2)

	# Terminating Wall at (1200, 700)
	var wall: Wall = Wall.new()
	var wall_body: RID = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_space(wall_body, root.world_2d.space)
	PhysicsServer2D.body_attach_object_instance_id(wall_body, wall.get_instance_id())
	var wall_shape: RID = PhysicsServer2D.rectangle_shape_create()
	PhysicsServer2D.shape_set_data(wall_shape, Vector2(20.0, 150.0))
	PhysicsServer2D.body_add_shape(wall_body, wall_shape, Transform2D(0.0, Vector2(1200.0, 700.0)))
	PhysicsServer2D.body_set_collision_layer(wall_body, 1)

	var segments: Array[BeamTypes.Segment] = level.update_beam(space)
	assert_eq(segments.size(), 3, "Z-path physics query should produce 3 segments (M1 -> M2 -> Wall)")
	if segments.size() >= 3:
		# Segment 0: horizontal to Mirror 1
		assert_vector_approx(segments[0].a, Vector2(224.0, 300.0), 0.001, "Seg 0 start mismatch")
		assert_vector_approx(segments[0].b, Vector2(600.0, 300.0), 15.0, "Seg 0 hit M1 mismatch")
		var dir0: Vector2 = (segments[0].b - segments[0].a).normalized()
		assert_vector_approx(dir0, Vector2.RIGHT, 0.001, "Seg 0 direction should be RIGHT")

		# Segment 1: vertical down to Mirror 2
		assert_vector_approx(segments[1].a, Vector2(600.0, 300.0), 20.0, "Seg 1 start mismatch")
		assert_vector_approx(segments[1].b, Vector2(600.0, 700.0), 30.0, "Seg 1 hit M2 mismatch")
		var dir1: Vector2 = (segments[1].b - segments[1].a).normalized()
		assert_vector_approx(dir1, Vector2.DOWN, 0.001, "Seg 1 direction should be DOWN")

		# Segment 2: horizontal to terminating Wall
		assert_vector_approx(segments[2].a, Vector2(600.0, 700.0), 30.0, "Seg 2 start mismatch")
		assert_vector_approx(segments[2].b, Vector2(1200.0, 700.0), 35.0, "Seg 2 hit Wall mismatch")
		var dir2: Vector2 = (segments[2].b - segments[2].a).normalized()
		assert_vector_approx(dir2, Vector2.RIGHT, 0.001, "Seg 2 direction should be RIGHT")

	PhysicsServer2D.free_rid(m1_shape)
	PhysicsServer2D.free_rid(m1_body)
	PhysicsServer2D.free_rid(m2_shape)
	PhysicsServer2D.free_rid(m2_body)
	PhysicsServer2D.free_rid(wall_shape)
	PhysicsServer2D.free_rid(wall_body)
	mirror1.free()
	mirror2.free()
	wall.free()
	level.free()

func test_m2_test_level_zero_allocations() -> void:
	var level: M2TestLevel = M2_LEVEL_SCENE.instantiate() as M2TestLevel
	var space: PhysicsDirectSpaceState2D = root.world_2d.direct_space_state
	var renderer: BeamRenderer = level.get_node("BeamRenderer") as BeamRenderer
	renderer._init_pool()
	var initial_child_count: int = renderer.get_child_count()
	assert_eq(initial_child_count, 64, "Initial pooled child count should be 64")

	for i in range(10):
		level.update_beam(space)

	assert_eq(renderer.get_child_count(), initial_child_count, "BeamRenderer child count must remain constant (zero runtime allocations)")
	level.free()

# --- M0 Regression Tests ---

func test_m0_main_scene_load() -> void:
	var scene_res: PackedScene = load("res://scenes/main.tscn")
	assert_true(scene_res != null, "res://scenes/main.tscn should load")
	if scene_res != null:
		var instance: Node = scene_res.instantiate()
		assert_true(instance != null, "Main scene should instantiate")
		if instance != null:
			instance.free()

func test_m0_main_scene_hierarchy() -> void:
	var scene_res: PackedScene = load("res://scenes/main.tscn")
	if scene_res != null:
		var root_node: Node = scene_res.instantiate()
		if root_node != null:
			var bg: ColorRect = root_node.get_node_or_null("Background") as ColorRect
			assert_true(bg != null, "Background ColorRect should exist")
			var label: Label = root_node.get_node_or_null("CenterContainer/TitleLabel") as Label
			assert_true(label != null, "CenterContainer/TitleLabel should exist")
			if label != null:
				assert_eq(label.text, "Chromatic - Shell Ready", "Title label text should match")
			root_node.free()

func test_m0_input_emulation_event() -> void:
	var scene_res: PackedScene = load("res://scenes/main.tscn")
	if scene_res != null:
		var root_node: Node = scene_res.instantiate()
		if root_node != null:
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.index = 0
			touch.position = Vector2(960, 540)
			touch.pressed = true
			root_node._unhandled_input(touch)

			var drag: InputEventScreenDrag = InputEventScreenDrag.new()
			drag.index = 0
			drag.position = Vector2(980, 540)
			drag.relative = Vector2(20, 0)
			root_node._unhandled_input(drag)

			assert_true(true, "Input handling executed without error")
			root_node.free()
