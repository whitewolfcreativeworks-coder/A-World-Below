extends RefCounted
## A lightweight fluid-force model, not a Navier–Stokes solver.
## Drag acts on velocity relative to the local water, so currents carry a swimmer.

const LINEAR_DRAG := 1.0
const QUADRATIC_DRAG := 0.16
const SWIM_THRUST := 18.0
const CRUISE_THRUST := 29.0

static func current_at(point: Vector3, time: float) -> Vector3:
	var x := point.x * 0.035
	var z := point.z * 0.028
	var pulse := time * 0.12
	var vent_distance := Vector2(point.x + 16.0, point.z + 29.0).length_squared()
	var upwelling := exp(-vent_distance / 280.0) * 0.13
	return Vector3(0.20 + sin(z + pulse) * 0.13, sin(x - z + pulse * 0.7) * 0.025 + upwelling, -0.08 + cos(x + pulse * 0.6) * 0.10)

static func advance(velocity: Vector3, thrust: Vector3, water: Vector3, delta: float, cruise: bool = false) -> Vector3:
	# Small bounded integration steps make drag stable across mobile frame rates.
	var remaining := clampf(delta, 0.0, 0.25)
	var result := velocity
	var force := thrust.limit_length() * (CRUISE_THRUST if cruise else SWIM_THRUST)
	while remaining > 0.000001:
		var dt := minf(remaining, 1.0 / 90.0)
		var relative := result - water
		var drag := relative * (LINEAR_DRAG + QUADRATIC_DRAG * relative.length())
		result += (force - drag) * dt
		remaining -= dt
	return result
