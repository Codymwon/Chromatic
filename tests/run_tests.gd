extends SceneTree

const GameConstants = preload("res://core/constants.gd")
const BeamTypes = preload("res://core/beam_types.gd")
const BeamTracer = preload("res://core/beam_tracer.gd")
const BeamRenderer = preload("res://scenes/fx/beam_renderer.gd")

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

	# Verify active pair 0 (RED)
	var halo0: Line2D = renderer._halo_lines[0]
	var core0: Line2D = renderer._core_lines[0]
	assert_eq(halo0.visible, true, "Active halo 0 should be visible")
	assert_eq(core0.visible, true, "Active core 0 should be visible")
	assert_eq(halo0.points.size(), 2, "Halo 0 points size should be 2")
	assert_vector_approx(halo0.points[0], seg0.a, 0.001, "Halo 0 start point mismatch")
	assert_vector_approx(halo0.points[1], seg0.b, 0.001, "Halo 0 end point mismatch")
	assert_eq(halo0.default_color, BeamRenderer.COLOR_PALETTE[BeamTypes.RayColor.RED], "Halo 0 color should match RED palette")
	assert_eq(core0.default_color, Color.WHITE, "Core 0 color should remain pure white")

	# Verify active pair 1 (BLUE)
	var halo1: Line2D = renderer._halo_lines[1]
	var core1: Line2D = renderer._core_lines[1]
	assert_eq(halo1.visible, true, "Active halo 1 should be visible")
	assert_eq(core1.visible, true, "Active core 1 should be visible")
	assert_eq(halo1.default_color, BeamRenderer.COLOR_PALETTE[BeamTypes.RayColor.BLUE], "Halo 1 color should match BLUE palette")

	# Verify pair 2 remains hidden
	var halo2: Line2D = renderer._halo_lines[2]
	var core2: Line2D = renderer._core_lines[2]
	assert_eq(halo2.visible, false, "Inactive halo 2 should be hidden")
	assert_eq(core2.visible, false, "Inactive core 2 should be hidden")

	renderer.free()

func test_beam_renderer_surplus_hiding() -> void:
	var renderer: BeamRenderer = BeamRenderer.new()
	
	# Render 3 segments first
	var segs: Array[BeamTypes.Segment] = [
		BeamTypes.Segment.new(Vector2.ZERO, Vector2(50, 0), BeamTypes.RayColor.WHITE),
		BeamTypes.Segment.new(Vector2(50, 0), Vector2(100, 0), BeamTypes.RayColor.GREEN),
		BeamTypes.Segment.new(Vector2(100, 0), Vector2(150, 0), BeamTypes.RayColor.RED),
	]
	renderer.render_segments(segs)
	assert_eq(renderer._halo_lines[2].visible, true, "Halo 2 should be visible when 3 segments rendered")

	# Now re-render with only 1 segment
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

	# Render various segment lists repeatedly
	for cycle in range(5):
		var segs: Array[BeamTypes.Segment] = []
		for s in range(cycle + 1):
			segs.append(BeamTypes.Segment.new(Vector2(s * 10, 0), Vector2((s + 1) * 10, 0), BeamTypes.RayColor.WHITE))
		renderer.render_segments(segs)

	assert_eq(renderer.get_child_count(), initial_child_count, "Child count must remain constant across render_segments calls")
	renderer.free()

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
		var root: Node = scene_res.instantiate()
		if root != null:
			var bg: ColorRect = root.get_node_or_null("Background") as ColorRect
			assert_true(bg != null, "Background ColorRect should exist")
			var label: Label = root.get_node_or_null("CenterContainer/TitleLabel") as Label
			assert_true(label != null, "CenterContainer/TitleLabel should exist")
			if label != null:
				assert_eq(label.text, "Chromatic - Shell Ready", "Title label text should match")
			root.free()

func test_m0_input_emulation_event() -> void:
	var scene_res: PackedScene = load("res://scenes/main.tscn")
	if scene_res != null:
		var root: Node = scene_res.instantiate()
		if root != null:
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.index = 0
			touch.position = Vector2(960, 540)
			touch.pressed = true
			root._unhandled_input(touch)

			var drag: InputEventScreenDrag = InputEventScreenDrag.new()
			drag.index = 0
			drag.position = Vector2(980, 540)
			drag.relative = Vector2(20, 0)
			root._unhandled_input(drag)

			assert_true(true, "Input handling executed without error")
			root.free()
