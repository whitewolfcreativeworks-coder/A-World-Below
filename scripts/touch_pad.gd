extends Control
## Native touch ownership is handled before GUI dispatch by the game input router.
## This control renders that state and retains real-mouse support for desktops.
var axis := Vector2.ZERO
var finger := -1
var knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	knob = size * 0.5

func _gui_input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			finger = -2
			_update_axis(event.position)
		else:
			reset()
		accept_event()
	elif event is InputEventMouseMotion and finger == -2:
		_update_axis(event.position)
		accept_event()

func begin_touch(id: int, viewport_point: Vector2) -> void:
	finger = id
	drag_touch(viewport_point)

func drag_touch(viewport_point: Vector2) -> void:
	_update_axis(get_global_transform_with_canvas().affine_inverse() * viewport_point)

func _update_axis(point: Vector2) -> void:
	axis = ((point - size * 0.5) / 54.0).limit_length(1.0)
	knob = size * 0.5 + axis * 45.0
	queue_redraw()

func reset() -> void:
	finger = -1
	axis = Vector2.ZERO
	knob = size * 0.5
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 68, Color(0.02, 0.12, 0.16, 0.55))
	draw_arc(center, 68, 0, TAU, 64, Color(0.42, 0.73, 0.73, 0.5), 1.0, true)
	draw_line(center - Vector2(48, 0), center + Vector2(48, 0), Color(0.5, 0.8, 0.8, 0.15))
	draw_line(center - Vector2(0, 48), center + Vector2(0, 48), Color(0.5, 0.8, 0.8, 0.15))
	draw_circle(knob, 24, Color(0.4, 0.8, 0.75, 0.55))
