extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/ocean.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var before: Dictionary = game.progress.to_data().duplicate(true)
	var position: Vector3 = game.camera.position
	game.hud.show_specimen()
	await process_frame
	var inspector = game.hud.specimen_view
	check(inspector.viewport.own_world_3d, "Specimen must use a real, independent 3D world")
	check(not game.garden.visible, "Inspection must avoid rendering the habitat behind its opaque study view")
	var meshes: Array[Node] = inspector.pivot.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() >= 4, "Specimen needs tube, interior, collar and respiratory geometry")
	var vertex_count := 0
	for mesh in meshes:
		for surface in range(mesh.mesh.get_surface_count()):
			vertex_count += mesh.mesh.surface_get_array_len(surface)
	check(vertex_count > 10000, "Detailed specimen geometry must load, not a placeholder primitive")
	inspector.show_feature("plume")
	check(inspector.distance < 2.0 and inspector.focus.y > 1.0, "Plume view must frame the respiratory structures")
	var old_angle: float = inspector.angle
	inspector._orbit(Vector2(100, 20))
	check(inspector.angle != old_angle and inspector.turned_by_user, "Orbit must rotate the 3D specimen")
	inspector.show_feature("tube")
	check(inspector.detail.text.contains("no mouth"), "Tube view must show sourced biology")
	inspector.show_feature("symbiosis")
	check(inspector.detail.text.contains("proposed game mechanic"), "Research concept must distinguish fiction from observed biology")
	var air: float = game.air
	game._process(10.0)
	check(game.air == air and game.camera.position == position, "Inspection must pause expedition movement and life support")
	check(game.progress.to_data() == before, "Preview must not award unearned discoveries or overwrite progress")
	game.hud.close_modal()
	await process_frame
	check(not is_instance_valid(inspector), "Closing inspection must dispose of its viewport and model")
	check(game.garden.visible, "Closing inspection must restore the habitat")
	game.queue_free()
	await process_frame
	print("Specimen checks: %d passed / %d total; %d model vertices" % [checks-failures, checks, vertex_count])
	quit(1 if failures else 0)
