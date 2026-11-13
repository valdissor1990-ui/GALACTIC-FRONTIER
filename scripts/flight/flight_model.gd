extends RefCounted
class_name FlightModel
## Small deterministic movement helper. It does not read input or own scene nodes.


func integrate_velocity(
	current_velocity: Vector3,
	acceleration_direction: Vector3,
	acceleration: float,
	max_speed: float,
	drag: float,
	delta: float
) -> Vector3:
	var result: Vector3 = current_velocity

	if acceleration_direction.length_squared() > 0.0001:
		result += acceleration_direction.normalized() * acceleration * delta
	else:
		result *= exp(-drag * delta)

	return result.limit_length(max_speed)
