extends SceneTree

const Water = preload("res://scripts/water_motion.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func simulate(rate: int, thrust: Vector3, water: Vector3, seconds: float = 3.0) -> Vector3:
	var v := Vector3.ZERO
	for i in range(roundi(rate * seconds)):
		v = Water.advance(v, thrust, water, 1.0 / rate)
	return v

func run() -> void:
	var coasting := Water.advance(Vector3(5,0,0), Vector3.ZERO, Vector3.ZERO, 0.1)
	check(coasting.x > 0 and coasting.x < 5, "Releasing thrust must coast with drag, not stop or accelerate")
	var current := Vector3(0.3, 0.04, -0.1)
	check(Water.advance(current, Vector3.ZERO, current, 0.1).is_equal_approx(current), "Zero relative velocity must have zero drag")
	check(simulate(60, Vector3.ZERO, current, 5).distance_to(current) < 0.01, "A passive swimmer must become entrained in the current")
	var v30 := simulate(30, Vector3.FORWARD, Vector3.ZERO)
	var v120 := simulate(120, Vector3.FORWARD, Vector3.ZERO)
	check(v30.distance_to(v120) < 0.015, "Fluid forces must remain consistent across frame rates")
	check(v120.length() > 7 and v120.length() < 9, "Thrust and quadratic drag must reach a bounded cruising speed")
	check(Water.advance(Vector3(5,0,0), Vector3.LEFT, Vector3.ZERO, 0.1).x < coasting.x, "Reverse thrust must brake harder than passive drag")
	check(Water.advance(Vector3.ONE, Vector3.UP, current, 0) == Vector3.ONE, "Zero-time updates must not move velocity")
	check(Water.current_at(Vector3.ZERO, 20) == Water.current_at(Vector3.ZERO, 20), "Current samples must be deterministic")
	check(Water.current_at(Vector3(-16,-8,-29), 20).y > Water.current_at(Vector3(300,-8,300), 20).y, "Vent region must have a localized upwelling")
	var game = load("res://scenes/ocean.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var particle: Vector3 = game.camera.position + Vector3(2,2,-2)
	game.snow_positions[0] = particle
	game.camera.position.x += 1.0
	game._animate_world(0.1)
	check(game.snow_positions[0].distance_to(particle) < 0.1, "Nearby particles must stay in the water rather than follow camera translation")
	game.sway_enabled = true
	game.toggle_sway()
	game._move_player(0.1)
	check(not game.sway_enabled and is_zero_approx(game.camera.rotation.z), "Comfort mode must remove camera roll")
	check(game.water_material.get_shader_parameter("motion_amount") == 0.0, "Comfort mode must disable optical shimmer")
	var settings := ConfigFile.new()
	check(settings.load("user://comfort.cfg") == OK and settings.get_value("display","sway",true) == false, "Comfort preference must persist locally")
	game.hud.show_journal()
	game._process(1.0)
	check(not game.sediment.emitting and game.sediment.speed_scale == 0, "Paused expedition must stop sediment emission and simulation")
	game.queue_free()
	await process_frame
	print("Water checks: %d passed / %d total" % [checks-failures, checks])
	quit(1 if failures else 0)
