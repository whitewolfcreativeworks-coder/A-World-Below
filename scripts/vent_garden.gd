extends Node3D
## Compact authored research habitat. All exported mesh sources are in art-source/.

const Forms = preload("res://scripts/forms.gd")
const TISSUE = preload("res://shaders/tissue.gdshader")
var specimen: Node3D
var time := 0.0
var particles: Array[CPUParticles3D] = []
var rock_material: StandardMaterial3D
var floor_material: StandardMaterial3D
var rng := RandomNumberGenerator.new()
var colony: Array[Node3D] = []

static func mineral_material(scale_value: float = 0.4) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/materials/basalt_albedo.jpg")
	mat.albedo_color = Color("a6b1b1")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/materials/basalt_normal.jpg")
	mat.normal_scale = 1.2
	mat.roughness_texture = load("res://assets/materials/basalt_roughness.jpg")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.roughness = 0.94
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * scale_value
	mat.uv1_triplanar_sharpness = 3.0
	return mat

static func make_specimen() -> Node3D:
	var scene: PackedScene = load("res://assets/models/riftia.glb")
	var model: Node3D = scene.instantiate()
	_skin_meshes(model)
	return model

static func _skin_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mat := ShaderMaterial.new()
		mat.shader = TISSUE
		var is_plume := "plume" in node.name.to_lower() or "pinnules" in node.name.to_lower()
		var color := Color("bfaba0")
		if "plume" in node.name.to_lower():
			color = Color("a91c36")
		elif "pinnules" in node.name.to_lower():
			color = Color("e86671")
		elif "lumen" in node.name.to_lower():
			color = Color("2d1e1a")
		mat.set_shader_parameter("tissue_color", color)
		mat.set_shader_parameter("plume", 1.0 if is_plume else 0.0)
		node.material_override = mat
	for child in node.get_children():
		_skin_meshes(child)

func build(generator: RefCounted) -> void:
	rng.seed = 29384
	rock_material = mineral_material(0.72)
	floor_material = mineral_material(0.20)
	var chimney_scene: PackedScene = load("res://assets/models/chimney.glb")
	var layouts := [Vector4(-16, -29, 1.25, 0.15), Vector4(-26, -40, 1.7, -0.12), Vector4(-7, -44, 0.9, 0.18), Vector4(9, -58, 2.05, -0.07), Vector4(-35, -57, 1.0, 0.2)]
	for placement in layouts:
		var at := Vector3(placement.x, generator.height_at(placement.x, placement.y) - 0.8, placement.y)
		var chimney: Node3D = chimney_scene.instantiate()
		chimney.position = at
		chimney.scale = Vector3(1.0, placement.z, 1.0)
		chimney.rotation = Vector3(placement.w, rng.randf() * TAU, 0)
		add_child(chimney)
		_apply_mineral(chimney)
		_add_plume(at + Vector3(0, 10.0 * placement.z - 0.1, 0), placement.z)
		for i in range(4):
			var satellite: Node3D = chimney_scene.instantiate()
			satellite.position = at + Vector3(cos(i * 1.8) * 2, 0, sin(i * 1.8) * 2)
			satellite.scale = Vector3.ONE * rng.randf_range(0.18, 0.45)
			satellite.rotation.z = rng.randf_range(-0.3, 0.3)
			add_child(satellite)
			_apply_mineral(satellite)
	# Original anatomical illustration. Colony proportions are intentionally varied.
	for i in range(38):
		var angle := rng.randf() * TAU
		var radius := sqrt(rng.randf()) * 7.0
		var x := -15.0 + cos(angle) * radius
		var z := -19.0 + sin(angle) * radius * 0.7
		var worm := make_specimen()
		worm.position = Vector3(x, generator.height_at(x, z) + 0.15, z)
		worm.rotation = Vector3(rng.randf_range(-0.18, 0.18), rng.randf() * TAU, rng.randf_range(-0.24, 0.24))
		worm.scale = Vector3.ONE * rng.randf_range(0.75, 1.55)
		add_child(worm)
		colony.append(worm)
		if i == 0:
			specimen = worm
	for i in range(50):
		var x := rng.randf_range(-44, 35)
		var z := rng.randf_range(-65, 10)
		var at := Vector3(x, generator.height_at(x, z) - 0.2, z)
		var rock := Forms.sphere(self, at, Vector3(rng.randf_range(1.4, 4.5), rng.randf_range(0.9, 2.5), rng.randf_range(1.6, 4.0)), rock_material)
		rock.mesh = crag_mesh(i % 5)
		rock.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
	_add_research_lamp(Vector3(-21, -4, -7), Vector3(-14, -8, -22), Color("a0d6e6"), 24.0)
	_add_research_lamp(Vector3(-3, -3, -18), Vector3(-16, -6, -28), Color("bde3ed"), 20.0)
	Forms.light(self, Vector3(-20, 7, -40), Color("396c9b"), 6.0, 38)
	Forms.light(self, Vector3(-15, -6, -17), Color("a3c5d4"), 8.0, 24)

static func crag_mesh(seed_value: int) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 20
	sphere.rings = 14
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 3.5
	for i in range(vertices.size()):
		var p := vertices[i]
		vertices[i] *= 1.0 + noise.get_noise_3dv(p) * 0.4
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _apply_mineral(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = rock_material
	for child in node.get_children():
		_apply_mineral(child)

func _add_research_lamp(at: Vector3, toward: Vector3, color: Color, power: float) -> void:
	var pole := Forms.material(Color("5c7076"), 0, 0.7)
	Forms.tube(self, at - Vector3(0, 5, 0), at, 0.055, pole)
	Forms.sphere(self, at, Vector3(0.4, 0.3, 0.25), Forms.material(color, 1.0))
	var spot := SpotLight3D.new()
	spot.position = at
	spot.light_color = color
	spot.light_energy = power
	spot.spot_range = 35
	spot.spot_angle = 58
	add_child(spot)
	spot.look_at(toward)

func _add_plume(at: Vector3, height: float) -> void:
	var particle := CPUParticles3D.new()
	particle.position = at
	particle.amount = 100
	particle.lifetime = 12
	particle.preprocess = 12
	particle.direction = Vector3.UP
	particle.spread = 9.0
	particle.gravity = Vector3(0.04, 0.05, 0.0)
	particle.initial_velocity_min = 0.8
	particle.initial_velocity_max = 1.5 * height
	particle.scale_amount_min = 1.0
	particle.scale_amount_max = 2.2
	var scale_curve := Curve.new()
	scale_curve.max_value = 4.0
	scale_curve.add_point(Vector2(0, 0.3))
	scale_curve.add_point(Vector2(0.35, 1.0))
	scale_curve.add_point(Vector2(1, 3.5))
	particle.scale_amount_curve = scale_curve
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.12, 0.75, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	particle.color_ramp = gradient
	var quad := QuadMesh.new()
	quad.size = Vector2(2.5, 2.5)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/plume.gdshader")
	var noise := FastNoiseLite.new()
	noise.frequency = 0.035
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.noise = noise
	tex.seamless = true
	mat.set_shader_parameter("turbulence", tex)
	quad.material = mat
	particle.mesh = quad
	add_child(particle)
	particles.append(particle)

func set_paused(value: bool) -> void:
	for particle in particles:
		particle.speed_scale = 0.0 if value else 1.0
