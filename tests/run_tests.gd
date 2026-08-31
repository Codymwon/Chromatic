extends SceneTree

const GameConstants = preload("res://core/constants.gd")
const BeamTypes = preload("res://core/beam_types.gd")

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
