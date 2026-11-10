extends RefCounted
## A finger keeps the role acquired on touch-down until that same finger ends.
## Deltas come from its own absolute positions, not the emulated mouse pointer.
var move_id := -1
var look_id := -1
var positions: Dictionary = {}

func press(id: int, point: Vector2, move_area: Rect2, look_area: Rect2) -> String:
	if positions.has(id):
		return ""
	if move_id == -1 and move_area.has_point(point):
		move_id = id
		positions[id] = point
		return "move"
	if look_id == -1 and look_area.has_point(point) and not move_area.has_point(point):
		look_id = id
		positions[id] = point
		return "look"
	return ""

func drag(id: int, point: Vector2) -> Dictionary:
	if not positions.has(id):
		return {}
	var previous: Vector2 = positions[id]
	positions[id] = point
	return {"role": "move" if id == move_id else "look", "delta": point - previous}

func release(id: int) -> String:
	positions.erase(id)
	if id == move_id:
		move_id = -1
		return "move"
	if id == look_id:
		look_id = -1
		return "look"
	return ""

func reset() -> void:
	move_id = -1
	look_id = -1
	positions.clear()
