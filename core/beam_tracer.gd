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
		elif hit.collider_type == BeamTypes.ColliderType.MIRROR:
			var normal: Vector2 = hit.normal.normalized()
			if normal.is_zero_approx():
				break

			var dot_prod: float = current_dir.dot(normal)
			if abs(dot_prod) < GameConstants.GLANCING_DOT_THRESHOLD:
				# Glancing incidence (< ~2.86 deg) is absorbed and terminates at hit.point
				break

			var reflected_dir: Vector2 = (current_dir - 2.0 * dot_prod * normal).normalized()
			if reflected_dir.is_zero_approx():
				break

			current_origin = hit.point + reflected_dir * GameConstants.RAY_STEP_NUDGE
			current_dir = reflected_dir
			current_exclude = exclude_rids.duplicate()
			if hit.rid.is_valid():
				current_exclude.append(hit.rid)
		else:
			# Default termination for unhandled or absorbing collision
			break

	return segments
