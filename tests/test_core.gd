extends SceneTree

const World = preload("res://scripts/world_gen.gd")
const Progress = preload("res://scripts/progress.gd")
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var a := World.new()
	var b := World.new()
	var other := World.new(42)
	for point in [Vector2(-129, -87), Vector2(100, -256), Vector2(24, 36)]:
		check(is_equal_approx(a.height_at(point.x, point.y), b.height_at(point.x, point.y)), "Seed must recreate terrain")
	check(not is_equal_approx(a.height_at(129, -87), other.height_at(129, -87)), "Different seed must vary terrain")
	check(a.chunk_at(Vector3(-0.1, 0, -64.1)) == Vector2i(-1, -2), "Negative coordinates must floor correctly")
	check(a.resource_positions(Vector2i(-2, 3)) == b.resource_positions(Vector2i(-2, 3)), "Resources must regenerate identically")
	# The same boundary world coordinates must produce the same height on both meshes.
	var left: PackedVector3Array = a.mesh_for(Vector2i(0, 0)).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = a.mesh_for(Vector2i(0, 0)).surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].y > 0.5, "Seabed faces and lighting normals must point upward")
	var right: PackedVector3Array = a.mesh_for(Vector2i(1, 0)).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var edge: Dictionary = {}
	for vertex in left:
		if is_equal_approx(vertex.x, 64.0):
			edge[vertex.z] = vertex.y
	for vertex in right:
		if is_equal_approx(vertex.x, 64.0):
			check(is_equal_approx(edge[vertex.z], vertex.y), "Chunk boundaries must meet")
	var state := Progress.new()
	check(not state.build_module(), "Cannot build without resources")
	check(state.scan("atolla"), "First observation should register")
	check(not state.scan("atolla"), "Observation must not duplicate")
	check(state.collect("0:0:0"), "First resource should collect")
	check(not state.collect("0:0:0"), "Collected resource must not duplicate")
	for i in range(1, 20):
		state.collect("0:0:%d" % i)
	check(not state.collect("overflow"), "Cargo limit must be enforced")
	check(state.deposit() == 20 and state.cargo == 0 and state.bank == 20, "Deposit must conserve resources")
	check(state.build_module() and state.bank == 16 and state.modules == 1, "Build must spend correct amount")
	check(state.build_cost() == 6, "Upgrade cost must increase")
	var restored := Progress.new()
	restored.load_data(JSON.parse_string(JSON.stringify(state.to_data())))
	check(restored.to_data() == state.to_data(), "JSON round trip must preserve discoveries, depletion and village")
	check(state.save_game(), "Save should succeed in writable user directory")
	var disk := Progress.new()
	disk.load_game()
	check(disk.to_data() == state.to_data(), "Disk round trip must preserve progress")
	var bad := Progress.new()
	bad.load_data({"version": 1, "seed": 731942, "bank": -20, "cargo": 1000, "modules": 500, "discovered": null, "collected": 4})
	check(bad.bank == 0 and bad.cargo == 20 and bad.modules == 6 and bad.discovered.is_empty(), "Malformed save values must be bounded")
	bad.bank = 100
	check(not bad.build_module(), "Prototype module cap must be enforced")
	var content = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures.json"))
	check(content is Array and content.size() == 3, "Creature catalog must load")
	for item in content:
		check(item.has("source") and item.source.begins_with("https://") and item.has("fact"), "Creature needs scientific provenance")
	print("Core regression checks: %d passed / %d total" % [checks - failures, checks])
	quit(1 if failures else 0)
