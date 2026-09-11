class_name TestTouchInteraction
extends RefCounted

const GameConstants = preload("res://core/constants.gd")
const BeamTypes = preload("res://core/beam_types.gd")
const LevelBase = preload("res://scenes/level/level_base.gd")
const LEVEL_BASE_SCENE: PackedScene = preload("res://scenes/level/level_base.tscn")
const Mirror = preload("res://scenes/objects/mirror.gd")
const MIRROR_SCENE: PackedScene = preload("res://scenes/objects/mirror.tscn")
const Prism = preload("res://scenes/objects/prism.gd")
const PRISM_SCENE: PackedScene = preload("res://scenes/objects/prism.tscn")
const HUD = preload("res://scenes/ui/hud.gd")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")

static func test_translation_mode_activation_and_offset(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	mirror.position = Vector2(500, 500)
	level.get_objects_container().add_child(mirror)
	level._ready()

	# Touch down within <= 32px inner radius: offset (10, 5) from center
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.position = Vector2(510, 505)
	touch_down.pressed = true
	level._unhandled_input(touch_down)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.MOVE, "Touch <= 32px should activate MOVE mode")
	runner.assert_eq(level.active_drag_object, mirror, "Active drag object should be mirror")
	runner.assert_vector_approx(level.drag_offset, Vector2(10, 5), 0.001, "Drag offset should be recorded accurately")

	# Drag to (600, 600)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(610, 605)
	level._unhandled_input(drag)

	runner.assert_vector_approx(mirror.global_position, Vector2(600, 600), 0.001, "Piece should track finger maintaining grab offset")
	runner.assert_eq(level.is_dirty, true, "Drag should mark level dirty for real-time beam updates")

	# Release touch
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.position = Vector2(610, 605)
	touch_up.pressed = false
	level._unhandled_input(touch_up)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.NONE, "Release should reset drag mode to NONE")
	runner.assert_eq(level.active_drag_object, null, "Release should clear active drag object")

	level.free()

