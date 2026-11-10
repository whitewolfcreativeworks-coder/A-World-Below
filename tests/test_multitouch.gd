extends SceneTree
## Dispatch native events through the viewport, including GUI and mouse emulation.
var checks := 0
var failures := 0
var game: Node3D

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func touch(id: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)

func drag(id: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = point
	# A bad shared-pointer relative value must not cause a camera jump.
	event.relative = Vector2(900, -800)
	root.push_input(event, true)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/ocean.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.hud.close_modal()
	await process_frame
	var center: Vector2 = game.hud.pad.get_global_rect().get_center()
	var forward := center + Vector2(0,-48)
	var right := Vector2(900,400)
	var yaw: float = game.yaw
	# Left-first: both roles stay active, with deltas belonging to the right finger.
	touch(7, center, true)
	drag(7, forward)
	touch(42, right, true)
	drag(42, right + Vector2(30,0))
	check(game.hud.pad.axis.y < -0.8 and game.touch_controls.move_id == 7, "Right touch must not release or steal the movement pad")
	check(is_equal_approx(game.yaw, yaw - 0.12), "Look must use its own position delta, not a shared pointer delta")
	drag(7, forward + Vector2(15,0))
	check(is_equal_approx(game.yaw, yaw - 0.12), "Joystick motion must never rotate the camera")
	touch(42, right + Vector2(30,0), false)
	check(game.touch_controls.look_id == -1 and game.hud.pad.axis.length() > 0.8, "Lifting the look thumb must keep swimming")
	touch(43, right, true)
	drag(43, right + Vector2(-15,10))
	check(game.touch_controls.move_id == 7 and game.touch_controls.look_id == 43, "Look thumb must rejoin without lifting the movement thumb")
	touch(7, forward, false)
	check(game.hud.pad.axis == Vector2.ZERO and game.touch_controls.look_id == 43, "Lifting the movement thumb must keep look ownership")
	var yaw2: float = game.yaw
	drag(43, right + Vector2(-5,10))
	check(is_equal_approx(game.yaw, yaw2 - 0.04), "Looking must continue smoothly after movement ends")
	touch(43, right, false)
	# Right-first, crossing boundaries, and unrelated extra fingers.
	touch(91, right, true)
	touch(3, center, true)
	drag(3, forward)
	check(game.touch_controls.look_id == 91 and game.touch_controls.move_id == 3, "Both touch-down orders must work")
	drag(91, center)
	check(game.touch_controls.look_id == 91 and game.touch_controls.move_id == 3, "Crossing the pad must not transfer finger roles")
	drag(3, Vector2(500,500))
	check(game.hud.pad.axis.length() > 0.9 and game.touch_controls.look_id == 91, "Joystick thumb must remain captured outside its rectangle")
	touch(55, Vector2(800,350), true)
	touch(55, Vector2(800,350), false)
	check(game.touch_controls.look_id == 91 and game.touch_controls.move_id == 3, "Unrelated fingers must not reset either control")
	touch(3, center, false, true)
	check(game.hud.pad.axis == Vector2.ZERO and game.touch_controls.look_id == 91, "Canceled touch must release only its own role")
	touch(91, right, false)
	# A third touch can hold a native RISE button while swim/look remain captured.
	touch(1, center, true)
	drag(1, forward)
	touch(2, right, true)
	var up: Button
	for node in game.hud.root.find_children("*", "Button", true, false):
		if node.get_meta("swim_vertical", 0.0) == 1.0:
			up = node
	var up_point := up.get_global_rect().get_center()
	touch(4, up_point, true)
	check(game.hud.vertical == 1 and game.hud.pad.axis.y < -0.8 and game.touch_controls.look_id == 2, "Rise must work alongside two-thumb swimming and looking")
	check(up.button_pressed, "Native hold buttons must show pressed feedback")
	drag(2, right + Vector2(12,0))
	touch(4, up_point, false)
	check(game.hud.vertical == 0 and game.touch_controls.move_id == 1 and game.touch_controls.look_id == 2, "Releasing a button must preserve both thumb controls")
	var journal: Button
	for node in game.hud.root.find_children("*", "Button", true, false):
		if node.text.begins_with("JOURNAL"):
			journal = node
	var journal_point := journal.get_global_rect().get_center()
	touch(6, journal_point, true)
	touch(6, journal_point, false)
	check(game.hud.modal, "Native action button must open the journal while both thumbs are held")
	check(game.hud.pad.axis == Vector2.ZERO and game.touch_controls.positions.is_empty(), "Opening a modal must clear all captured fingers")
	game.hud.close_modal()
	await process_frame
	touch(9, center, true)
	touch(8, right, true)
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.touch_controls.positions.is_empty() and game.hud.pad.axis == Vector2.ZERO, "App focus loss must not leave a stuck thumb")
	touch(9, center, true)
	touch(8, right, true)
	root.size_changed.emit()
	check(game.touch_controls.positions.is_empty(), "Orientation or viewport changes must discard stale touch coordinates")
	game.queue_free()
	await process_frame
	print("Multitouch checks: %d passed / %d total" % [checks-failures, checks])
	quit(1 if failures else 0)
