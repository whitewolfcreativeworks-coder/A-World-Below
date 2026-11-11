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
	game.progress = load("res://scripts/progress.gd").new()
	game.hud.close_modal()
	check(game.chunks.size() == 9, "Compact terrain neighborhood must load")
	check(game.hud.pad.get_global_rect().position.y > 0, "Touch controls must be on-screen")
	check(game.hud.interact_button.get_global_rect().position.x > game.hud.root.size.x / 2, "Context action must be anchored to the right")
	game.camera.position = game.animals[0].position + Vector3(0, 0, 7)
	game.interact()
	check(game.progress.discovered.has("atolla"), "Approach and interact must scan creature")
	game.interact()
	check(game.progress.discovered.count("atolla") == 1, "Scanning again must not duplicate discovery even with other animals nearby")
	var ids: Array[String] = []
	for i in range(4):
		var id := "intro:%d" % i
		ids.append(id)
		game.camera.position = game.resources[id].position + Vector3(0, 2, 0)
		game.interact()
	check(game.progress.cargo == 4, "Expedition must gather four fragments")
	game.camera.position = game.HOME + Vector3(0, 0, 10)
	game._update_air(1.0)
	check(game.progress.cargo == 0 and game.progress.bank == 4, "Returning must deposit cargo")
	game.build_home()
	check(game.progress.modules == 1 and game.progress.bank == 0, "Player must be able to build first capsule")
	# Depleted resources must remain absent when their terrain unloads and reloads.
	var chunk := Vector2i(1, 0)
	var resource_id: String = game.generator.resource_id(chunk, 0)
	game.progress.collect(resource_id)
	var original_positions = game.generator.resource_positions(chunk)
	game.camera.position = Vector3(800, 0, 800)
	game._refresh_chunks(true)
	game.camera.position = game.SPAWN
	game._refresh_chunks(true)
	check(not game.resources.has(resource_id), "Collected resource must stay depleted after chunk reload")
	check(game.generator.resource_positions(chunk) == original_positions, "Exploration must not reroll resource positions")
	game.air = 1.0
	game.progress.cargo = 8
	game.camera.position = Vector3(0, 0, -100)
	game._update_air(2.0)
	check(game.camera.position == game.SPAWN and game.progress.cargo == 4 and game.air == game.MAX_AIR, "Air exhaustion must rescue the player with documented cargo loss")
	check(game.progress.discovered.has("atolla") and game.progress.modules == 1, "Rescue must preserve discoveries and village")
	var air_before: float = game.air
	game.hud.show_journal()
	game._process(10.0)
	check(game.air == air_before, "Journal must pause life support")
	game.hud.close_modal()
	var saved = load("res://scripts/progress.gd").new()
	saved.load_game()
	check(saved.modules == 1 and saved.discovered.has("atolla"), "Expedition progress must survive reload")
	game.queue_free()
	await process_frame
	print("Expedition integration checks: %d passed / %d total" % [checks - failures, checks])
	quit(1 if failures else 0)
