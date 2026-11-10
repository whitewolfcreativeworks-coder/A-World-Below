extends RefCounted
## Pure, deterministic terrain rules shared by gameplay and regression tests.
## Terrain height is in local meters; displayed depth is 1400 - camera.y.

const CHUNK_SIZE := 64.0
const SEGMENTS := 16
const WORLD_SEED := 731942

var seed_value: int
var noise := FastNoiseLite.new()

func _init(value: int = WORLD_SEED) -> void:
	seed_value = value
	noise.seed = value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.009
	noise.fractal_octaves = 4

func height_at(x: float, z: float) -> float:
	var flat := smoothstep(18.0, 65.0, Vector2(x, z).length())
	var shelf := noise.get_noise_2d(x, z) * 17.0
	var descent := maxf(0.0, -z - 35.0) * 0.10
	var trench := exp(-pow((x - 75.0) / 32.0, 2.0)) * smoothstep(25.0, 170.0, -z) * 48.0
	return -13.0 + flat * shelf - descent - trench

func rng_for(chunk: Vector2i) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = (seed_value ^ (chunk.x * 73856093) ^ (chunk.y * 19349663)) & 0x7fffffff
	return rng

func chunk_at(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / CHUNK_SIZE), floori(point.z / CHUNK_SIZE))

func resource_id(chunk: Vector2i, index: int) -> String:
	return "%d:%d:%d" % [chunk.x, chunk.y, index]

func resource_positions(chunk: Vector2i) -> Array[Vector3]:
	var rng := rng_for(chunk)
	var result: Array[Vector3] = []
	for i in range(5):
		var x := (chunk.x + rng.randf()) * CHUNK_SIZE
		var z := (chunk.y + rng.randf()) * CHUNK_SIZE
		result.append(Vector3(x, height_at(x, z) + 1.1, z))
	return result

func mesh_for(chunk: Vector2i) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := CHUNK_SIZE / SEGMENTS
	for z in range(SEGMENTS):
		for x in range(SEGMENTS):
			for corner in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var px: float = chunk.x * CHUNK_SIZE + (x + corner.x) * step
				var pz: float = chunk.y * CHUNK_SIZE + (z + corner.y) * step
				var h := height_at(px, pz)
				var tone := clampf((h + 45.0) / 60.0, 0.0, 1.0)
				surface.set_color(Color(0.025, 0.075, 0.09).lerp(Color(0.12, 0.23, 0.23), tone))
				surface.add_vertex(Vector3(px, h, pz))
	surface.generate_normals()
	return surface.commit()
