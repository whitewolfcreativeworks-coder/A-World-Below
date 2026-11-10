extends RefCounted
## Original procedural forms. No downloaded meshes, textures, or recordings.

static func material(color: Color, glow: float = 0.0, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.65
	m.metallic = metal
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

static func sphere(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 20
	mesh.rings = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	node.scale = size
	parent.add_child(node)
	return node

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = mat
	parent.add_child(node)
	return node

static func tube(parent: Node3D, from: Vector3, to: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var node := cylinder(parent, (from + to) * 0.5, radius, from.distance_to(to), mat)
	var direction := (to - from).normalized()
	if absf(direction.dot(Vector3.UP)) < 0.999:
		node.quaternion = Quaternion(Vector3.UP, direction)
	return node

static func ring(parent: Node3D, at: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 24
	mesh.ring_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = mat
	parent.add_child(node)
	return node

static func light(parent: Node3D, at: Vector3, color: Color, power: float, reach: float) -> OmniLight3D:
	var node := OmniLight3D.new()
	node.position = at
	node.light_color = color
	node.light_energy = power
	node.omni_range = reach
	parent.add_child(node)
	return node

static func capsule(parent: Node3D, at: Vector3, index: int) -> Node3D:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	var shell := material(Color("244952"), 0.0, 0.65)
	var frame := material(Color("63817e"), 0.0, 0.6)
	var window := material(Color("e6be78"), 1.3)
	var trim := material(Color("62d6c0"), 1.2)
	sphere(root, Vector3.ZERO, Vector3(8.5, 4.4, 5.8), shell)
	for z in [-1.8, 1.8]:
		var rib := ring(root, Vector3(0, 0, z), 3.4, 0.13, frame)
		rib.rotation.x = PI / 2
		rib.scale.x = 1.18
		rib.scale.z = 0.64
	for x in [-2.4, 0.0, 2.4]:
		sphere(root, Vector3(x, 0.2, 2.5), Vector3(1.3, 1.55, 0.23), window)
		tube(root, Vector3(x - 0.7, -2.0, 0), Vector3(x - 0.7, -8.0, 0), 0.16, frame)
	var lip := ring(root, Vector3(0, -1.7, 0), 4.0, 0.05, trim)
	lip.scale.z = 0.65
	light(root, Vector3(0, 0.8, 4.2), Color("e7c68d"), 3.0, 24.0)
	light(root, Vector3(0, 2.8, 0), Color("61d9d0"), 2.0, 18.0)
	var sign_node := Label3D.new()
	sign_node.text = "PELAGIC / %02d" % (index + 1)
	sign_node.font_size = 36
	sign_node.pixel_size = 0.015
	sign_node.position = Vector3(0, 2.9, 0)
	sign_node.modulate = Color("b7ded7")
	sign_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(sign_node)
	return root
