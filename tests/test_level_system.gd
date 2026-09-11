class_name TestLevelSystem
extends RefCounted

const GameConstants = preload("res://core/constants.gd")
const BeamTypes = preload("res://core/beam_types.gd")
const LevelBase = preload("res://scenes/level/level_base.gd")
const LEVEL_BASE_SCENE: PackedScene = preload("res://scenes/level/level_base.tscn")
const LevelManagerNode = preload("res://autoload/level_manager.gd")
const WinOverlay = preload("res://scenes/ui/win_overlay.gd")
const WIN_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/win_overlay.tscn")
const HUD = preload("res://scenes/ui/hud.gd")
const LightSource = preload("res://scenes/objects/light_source.gd")
const Mirror = preload("res://scenes/objects/mirror.gd")
const Prism = preload("res://scenes/objects/prism.gd")
const GoalSink = preload("res://scenes/objects/goal_sink.gd")
const Wall = preload("res://scenes/objects/wall.gd")

static func test_levels_json_validity_and_schema(runner: Object) -> void:
	var path := "res://scenes/level/levels.json"
	runner.assert_true(FileAccess.file_exists(path), "levels.json file must exist")

	var file := FileAccess.open(path, FileAccess.READ)
	runner.assert_true(file != null, "levels.json must be readable")

	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	runner.assert_true(parsed is Dictionary, "levels.json root must be a JSON object")

	var dict := parsed as Dictionary
	runner.assert_eq(int(dict.get("version", 0)), 1, "Schema version must be 1")

	var levels: Array = dict.get("levels", [])
	runner.assert_eq(levels.size(), 8, "levels.json must contain exactly 8 authored levels")

	var valid_types := ["mirror", "prism", "sink", "wall"]
	var seen_ids := {}

	for i in range(levels.size()):
		var lvl: Variant = levels[i]
		runner.assert_true(lvl is Dictionary, "Level entry %d must be a dictionary" % i)
		var lvl_dict := lvl as Dictionary

		# Required top-level fields
		runner.assert_true(lvl_dict.has("id"), "Level %d must have an 'id'" % i)
		var id: String = str(lvl_dict.get("id", ""))
		runner.assert_true(not seen_ids.has(id), "Level id '%s' must be unique" % id)
		seen_ids[id] = true

		runner.assert_true(lvl_dict.has("title"), "Level %d must have a 'title'" % i)
		runner.assert_true(lvl_dict.has("source"), "Level %d must have a 'source'" % i)
		runner.assert_true(lvl_dict.has("objects"), "Level %d must have an 'objects' array" % i)

		# Validate source
		var src: Dictionary = lvl_dict.get("source", {})
		runner.assert_true(src.has("x") and src.has("y"), "Source must specify x and y coordinates in level %s" % id)

		# Validate objects
		var objects: Array = lvl_dict.get("objects", [])
		runner.assert_true(objects.size() > 0, "Level %s must contain optical objects" % id)
		var has_sink := false
		for obj in objects:
			var obj_dict := obj as Dictionary
			var obj_type: String = str(obj_dict.get("type", "")).to_lower()
			runner.assert_true(valid_types.has(obj_type), "Piece type '%s' in level %s must be valid" % [obj_type, id])
			runner.assert_true(obj_dict.has("x") and obj_dict.has("y"), "Object in level %s must specify x and y" % id)
			if obj_type == "sink":
				has_sink = true
				runner.assert_true(obj_dict.has("color"), "Sink in level %s must specify a color" % id)

		runner.assert_true(has_sink, "Level %s must have at least one goal sink" % id)

static func test_unknown_piece_type_assertion(runner: Object) -> void:
	# Verify validation function accepts all valid optical piece types
	runner.assert_true(LevelBase.is_valid_piece_type("mirror"), "mirror should be a recognized piece type")
	runner.assert_true(LevelBase.is_valid_piece_type("prism"), "prism should be a recognized piece type")
	runner.assert_true(LevelBase.is_valid_piece_type("sink"), "sink should be a recognized piece type")
	runner.assert_true(LevelBase.is_valid_piece_type("wall"), "wall should be a recognized piece type")

	# Verify rejection of unknown/invalid types
	runner.assert_true(not LevelBase.is_valid_piece_type("laser_gun"), "laser_gun should be rejected")
	runner.assert_true(not LevelBase.is_valid_piece_type("portal"), "portal should be rejected")
	runner.assert_true(not LevelBase.is_valid_piece_type("black_hole"), "black_hole should be rejected")
	runner.assert_true(not LevelBase.is_valid_piece_type(""), "empty type should be rejected")

