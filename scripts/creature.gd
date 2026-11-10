extends Node3D
## Stylized silhouettes informed by real animals, not scientific reconstructions.

const Forms = preload("res://scripts/forms.gd")
var record: Dictionary
var origin := Vector3.ZERO
var phase := 0.0
var age := 0.0
var body: Node3D
var fins: Array[Node3D] = []
var tendrils: MeshInstance3D
var color: Color
var line_material: StandardMaterial3D
var animated := true

func setup(info: Dictionary, at: Vector3, offset: float) -> void:
	record = info
	origin = at
	position = at
	phase = offset
	color = Color(info.color)
	body = Node3D.new()
	add_child(body)
	line_material = Forms.material(color.lightened(0.15), 0.9)
	var flesh := Forms.material(color.darkened(0.3), 0.18)
	if info.model == "jelly":
		Forms.sphere(body, Vector3.ZERO, Vector3(4.6, 1.7, 4.6), flesh)
		Forms.sphere(body, Vector3(0, 0.25, 0), Vector3(2.5, 1.6, 2.5), Forms.material(color, 0.6))
		Forms.ring(body, Vector3(0, -0.35, 0), 2.12, 0.075, line_material)
		for i in range(16):
			var angle := TAU * i / 16.0
			Forms.sphere(body, Vector3(cos(angle) * 1.9, -0.1, sin(angle) * 1.9), Vector3.ONE * 0.18, line_material)
	elif info.model == "dumbo":
		Forms.sphere(body, Vector3.ZERO, Vector3(2.5, 3.2, 2.2), flesh)
		for side in [-1.0, 1.0]:
			var fin := Node3D.new()
			fin.position = Vector3(side, 0.6, 0)
			body.add_child(fin)
			Forms.sphere(fin, Vector3(side * 0.65, 0, 0), Vector3(2.0, 0.28, 1.25), Forms.material(color, 0.25))
			fins.append(fin)
			Forms.sphere(body, Vector3(side * 0.7, 0.05, 0.9), Vector3(0.28, 0.32, 0.18), Forms.material(Color("0c2330")))
		Forms.cylinder(body, Vector3(0, -1.6, 0), 1.9, 1.7, flesh, 0.7)
	else:
		for i in range(7):
			var segment := Forms.sphere(body, Vector3(0, sin(i * PI / 7.0) * 0.25, i * 0.38 - 1.2), Vector3(1.9 - absf(i - 3.0) * 0.12, 0.85, 0.65), flesh)
			segment.rotation.x = -0.08
			for side in [-1.0, 1.0]:
				Forms.tube(body, Vector3(side * 0.6, -0.2, i * 0.38 - 1.2), Vector3(side * 1.35, -0.55, i * 0.38 - 1.4), 0.05, line_material)
		for side in [-1.0, 1.0]:
			Forms.tube(body, Vector3(side * 0.4, 0, 1.4), Vector3(side * 1.1, 0.2, 3.0), 0.035, line_material)
	if info.model != "isopod":
		tendrils = MeshInstance3D.new()
		tendrils.material_override = line_material
		body.add_child(tendrils)
		Forms.light(self, Vector3.ZERO, color, 0.75, 10.0)

func _process(delta: float) -> void:
	if not animated:
		return
	age += delta
	var t := age + phase
	if record.model == "isopod":
		rotation.y = sin(t * 0.15) * 0.2
		return
	position = origin + Vector3(sin(t * 0.19) * 2.5, sin(t * 0.65) * 1.0, cos(t * 0.21) * 2.0)
	rotation.y = sin(t * 0.23) * 0.5
	body.scale = Vector3.ONE * (1.0 + sin(t * 1.6) * 0.055)
	for i in range(fins.size()):
		fins[i].rotation.z = sin(t * 3.0 + i * PI) * 0.45
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var count := 16 if record.model == "jelly" else 8
	var radius := 2.0 if record.model == "jelly" else 1.6
	var length := 6.5 if record.model == "jelly" else 2.5
	for i in range(count):
		var angle := TAU * i / count
		var previous := Vector3(cos(angle) * radius, -0.4 if record.model == "jelly" else -2.1, sin(angle) * radius)
		for j in range(1, 17):
			var p := j / 16.0
			var drift := sin(t * 1.5 + p * 5.0 + angle) * p * 1.0
			var next := Vector3(cos(angle) * (radius + p * 0.5) + drift, (-0.4 if record.model == "jelly" else -2.1) - p * length, sin(angle) * radius + cos(t + p * 4.0) * p)
			mesh.surface_add_vertex(previous)
			mesh.surface_add_vertex(next)
			previous = next
	mesh.surface_end()
	tendrils.mesh = mesh
