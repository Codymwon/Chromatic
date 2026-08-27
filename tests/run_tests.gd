class_name HeadlessTestRunner
extends SceneTree

func _init() -> void:
	print("=== Chromatic Headless Test Runner ===")
	var failures: int = 0
	
	failures += test_main_scene_load()
	failures += test_main_scene_hierarchy()
	failures += test_input_emulation_event()
	
	if failures > 0:
		print("FAILED: %d test(s) failed." % failures)
		quit(1)
	else:
		print("PASSED: All tests passed successfully.")
		quit(0)

func _instantiate_main_scene() -> Control:
	var scene_res: PackedScene = load("res://scenes/main.tscn")
	if scene_res == null:
		return null
	return scene_res.instantiate() as Control

func test_main_scene_load() -> int:
	print("[TEST] Loading res://scenes/main.tscn...")
	var instance: Control = _instantiate_main_scene()
	if instance == null:
		printerr("FAIL: Could not load or instantiate res://scenes/main.tscn")
		return 1
	instance.free()
	print("  -> OK")
	return 0

func test_main_scene_hierarchy() -> int:
	print("[TEST] Verifying main scene node hierarchy...")
	var root: Control = _instantiate_main_scene()
	if root == null:
		printerr("FAIL: Could not instantiate main scene")
		return 1
		
	var bg: ColorRect = root.get_node_or_null("Background") as ColorRect
	if bg == null:
		printerr("FAIL: Background ColorRect not found")
		root.free()
		return 1
	
	var label: Label = root.get_node_or_null("CenterContainer/TitleLabel") as Label
	if label == null:
		printerr("FAIL: CenterContainer/TitleLabel not found")
		root.free()
		return 1
	if label.text != "Chromatic - Shell Ready":
		printerr("FAIL: Title label text mismatch: expected 'Chromatic - Shell Ready', got '%s'" % label.text)
		root.free()
		return 1
		
	root.free()
	print("  -> OK")
	return 0

func test_input_emulation_event() -> int:
	print("[TEST] Verifying MainLauncher touch input handling...")
	var root: Control = _instantiate_main_scene()
	if root == null:
		printerr("FAIL: Could not instantiate main scene")
		return 1
	
	# Test touch event handling
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(960, 540)
	touch.pressed = true
	root._unhandled_input(touch)
	
	# Test drag event handling
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(980, 540)
	drag.relative = Vector2(20, 0)
	root._unhandled_input(drag)
	
	root.free()
	print("  -> OK")
	return 0
