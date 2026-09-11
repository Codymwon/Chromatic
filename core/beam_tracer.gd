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
	if direction.is_zero_approx() or not cast_fn.is_valid() or max_bounces <= 0:
		return segments

	_trace_recursive(
		cast_fn,
		origin,
		direction.normalized(),
		color,
		max_bounces,
		exclude_rids,
		segments
	)
	return segments

static func _trace_recursive(
	cast_fn: Callable,
	origin: Vector2,
	direction: Vector2,
	color: BeamTypes.RayColor,
	bounces_remaining: int,
	exclude_rids: Array[RID],
	segments: Array[BeamTypes.Segment]
) -> void:
	if bounces_remaining <= 0:
		return

	var hit: BeamTypes.RayHit = cast_fn.call(origin, direction, exclude_rids)

	if hit == null:
		var end_point: Vector2 = origin + direction * GameConstants.MAX_RAY_DISTANCE
		segments.append(BeamTypes.Segment.new(origin, end_point, color))
		return

	# Ray hit an optical body or obstacle
	segments.append(BeamTypes.Segment.new(origin, hit.point, color))

	if hit.collider_type == BeamTypes.ColliderType.WALL:
		# Wall absorbs light; terminate recursion
		return
	elif hit.collider_type == BeamTypes.ColliderType.MIRROR:
		var normal: Vector2 = hit.normal.normalized()
		if normal.is_zero_approx():
			return

		var dot_prod: float = direction.dot(normal)
		if abs(dot_prod) < GameConstants.GLANCING_DOT_THRESHOLD:
			# Glancing incidence (< ~2.86 deg) is absorbed and terminates at hit.point
			return

		var reflected_dir: Vector2 = (direction - 2.0 * dot_prod * normal).normalized()
		if reflected_dir.is_zero_approx():
			return

		var next_origin: Vector2 = hit.point + reflected_dir * GameConstants.RAY_STEP_NUDGE
		var next_exclude: Array[RID] = []
		if hit.rid.is_valid():
			next_exclude.append(hit.rid)

		_trace_recursive(
			cast_fn,
			next_origin,
			reflected_dir,
			color,
			bounces_remaining - 1,
			next_exclude,
			segments
		)
	else:
		# Default termination for unhandled or absorbing collision
		return
