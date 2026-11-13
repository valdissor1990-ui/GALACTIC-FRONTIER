extends Resource
class_name ShipFlightConfig
## Data-only tuning values for the first player ship.

@export_group("Translation")
@export_range(1.0, 300.0, 1.0) var max_speed: float = 95.0
@export_range(1.0, 150.0, 1.0) var acceleration: float = 34.0
@export_range(0.0, 8.0, 0.1) var drag: float = 0.85
@export_range(1.0, 3.0, 0.05) var boost_speed_multiplier: float = 1.55
@export_range(1.0, 3.0, 0.05) var boost_acceleration_multiplier: float = 1.35
@export_range(0.1, 100.0, 0.1) var brake_drag: float = 16.0

@export_group("Rotation")
@export_range(0.1, 4.0, 0.05) var rotation_speed: float = 1.35
@export_range(0.1, 20.0, 0.1) var rotation_acceleration: float = 5.5
@export_range(0.1, 20.0, 0.1) var rotation_stabilization: float = 4.0

@export_group("Boost")
@export_range(1.0, 30.0, 0.5) var boost_capacity: float = 10.0
@export_range(0.1, 10.0, 0.1) var boost_recharge_rate: float = 2.0
