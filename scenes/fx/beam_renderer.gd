class_name BeamRenderer
extends Node2D

const DEFAULT_POOL_SIZE: int = 32
const CORE_LINE_WIDTH: float = 2.0

const COLOR_PALETTE: Dictionary = {
	BeamTypes.RayColor.WHITE: Color(1.0, 1.0, 1.0, 1.0),
	BeamTypes.RayColor.RED: Color(1.0, 0.25, 0.25, 1.0),
	BeamTypes.RayColor.GREEN: Color(0.25, 1.0, 0.35, 1.0),
	BeamTypes.RayColor.BLUE: Color(0.25, 0.55, 1.0, 1.0),
}

static func get_palette_color(p_color: BeamTypes.RayColor) -> Color:
	return COLOR_PALETTE.get(p_color, Color.WHITE)

@export var pool_size: int = DEFAULT_POOL_SIZE

var _halo_lines: Array[Line2D] = []
var _core_lines: Array[Line2D] = []
var _halo_material: CanvasItemMaterial = null
var _pulse_time: float = 0.0
var _active_count: int = 0

func _ready() -> void:
	_init_pool()

func _process(delta: float) -> void:
	if _active_count <= 0:
		return
	_pulse_time += delta
	var pulse_width: float = GameConstants.BEAM_WIDTH + sin(_pulse_time * 6.0) * 0.5
	var pulse_alpha: float = 0.875 + sin(_pulse_time * 8.0) * 0.075

	for i in range(_active_count):
		var halo: Line2D = _halo_lines[i]
		halo.width = pulse_width
		halo.modulate.a = pulse_alpha

func _init_pool() -> void:
	if not _halo_lines.is_empty():
		return

	if _halo_material == null:
		_halo_material = CanvasItemMaterial.new()
		_halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for i in range(pool_size):
		var halo := Line2D.new()
		halo.name = "HaloLine_%d" % i
		halo.width = GameConstants.BEAM_WIDTH
		halo.material = _halo_material
		halo.default_color = COLOR_PALETTE[BeamTypes.RayColor.WHITE]
		halo.visible = false
		add_child(halo)
		_halo_lines.append(halo)

	for i in range(pool_size):
		var core := Line2D.new()
		core.name = "CoreLine_%d" % i
		core.width = CORE_LINE_WIDTH
		core.default_color = Color.WHITE
		core.visible = false
		add_child(core)
		_core_lines.append(core)

func render_segments(segments: Array[BeamTypes.Segment]) -> void:
	if _halo_lines.is_empty():
		_init_pool()

	_active_count = mini(segments.size(), pool_size)

	for i in range(_active_count):
		var seg: BeamTypes.Segment = segments[i]
		var halo: Line2D = _halo_lines[i]
		var core: Line2D = _core_lines[i]

		var points := PackedVector2Array([seg.a, seg.b])
		halo.points = points
		halo.default_color = COLOR_PALETTE.get(seg.color, Color.WHITE)
		halo.visible = true

		core.points = points
		core.default_color = Color.WHITE
		core.visible = true

	for i in range(_active_count, pool_size):
		var halo_hidden: Line2D = _halo_lines[i]
		halo_hidden.visible = false
		halo_hidden.width = GameConstants.BEAM_WIDTH
		halo_hidden.modulate.a = 1.0
		_core_lines[i].visible = false


