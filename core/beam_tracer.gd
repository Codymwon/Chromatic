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
	elif hit.collider_type == BeamTypes.ColliderType.PRISM:
		var next_exclude: Array[RID] = []
		if hit.rid.is_valid():
			next_exclude.append(hit.rid)

		if color == BeamTypes.RayColor.WHITE:
			var prism_rotation: float = 0.0
			if hit.collider != null and "rotation" in hit.collider:
				prism_rotation = hit.collider.rotation

			var half_angle_rad: float = deg_to_rad(GameConstants.PRISM_HALF_ANGLE_DEG)
			var fan_colors: Array[BeamTypes.RayColor] = [
				BeamTypes.RayColor.RED,
				BeamTypes.RayColor.GREEN,
				BeamTypes.RayColor.BLUE,
			]
			var fan_offsets: Array[float] = [
				-half_angle_rad,
				0.0,
				half_angle_rad,
			]

			for i in range(3):
				var fan_color: BeamTypes.RayColor = fan_colors[i]
				var fan_dir: Vector2 = Vector2.from_angle(prism_rotation + fan_offsets[i]).normalized()
				var fan_origin: Vector2 = hit.point + fan_dir * GameConstants.RAY_STEP_NUDGE

				_trace_recursive(
					cast_fn,
					fan_origin,
					fan_dir,
					fan_color,
					bounces_remaining - 1,
					next_exclude,
					segments
				)
		else:
			# Colored ray passes straight through without deflection or re-splitting
			var pass_origin: Vector2 = hit.point + direction * GameConstants.RAY_STEP_NUDGE
			_trace_recursive(
				cast_fn,
				pass_origin,
				direction,
				color,
				bounces_remaining - 1,
				next_exclude,
				segments
			)
	else:
		# Default termination for unhandled or absorbing collision
		return
