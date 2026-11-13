extends RefCounted
class_name DockingRules
## Deterministic approach gate shared by carrier docking and its tests.

const MAX_DOCK_DISTANCE: float = 18.0
const MAX_DOCK_SPEED: float = 18.0
const MIN_ALIGNMENT_DOT: float = 0.94


static func can_dock(
	distance: float,
	speed: float,
	ship_forward: Vector3,
	docking_forward: Vector3
) -> bool:
	if distance < 0.0 or speed < 0.0:
		return false
	if distance > MAX_DOCK_DISTANCE or speed > MAX_DOCK_SPEED:
		return false
	if ship_forward.length_squared() < 0.0001 or docking_forward.length_squared() < 0.0001:
		return false
	return ship_forward.normalized().dot(docking_forward.normalized()) >= MIN_ALIGNMENT_DOT
