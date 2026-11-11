extends Node3D
## Original representative forms; not scanned or species-accurate specimens.
## Static colonies are batched so habitat density does not multiply draw calls.
const Forms = preload("res://scripts/forms.gd")
var schools: MultiMeshInstance3D
var age := 0.0
var paused := false
var origins: Array[Vector3] = []
var swarm_positions: Array[Vector3] = []
var colony_positions: Array[Vector3] = []
var batches: Dictionary = {}

func _batch(key: String, mesh: Mesh, color: Color) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	node.multimesh = multi
	node.material_override = Forms.material(color)
	node.visibility_range_end = 125.0
	add_child(node)
	batches[key] = {"node":node,"transforms":[]}
	return node

func _instance(key: String, at: Vector3, scale_value: Vector3, direction: Vector3 = Vector3.UP) -> void:
	var basis := Basis.IDENTITY
	if absf(direction.normalized().dot(Vector3.UP)) < 0.999:
		basis = Basis(Quaternion(Vector3.UP,direction.normalized()))
	batches[key].transforms.append(Transform3D(basis * Basis.from_scale(scale_value), at))

func _branch(at: Vector3, toward: Vector3, radius: float) -> void:
	_instance("coral",(at+toward)*0.5,Vector3(radius,at.distance_to(toward),radius),toward-at)

func build(generator: RefCounted) -> void:
	var rod := CylinderMesh.new()
	rod.top_radius = 0.65
	rod.bottom_radius = 1
	rod.height = 1
	rod.radial_segments = 6
	_batch("coral",rod,Color("cfa497"))
	var cup := CylinderMesh.new()
	cup.top_radius = 0.55
	cup.bottom_radius = 0.25
	cup.height = 1
	cup.radial_segments = 10
	_batch("sponge",cup,Color("d6c9ae"))
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	_batch("mat",sphere,Color("c4bda4"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 74209
	# Cooler rocky perimeter: representative cold-water corals and sponges.
	for i in range(42):
		var angle := rng.randf()*TAU
		var radius := rng.randf_range(19,55)
		var at := Vector3(-13+cos(angle)*radius,0,-24+sin(angle)*radius)
		at.y = generator.height_at(at.x,at.z)+0.15
		if Vector2(at.x+16,at.z+29).length() < 14 or Vector2(at.x-19,at.z-4).length() < 13:
			continue
		colony_positions.append(at)
		var top := at + Vector3(0,rng.randf_range(1.2,3.2),0)
		_branch(at,top,0.12)
		for side in [-1.0,1.0]:
			for level in range(4):
				var start := at.lerp(top,0.25+level*0.16)
				var tip := start + Vector3(side*(1.3-level*0.15),0.7,rng.randf_range(-0.4,0.4))
				_branch(start,tip,0.055)
				_branch(tip,tip+Vector3(side*0.2,0.45,0.15),0.025)
		for j in range(4):
			var p := at + Vector3(rng.randf_range(-2,2),0,rng.randf_range(-2,2))
			p.y = generator.height_at(p.x,p.z)+0.4
			_instance("sponge",p,Vector3(0.5,rng.randf_range(0.6,1.4),0.5))
	# Pale microbial mat representations around diffuse flow, not hot vent mouths.
	for i in range(48):
		var at := Vector3(rng.randf_range(-24,-8),0,rng.randf_range(-32,-16))
		at.y = generator.height_at(at.x,at.z)+0.08
		_instance("mat",at,Vector3(rng.randf_range(0.3,1.3),0.08,rng.randf_range(0.3,1)))
	for key in batches:
		var batch: Dictionary = batches[key]
		batch.node.multimesh.instance_count = batch.transforms.size()
		for i in range(batch.transforms.size()):
			batch.node.multimesh.set_instance_transform(i,batch.transforms[i])
	schools = MultiMeshInstance3D.new()
	schools.multimesh = MultiMesh.new()
	schools.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	schools.multimesh.mesh = shrimp_mesh()
	schools.multimesh.instance_count = 48
	schools.material_override = Forms.material(Color("d6b9a1"))
	add_child(schools)
	for i in range(48):
		var p := Vector3(rng.randf_range(-26,6),0,rng.randf_range(-38,-9))
		p.y = generator.height_at(p.x,p.z)+rng.randf_range(1,5)
		origins.append(p)
	swarm_positions.resize(origins.size())
	_animate()

func _process(delta: float) -> void:
	if paused or schools == null:
		return
	age += delta
	_animate()

func _animate() -> void:
	for i in range(origins.size()):
		var t := age*0.45+i*2.4
		var p := origins[i] + Vector3(sin(t)*1.2,sin(t*1.7)*0.25,cos(t)*0.8)
		swarm_positions[i] = p
		var basis := Basis(Vector3.UP,-t).scaled(Vector3.ONE*0.7)
		schools.multimesh.set_instance_transform(i,Transform3D(basis,p))

static func shrimp_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := SphereMesh.new()
	body.radial_segments = 8
	body.rings = 4
	surface.append_from(body,0,Transform3D(Basis.IDENTITY.scaled(Vector3(0.22,0.22,0.7)),Vector3.ZERO))
	var leg := CylinderMesh.new()
	leg.radial_segments = 5
	leg.top_radius = 0.012
	leg.bottom_radius = 0.018
	leg.height = 1
	for side in [-1.0,1.0]:
		for i in range(4):
			var from := Vector3(side*0.07,-0.04,i*0.11-0.15)
			var to := from+Vector3(side*0.2,-0.12,-0.09)
			var basis := Basis(Quaternion(Vector3.UP,(to-from).normalized())) * Basis.from_scale(Vector3(1,from.distance_to(to),1))
			surface.append_from(leg,0,Transform3D(basis,(from+to)*0.5))
		var antenna_basis := Basis(Quaternion(Vector3.UP,Vector3(side*0.3,0.06,0.7).normalized())) * Basis.from_scale(Vector3(0.45,0.7,0.45))
		surface.append_from(leg,0,Transform3D(antenna_basis,Vector3(side*0.1,0.05,0.55)))
	return surface.commit()