static func test_playfield_boundary_clamping(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	mirror.position = Vector2(500, 500)
	level.get_objects_container().add_child(mirror)
	level._ready()

	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.position = Vector2(500, 500)
	touch_down.pressed = true
	level._unhandled_input(touch_down)

	# Drag far past top-left boundary (-500, -500)
	var drag_out_top := InputEventScreenDrag.new()
	drag_out_top.index = 0
	drag_out_top.position = Vector2(-500, -500)
	level._unhandled_input(drag_out_top)

	runner.assert_vector_approx(mirror.global_position, Vector2(64, 64), 0.001, "Position must be clamped to top-left margin (64, 64)")

	# Drag far past bottom-right boundary (3000, 2000)
	var drag_out_bot := InputEventScreenDrag.new()
	drag_out_bot.index = 0
	drag_out_bot.position = Vector2(3000, 2000)
	level._unhandled_input(drag_out_bot)

	runner.assert_vector_approx(mirror.global_position, Vector2(1856, 1016), 0.001, "Position must be clamped to bottom-right margin (1856, 1016)")

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	level._unhandled_input(touch_up)
	level.free()

static func test_rotation_mode_and_snapping(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var prism: Prism = PRISM_SCENE.instantiate() as Prism
	prism.position = Vector2(800, 500)
	level.get_objects_container().add_child(prism)
	level._ready()

	# Touch down in outer rotation zone (> 32px from center, e.g. at (840, 500), dist = 40px)
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.position = Vector2(840, 500)
	touch_down.pressed = true
	level._unhandled_input(touch_down)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.ROTATE, "Touch > 32px should activate ROTATE mode")
	runner.assert_eq(level.active_drag_object, prism, "Active drag object should be prism")
	var ring: Line2D = prism.get_node("RotationRing") as Line2D
	runner.assert_eq(ring.visible, true, "Rotation ring should be visible during rotation drag")

	# Drag to an angle of 34 degrees: with snap enabled, should quantize to 30 degrees (2 * 15 deg)
	level.snap_enabled = true
	var angle_34 := deg_to_rad(34.0)
	var drag_snapped := InputEventScreenDrag.new()
	drag_snapped.index = 0
	drag_snapped.position = Vector2(800, 500) + Vector2(cos(angle_34), sin(angle_34)) * 40.0
	level._unhandled_input(drag_snapped)

	var expected_30 := deg_to_rad(30.0)
	runner.assert_float_approx(prism.global_rotation, expected_30, 0.001, "34deg touch should snap to 30deg (15deg increments)")
	runner.assert_eq(level.is_dirty, true, "Rotation drag should mark level dirty")

	# Test unsnapped continuous rotation
	level.snap_enabled = false
	var angle_42 := deg_to_rad(42.0)
	var drag_unsnapped := InputEventScreenDrag.new()
	drag_unsnapped.index = 0
	drag_unsnapped.position = Vector2(800, 500) + Vector2(cos(angle_42), sin(angle_42)) * 40.0
	level._unhandled_input(drag_unsnapped)

	runner.assert_float_approx(prism.global_rotation, angle_42, 0.001, "Unsnapped rotation should track continuous touch angle 42deg")

	# Release touch: ring hides
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	level._unhandled_input(touch_up)

	runner.assert_eq(ring.visible, false, "Rotation ring should hide on touch release")
	runner.assert_eq(level.drag_mode, LevelBase.DragMode.NONE, "Drag mode should reset to NONE")
	level.free()

static func test_interaction_cancels_win_hold(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	mirror.position = Vector2(500, 500)
	level.get_objects_container().add_child(mirror)
	level._ready()

	# Simulate active win hold in progress (e.g. 0.35s)
	level.win_hold_elapsed = 0.35
	runner.assert_float_approx(level.win_hold_elapsed, 0.35, 0.001, "Hold should be at 0.35s")

	# Touch down on mirror: must reset hold timer immediately
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.position = Vector2(500, 500)
	touch_down.pressed = true
	level._unhandled_input(touch_down)

	runner.assert_float_approx(level.win_hold_elapsed, 0.0, 0.001, "Touch interaction must immediately reset win hold timer to 0.0")

	# Simulate hold accumulation again and drag
	level.win_hold_elapsed = 0.2
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(510, 500)
	level._unhandled_input(drag)

	runner.assert_float_approx(level.win_hold_elapsed, 0.0, 0.001, "Drag movement must reset win hold timer to 0.0")

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	level._unhandled_input(touch_up)
	level.free()

static func test_hud_snap_toggle_and_level_reset(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	mirror.position = Vector2(300, 300)
	mirror.rotation = 0.0
	level.get_objects_container().add_child(mirror)
	level._ready()

	var hud: HUD = level.hud as HUD
	runner.assert_true(hud != null, "LevelBase should have HUD instantiated")

	# Test snap toggle signal propagation
	runner.assert_eq(level.snap_enabled, true, "Snap should default to true")
	hud._on_snap_button_pressed() # Toggles to false
	runner.assert_eq(level.snap_enabled, false, "HUD snap toggle should update LevelBase.snap_enabled to false")
	hud._on_snap_button_pressed() # Toggles back to true
	runner.assert_eq(level.snap_enabled, true, "HUD snap toggle should update LevelBase.snap_enabled back to true")

	# Move and rotate mirror away from spawn
	mirror.position = Vector2(800, 600)
	mirror.rotation = 1.5
	level.win_hold_elapsed = 0.4
	level.is_dirty = false

	# Press Reset button
	hud._on_reset_button_pressed()

	runner.assert_vector_approx(mirror.position, Vector2(300, 300), 0.001, "Reset should restore mirror position to spawn")
	runner.assert_float_approx(mirror.rotation, 0.0, 0.001, "Reset should restore mirror rotation to spawn")
	runner.assert_float_approx(level.win_hold_elapsed, 0.0, 0.001, "Reset should clear win hold timer")
	runner.assert_eq(level.is_dirty, true, "Reset should mark level dirty for immediate beam re-render")

	level.free()

static func test_top_most_selection(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var m1: Mirror = MIRROR_SCENE.instantiate() as Mirror
	m1.position = Vector2(500, 500)
	m1.z_index = 0
	var m2: Mirror = MIRROR_SCENE.instantiate() as Mirror
	m2.position = Vector2(500, 500)
	m2.z_index = 1 # Higher visual layer

	level.get_objects_container().add_child(m1)
	level.get_objects_container().add_child(m2)
	level._ready()

	# Query object at (500, 500)
	var selected: Node2D = level.get_draggable_object_at(Vector2(500, 500))
	runner.assert_eq(selected, m2, "Top-most optical piece with higher z_index should be selected")

	level.free()

static func test_rotation_ring_hover_feedback(runner: Object) -> void:
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	mirror._ready()
	var ring: Line2D = mirror.get_node("RotationRing") as Line2D
	runner.assert_eq(ring.visible, false, "Rotation ring should be hidden by default")

	# Mouse hover entered
	mirror._on_touch_target_mouse_entered()
	runner.assert_eq(ring.visible, true, "Rotation ring should become visible on hover")

	# Mouse hover exited
	mirror._on_touch_target_mouse_exited()
	runner.assert_eq(ring.visible, false, "Rotation ring should hide when hover exits")

	# Active drag rotation overrides hover
	mirror.set_rotation_ring_visible(true)
	runner.assert_eq(ring.visible, true, "Active drag rotation should keep ring visible")
	mirror._on_touch_target_mouse_exited()
	runner.assert_eq(ring.visible, true, "Exiting hover while active drag should keep ring visible")
	mirror.set_rotation_ring_visible(false)
	runner.assert_eq(ring.visible, false, "Clearing active drag should hide ring if not hovered")

	mirror.free()

static func test_hud_input_consumption_and_accessibility(runner: Object) -> void:
	var hud: HUD = HUD_SCENE.instantiate() as HUD
	var snap_btn: Button = hud.get_node("TopBar/HBoxContainer/SnapButton") as Button
	var reset_btn: Button = hud.get_node("TopBar/HBoxContainer/ResetButton") as Button

	# Verify minimum touch target height meets 48px accessibility standard
	runner.assert_true(snap_btn.custom_minimum_size.y >= 48.0, "Snap button height must be >= 48px")
	runner.assert_true(reset_btn.custom_minimum_size.y >= 48.0, "Reset button height must be >= 48px")

	# Verify buttons stop mouse/touch input propagation to game board
	runner.assert_eq(snap_btn.mouse_filter, Control.MOUSE_FILTER_STOP, "SnapButton must consume touch events")
	runner.assert_eq(reset_btn.mouse_filter, Control.MOUSE_FILTER_STOP, "ResetButton must consume touch events")

	hud.free()

static func test_mouse_touch_emulation_parity(runner: Object) -> void:
	# Verify project setting for touch emulation from mouse
	var emulate_enabled: bool = ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)
	runner.assert_eq(emulate_enabled, true, "pointing/emulate_touch_from_mouse must be enabled in project settings")

	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	var mirror: Mirror = MIRROR_SCENE.instantiate() as Mirror
	mirror.position = Vector2(600, 400)
	level.get_objects_container().add_child(mirror)
	level._ready()

	# Desktop mouse touch emulation produces InputEventScreenTouch with index 0
	var mouse_touch := InputEventScreenTouch.new()
	mouse_touch.index = 0
	mouse_touch.position = Vector2(600, 400)
	mouse_touch.pressed = true
	level._unhandled_input(mouse_touch)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.MOVE, "Emulated touch from mouse should initiate MOVE")
	runner.assert_eq(level.active_drag_object, mirror, "Mouse touch should select mirror")

	var mouse_drag := InputEventScreenDrag.new()
	mouse_drag.index = 0
	mouse_drag.position = Vector2(650, 420)
	level._unhandled_input(mouse_drag)

	runner.assert_vector_approx(mirror.global_position, Vector2(650, 420), 0.001, "Emulated mouse drag should update piece position")

	var mouse_release := InputEventScreenTouch.new()
	mouse_release.index = 0
	mouse_release.pressed = false
	level._unhandled_input(mouse_release)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.NONE, "Mouse release should end drag")

	# Test direct native mouse input events (InputEventMouseButton and InputEventMouseMotion)
	var btn_down := InputEventMouseButton.new()
	btn_down.button_index = MOUSE_BUTTON_LEFT
	btn_down.position = Vector2(650, 420)
	btn_down.pressed = true
	level._unhandled_input(btn_down)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.MOVE, "Native left mouse button press should initiate MOVE")
	runner.assert_eq(level.active_drag_object, mirror, "Native mouse press should select mirror")

	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = Vector2(700, 450)
	level._unhandled_input(motion)

	runner.assert_vector_approx(mirror.global_position, Vector2(700, 450), 0.001, "Native mouse motion should drag mirror")

	var btn_up := InputEventMouseButton.new()
	btn_up.button_index = MOUSE_BUTTON_LEFT
	btn_up.position = Vector2(700, 450)
	btn_up.pressed = false
	level._unhandled_input(btn_up)

	runner.assert_eq(level.drag_mode, LevelBase.DragMode.NONE, "Native mouse button release should end drag")

	level.free()