static func test_save_game_persistence(runner: Object) -> void:
	var test_save := "user://test_save_persistence.cfg"
	# Clean any leftover test file
	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(test_save)

	var manager1 := LevelManagerNode.new()
	manager1.save_path = test_save
	manager1.unlocked_level = 4
	manager1.completed_levels = ["level_01", "level_02", "level_03"]
	manager1.save_game()

	runner.assert_true(FileAccess.file_exists(test_save), "Save file should be written to disk")

	# Fresh manager instance loading from disk
	var manager2 := LevelManagerNode.new()
	manager2.save_path = test_save
	manager2.load_save_data()

	runner.assert_eq(manager2.unlocked_level, 4, "Unlocked level should be restored as 4")
	runner.assert_eq(manager2.completed_levels.size(), 3, "Completed levels count should be 3")
	runner.assert_true(manager2.completed_levels.has("level_01"), "Completed levels should contain level_01")
	runner.assert_true(manager2.completed_levels.has("level_02"), "Completed levels should contain level_02")
	runner.assert_true(manager2.completed_levels.has("level_03"), "Completed levels should contain level_03")

	# Clean up
	DirAccess.remove_absolute(test_save)
	manager1.free()
	manager2.free()

static func test_dynamic_level_loading(runner: Object) -> void:
	var level: LevelBase = LEVEL_BASE_SCENE.instantiate() as LevelBase
	level._ready()

	var test_level_dict := {
		"id": "test_stage",
		"title": "Test Stage Dynamics",
		"source": { "x": 180.0, "y": 500.0, "rot_deg": 0.0, "color": "white" },
		"objects": [
			{ "type": "mirror", "x": 700.0, "y": 500.0, "rot_deg": 45.0, "draggable": true, "rotatable": false },
			{ "type": "prism", "x": 700.0, "y": 800.0, "rot_deg": 0.0, "draggable": false, "rotatable": true },
			{ "type": "sink", "color": "green", "x": 1400.0, "y": 800.0 },
			{ "type": "wall", "x": 900.0, "y": 400.0, "width": 80.0, "height": 240.0 }
		]
	}

	level.load_level(test_level_dict)

	# Verify HUD title update
	var hud: HUD = level.hud as HUD
	runner.assert_eq(hud.level_title, "Test Stage Dynamics", "HUD title should update on level load")

	# Verify instantiated nodes in Objects container
	var container: Node2D = level.get_objects_container()
	var children: Array[Node] = container.get_children()
	runner.assert_eq(children.size(), 5, "Container should contain light source + 4 optical objects")

	var mirror: Mirror = null
	var prism: Prism = null
	var sink: GoalSink = null
	var wall: Wall = null
	var source: LightSource = null

	for child in children:
		if child is Mirror:
			mirror = child as Mirror
		elif child is Prism:
			prism = child as Prism
		elif child is GoalSink:
			sink = child as GoalSink
		elif child is Wall:
			wall = child as Wall
		elif child is LightSource:
			source = child as LightSource

	runner.assert_true(source != null, "LightSource should be spawned")
	runner.assert_vector_approx(source.position, Vector2(180, 500), 0.001, "Source position should match")

	runner.assert_true(mirror != null, "Mirror should be spawned")
	runner.assert_eq(mirror.is_draggable, true, "Mirror is_draggable should be true")
	runner.assert_eq(mirror.is_rotatable, false, "Mirror is_rotatable should be false")

	runner.assert_true(prism != null, "Prism should be spawned")
	runner.assert_eq(prism.is_draggable, false, "Prism is_draggable should be false")
	runner.assert_eq(prism.is_rotatable, true, "Prism is_rotatable should be true")

	runner.assert_true(sink != null, "GoalSink should be spawned")
	runner.assert_eq(sink.required_color, BeamTypes.RayColor.GREEN, "Sink required_color should be GREEN")

	runner.assert_true(wall != null, "Wall should be spawned")
	runner.assert_float_approx(wall.wall_width, 80.0, 0.001, "Wall width should match")
	runner.assert_float_approx(wall.wall_height, 240.0, 0.001, "Wall height should match")

	# Verify immediate ray tracing
	runner.assert_true(level.get_beam_renderer() != null, "BeamRenderer should be present")

	level.free()

