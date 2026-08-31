class_name BeamTypes

enum RayColor {
	WHITE,
	RED,
	GREEN,
	BLUE,
}

enum ColliderType {
	WALL,
	MIRROR,
	PRISM,
	SINK,
}

class RayHit extends RefCounted:
	var point: Vector2
	var normal: Vector2
	var collider_type: ColliderType
	var collider: Object
	var rid: RID

	func _init(
		p_point: Vector2 = Vector2.ZERO,
		p_normal: Vector2 = Vector2.ZERO,
		p_collider_type: ColliderType = ColliderType.WALL,
		p_collider: Object = null,
		p_rid: RID = RID()
	) -> void:
		point = p_point
		normal = p_normal
		collider_type = p_collider_type
		collider = p_collider
		rid = p_rid

class Segment extends RefCounted:
	var a: Vector2
	var b: Vector2
	var color: RayColor

	func _init(
		p_a: Vector2 = Vector2.ZERO,
		p_b: Vector2 = Vector2.ZERO,
		p_color: RayColor = RayColor.WHITE
	) -> void:
		a = p_a
		b = p_b
		color = p_color
