class_name BeamTracer

static func trace(
	cast_fn: Callable,
	origin: Vector2,
	direction: Vector2,
	color: BeamTypes.RayColor = BeamTypes.RayColor.WHITE,
	max_bounces: int = GameConstants.MAX_BOUNCES,
	exclude_rids: Array[RID] = []
) -> Array[BeamTypes.Segment]:
	var segments: Array[BeamTypes.Segment] = []
	if direction.is_zero_approx() or not cast_fn.is_valid():
		return segments

	var current_origin: Vector2 = origin
	var current_dir: Vector2 = direction.normalized()
	var current_color: BeamTypes.RayColor = color
	var current_exclude: Array[RID] = exclude_rids.duplicate()
	var bounces_remaining: int = max_bounces

	while bounces_remaining > 0:
		bounces_remaining -= 1
		var hit: BeamTypes.RayHit = cast_fn.call(current_origin, current_dir, current_exclude)

		if hit == null:
			var end_point: Vector2 = current_origin + current_dir * GameConstants.MAX_RAY_DISTANCE
			segments.append(BeamTypes.Segment.new(current_origin, end_point, current_color))
			break

		# Ray hit an obstacle or optical body
		segments.append(BeamTypes.Segment.new(current_origin, hit.point, current_color))

		if hit.collider_type == BeamTypes.ColliderType.WALL:
			# Wall absorbs light; stop tracing
			break
		else:
			# Default termination for unhandled or absorbing collision
			break

	return segments