static func test_progression_advancement_logic(runner: Object) -> void:
	var test_save := "user://test_progression.cfg"
	if FileAccess.file_exists(test_save):
		DirAccess.remove_absolute(test_save)

	var manager := LevelManagerNode.new()
	manager.save_path = test_save
	manager.load_levels_json("res://scenes/level/levels.json")
	manager.load_save_data()

	runner.assert_eq(manager.unlocked_level, 1, "Initial progression should have Level 1 unlocked")
	runner.assert_eq(manager.current_level_index, 0, "Initial stage index should be 0")
	runner.assert_true(manager.has_next_level(), "Level 1 should have next level")

	# Complete Level 1
	manager.complete_current_level()
	runner.assert_eq(manager.unlocked_level, 2, "Completing Level 1 should unlock Level 2")
	runner.assert_true(manager.completed_levels.has("level_01"), "level_01 should be in completed_levels")

	# Advance to Level 2
	var advanced: bool = manager.load_next_level()
	runner.assert_true(advanced, "load_next_level should return true")
	runner.assert_eq(manager.current_level_index, 1, "Active stage index should now be 1")

	# Fast forward to final level (index 7)
	manager.current_level_index = 7
	runner.assert_eq(manager.has_next_level(), false, "Final level should have no next level")

	# Clean up
	DirAccess.remove_absolute(test_save)
	manager.free()

static func test_win_overlay_flow(runner: Object) -> void:
	var overlay: WinOverlay = WIN_OVERLAY_SCENE.instantiate() as WinOverlay
	overlay._ready()

	runner.assert_eq(overlay.visible, false, "Win overlay should be hidden by default")

	var next_btn: Button = overlay.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/NextButton") as Button
	var replay_btn: Button = overlay.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/ReplayButton") as Button
	var select_btn: Button = overlay.get_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/LevelSelectButton") as Button

	# Accessibility touch target height
	runner.assert_true(next_btn.custom_minimum_size.y >= 48.0, "Next button height must be >= 48px")
	runner.assert_true(replay_btn.custom_minimum_size.y >= 48.0, "Replay button height must be >= 48px")
	runner.assert_true(select_btn.custom_minimum_size.y >= 48.0, "Level select button height must be >= 48px")

	# Show victory for mid-campaign level
	overlay.show_victory("3. Angle of Attack", false)
	runner.assert_eq(overlay.visible, true, "Overlay should be visible after show_victory")
	runner.assert_eq(next_btn.visible, true, "Next button should be visible on non-final levels")
	runner.assert_eq(overlay.title_label.text, "3. Angle of Attack", "Title label should display level title")

	# Show victory for final level
	overlay.show_victory("8. Grand Chromatic Finale", true)
	runner.assert_eq(next_btn.visible, false, "Next button should be hidden on final campaign level")
	runner.assert_eq(overlay.banner_label.text, "CAMPAIGN COMPLETE!", "Banner should celebrate campaign completion")

	# Test signal emissions on buttons
	var events := {
		"next": false,
		"replay": false,
		"select": false
	}

	overlay.next_level_pressed.connect(func(): events["next"] = true)
	overlay.replay_pressed.connect(func(): events["replay"] = true)
	overlay.level_select_pressed.connect(func(): events["select"] = true)

	overlay._on_next_button_pressed()
	runner.assert_eq(events["next"], true, "Clicking Next should emit next_level_pressed")
	runner.assert_eq(overlay.visible, false, "Clicking Next should hide overlay")

	overlay._on_replay_button_pressed()
	runner.assert_eq(events["replay"], true, "Clicking Replay should emit replay_pressed")

	overlay._on_level_select_button_pressed()
	runner.assert_eq(events["select"], true, "Clicking Level Select should emit level_select_pressed")

	overlay.free()
