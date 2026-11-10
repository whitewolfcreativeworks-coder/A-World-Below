extends Node3D

const WorldGen = preload("res://scripts/world_gen.gd")
const Progress = preload("res://scripts/progress.gd")
const Forms = preload("res://scripts/forms.gd")
const Creature = preload("res://scripts/creature.gd")
const Hud = preload("res://scripts/hud.gd")
const VentGarden = preload("res://scripts/vent_garden.gd")
const WaterMotion = preload("res://scripts/water_motion.gd")
const TouchControls = preload("res://scripts/touch_controls.gd")
const MAX_AIR := 300.0
const HOME := Vector3(19, -5, 4)
const SPAWN := Vector3(-13, -7, -1)
const VIEW_RADIUS := 1

var generator := WorldGen.new()
var progress := Progress.new()
var camera: Camera3D
var hud: CanvasLayer
var environment: Environment
var chunks: Dictionary = {}
var resources: Dictionary = {}
var animals: Array[Node3D] = []
var records: Array = []
var village: Node3D
var snow: MultiMeshInstance3D
var smoke: Array[MeshInstance3D] = []
var target = null
var air := MAX_AIR
var elapsed := 0.0
var started := false
var yaw := 0.0
var pitch := -0.12
var velocity := Vector3.ZERO
var stream_clock := 0.0
var save_clock := 0.0
var touch_controls := TouchControls.new()
var touch_buttons: Dictionary = {}
var lamp: SpotLight3D
var audio: AudioStreamPlayer
var audio_enabled := false
var chunk_queue: Array[Vector2i] = []
var last_chunk := Vector2i(99999, 99999)
var garden: Node3D
var seabed_material: Material
var inspection_visibility: Dictionary = {}
var snow_positions := PackedVector3Array()
var snow_scales := PackedFloat32Array()
var current_water := Vector3.ZERO
var water_material: ShaderMaterial
var sediment: CPUParticles3D
var sway_enabled := true
var view_yaw := 0.0
var view_pitch := -0.12
var view_roll := 0.0
var flow_audio: AudioStreamPlayer

func set_inspection_mode(enabled: bool) -> void:
	if enabled:
		if not inspection_visibility.is_empty():
			return
		for child in get_children():
			if child is Node3D and child != camera:
				inspection_visibility[child] = child.visible
				child.visible = false
	else:
		for child in inspection_visibility:
			if is_instance_valid(child):
				child.visible = inspection_visibility[child]
		inspection_visibility.clear()

func _ready() -> void:
	progress.load_game()
	var settings := ConfigFile.new()
	if settings.load("user://comfort.cfg") == OK:
		sway_enabled = bool(settings.get_value("display", "sway", true))
	records = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures.json"))
	_setup_environment()
	_setup_camera()
	_setup_village()
	_setup_animals()
	_setup_snow()
	_setup_vent()
	_setup_sediment()
	_setup_audio()
	hud = Hud.new(self)
	add_child(hud)
	get_viewport().size_changed.connect(clear_touch_controls)
	_refresh_chunks(true)
	_setup_intro_resources()
	_pick_target()
	hud.update_status(0.0)
	get_tree().auto_accept_quit = false
	print("A World Below ready | seed=", generator.seed_value, " | inhabitants=", records.size())

func _setup_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("031320")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("4e8793")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("041a26")
	environment.fog_light_energy = 0.65
	environment.fog_density = 0.010
	environment.fog_sky_affect = 1.0
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.light_color = Color("669fa7")
	light.light_energy = 0.40
	light.rotation_degrees = Vector3(-65, -30, 0)
	add_child(light)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.position = SPAWN
	camera.rotation = Vector3(pitch, yaw, 0)
	camera.fov = 66
	camera.near = 0.2
	camera.far = 180
	add_child(camera)
	lamp = SpotLight3D.new()
	lamp.light_color = Color("a1e5dd")
	lamp.light_energy = 5.0
	lamp.spot_range = 65
	lamp.spot_angle = 48
	lamp.spot_attenuation = 0.7
	camera.add_child(lamp)
	get_viewport().msaa_3d = Viewport.MSAA_2X
	var water := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	water.mesh = quad
	water.extra_cull_margin = 16384
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://shaders/underwater.gdshader")
	# Refraction reads opaque scenery first; translucent water particles draw after it.
	water_material.render_priority = -100
	water.material_override = water_material
	camera.add_child(water)

func _setup_village() -> void:
	village = Node3D.new()
	add_child(village)
	Forms.capsule(village, HOME, 0)
	var beacon := Forms.material(Color("87e8d2"), 1.5)
	Forms.tube(village, HOME + Vector3(0, 2, 0), HOME + Vector3(0, 12, 0), 0.08, beacon)
	Forms.sphere(village, HOME + Vector3(0, 12, 0), Vector3.ONE * 0.65, beacon)
	for i in range(progress.modules):
		_add_capsule(i)

func _add_capsule(index: int) -> void:
	var angle := TAU * index / 6.0
	var point := HOME + Vector3(cos(angle) * 14, 0, sin(angle) * 14)
	Forms.capsule(village, point, index + 1)
	Forms.tube(village, HOME, point, 0.7, Forms.material(Color("1c454e"), 0.0, 0.5))

func _setup_animals() -> void:
	var positions := [Vector3(18, 3, -75), Vector3(34, -3, -65), Vector3(4, generator.height_at(4, -45) + 0.5, -45)]
	for i in range(records.size()):
		var animal := Creature.new()
		add_child(animal)
		animal.setup(records[i], positions[i], i * 2.7)
		animal.scale = Vector3.ONE * 0.55
		animals.append(animal)

func _setup_snow() -> void:
	snow = MultiMeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.045, 0.045)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/marine_snow.gdshader")
	mesh.material = material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = 850
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in range(multi.instance_count):
		var point := camera.position + Vector3(rng.randf_range(-22, 22), rng.randf_range(-14, 14), rng.randf_range(-22, 22))
		var size := rng.randf_range(0.45, 1.6)
		snow_positions.append(point)
		snow_scales.append(size)
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), point))
		multi.set_instance_color(i, Color(1, 1, 1, rng.randf_range(0.35, 0.85)))
	snow.multimesh = multi
	snow.custom_aabb = AABB(camera.position - Vector3(24, 16, 24), Vector3(48, 32, 48))
	add_child(snow)

func _setup_vent() -> void:
	garden = VentGarden.new()
	add_child(garden)
	garden.build(generator)
	seabed_material = garden.floor_material

func _setup_sediment() -> void:
	sediment = CPUParticles3D.new()
	sediment.emitting = false
	sediment.amount = 36
	sediment.lifetime = 4.5
	sediment.local_coords = false
	sediment.direction = Vector3.UP
	sediment.spread = 75
	sediment.gravity = Vector3(0.07, 0.05, -0.02)
	sediment.initial_velocity_min = 0.12
	sediment.initial_velocity_max = 0.5
	sediment.scale_amount_min = 0.3
	sediment.scale_amount_max = 1.5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.1))
	curve.add_point(Vector2(0.4, 0.7))
	curve.add_point(Vector2(1, 1))
	sediment.scale_amount_curve = curve
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	colors.colors = PackedColorArray([Color(1,1,1,0), Color.WHITE, Color(1,1,1,0)])
	sediment.color_ramp = colors
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4, 1.4)
	var material: ShaderMaterial = garden.particles[0].mesh.material.duplicate()
	material.set_shader_parameter("tint", Color(0.14, 0.19, 0.20, 0.24))
	quad.material = material
	sediment.mesh = quad
	add_child(sediment)

func _setup_audio() -> void:
	# Quiet synthesized ambience; it contains no third-party sound recordings.
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 22050 * 8
	var bytes := PackedByteArray()
	bytes.resize(stream.loop_end * 2)
	for i in range(stream.loop_end):
		var t := float(i) / stream.mix_rate
		var sample := (sin(TAU * 55 * t) * 0.07 + sin(TAU * 82.5 * t) * 0.025 + sin(TAU * 110 * t) * 0.018) * (0.8 + 0.2 * sin(TAU * t / 8))
		bytes.encode_s16(i * 2, int(sample * 32767))
	stream.data = bytes
	audio = AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = -14
	add_child(audio)
	var wash := AudioStreamWAV.new()
	wash.format = AudioStreamWAV.FORMAT_16_BITS
	wash.mix_rate = 22050
	wash.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wash.loop_end = 22050 * 4
	var wash_bytes := PackedByteArray()
	wash_bytes.resize(wash.loop_end * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 92
	var filtered := 0.0
	for i in range(wash.loop_end):
		filtered = filtered * 0.96 + rng.randf_range(-1, 1) * 0.04
		var t := float(i) / wash.mix_rate
		var envelope := smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(3.94, 4.0, t))
		wash_bytes.encode_s16(i * 2, int(filtered * envelope * 20000))
	wash.data = wash_bytes
	flow_audio = AudioStreamPlayer.new()
	flow_audio.stream = wash
	flow_audio.volume_db = -40
	add_child(flow_audio)

func toggle_audio() -> void:
	audio_enabled = not audio_enabled
	if audio_enabled:
		audio.play()
		flow_audio.play()
	else:
		audio.stop()
		flow_audio.stop()
	hud.sound_button.text = "SOUND ON" if audio_enabled else "SOUND OFF"

func toggle_sway() -> void:
	sway_enabled = not sway_enabled
	hud.sway_button.text = "SWAY ON" if sway_enabled else "SWAY OFF"
	var settings := ConfigFile.new()
	settings.set_value("display", "sway", sway_enabled)
	settings.save("user://comfort.cfg")

func start_expedition() -> void:
	if not started:
		started = true
		hud.toast("Vent Garden · Look for the crimson tubeworm colony. Tap SPECIMEN to examine its anatomy.")

func _process(delta: float) -> void:
	elapsed += delta
	for animal in animals:
		animal.animated = not hud.modal
	garden.set_paused(hud.modal)
	sediment.speed_scale = 0.0 if hud.modal else 1.0
	if hud.modal:
		sediment.emitting = false
		flow_audio.volume_db = -44
	if not hud.modal and started:
		_move_player(delta)
		_update_air(delta)
		_animate_world(delta)
		stream_clock += delta
		if stream_clock > 0.3:
			stream_clock = 0
			_refresh_chunks()
			_pick_target()
		if not chunk_queue.is_empty():
			_create_chunk(chunk_queue.pop_front())
		save_clock += delta
		if save_clock > 15:
			save_clock = 0
			_save()
	hud.update_status(delta)

func _move_player(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input.x += 1
	input = (input + hud.pad.axis).limit_length(1.0)
	var vertical: float = hud.vertical
	if Input.is_physical_key_pressed(KEY_SPACE):
		vertical += 1
	if Input.is_physical_key_pressed(KEY_C):
		vertical -= 1
	var direction := camera.basis * Vector3(input.x, 0, input.y) + Vector3.UP * vertical
	var dt := minf(delta, 0.2)
	current_water = WaterMotion.current_at(camera.position, elapsed)
	velocity = WaterMotion.advance(velocity, direction, current_water, dt, Input.is_physical_key_pressed(KEY_SHIFT))
	var next := camera.position + velocity * dt
	var floor_height := generator.height_at(next.x, next.z) + 2.0
	if next.y < floor_height:
		next.y = floor_height
		velocity.y = maxf(0.0, velocity.y)
	next.y = minf(next.y, 50.0)
	# Capsule collision volumes; terrain collision uses the generator's height field.
	for pod in village.get_children():
		if not pod is Node3D or not pod.get_child_count() > 5:
			continue
		var local: Vector3 = (next - pod.position) / Vector3(5.3, 3.5, 4.1)
		if local.length() < 1.0:
			next = pod.position + local.normalized() * Vector3(5.3, 3.5, 4.1)
	camera.position = next
	if sway_enabled:
		view_yaw = lerp_angle(view_yaw, yaw, 1.0 - exp(-9.0 * dt))
		view_pitch = lerpf(view_pitch, pitch, 1.0 - exp(-9.0 * dt))
		var bank := clampf(-input.x * 0.014 - wrapf(yaw - view_yaw, -PI, PI) * 0.04, -0.025, 0.025)
		view_roll = lerpf(view_roll, bank + sin(elapsed * 0.65) * 0.0015, 1.0 - exp(-2.5 * dt))
	else:
		view_yaw = yaw
		view_pitch = pitch
		view_roll = 0.0
	camera.rotation = Vector3(view_pitch, view_yaw, view_roll)
	var relative_speed := (velocity - current_water).length()
	camera.fov = lerpf(camera.fov, 66.0 + minf(relative_speed / 8.0, 1.0) * 1.4 if sway_enabled else 66.0, 1.0 - exp(-2.0 * dt))
	water_material.set_shader_parameter("swim_speed", relative_speed)
	water_material.set_shader_parameter("motion_amount", 1.0 if sway_enabled else 0.0)
	water_material.set_shader_parameter("thermal_amount", exp(-Vector2(next.x + 16.0, next.z + 29.0).length_squared() / 500.0))
	flow_audio.volume_db = lerpf(flow_audio.volume_db, -42.0 + minf(relative_speed / 8.0, 1.0) * 19.0, 1.0 - exp(-2.0 * dt))
	sediment.position = Vector3(next.x, floor_height - 1.7, next.z)
	sediment.emitting = next.y - floor_height < 1.2 and relative_speed > 1.5

func _animate_world(_delta: float) -> void:
	for i in range(snow_positions.size()):
		var point := snow_positions[i]
		point += (WaterMotion.current_at(point, elapsed) + Vector3(0, -0.035, 0)) * minf(_delta, 0.2)
		var relative := point - camera.position
		point = camera.position + Vector3(wrapf(relative.x, -22, 22), wrapf(relative.y, -14, 14), wrapf(relative.z, -22, 22))
		snow_positions[i] = point
		snow.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * snow_scales[i]), point))
	snow.custom_aabb = AABB(camera.position - Vector3(24, 16, 24), Vector3(48, 32, 48))
	for i in range(smoke.size()):
		var puff := smoke[i]
		var origin: Vector3 = puff.get_meta("origin")
		var t := fmod(elapsed * 0.7 + i * 1.4, 20.0)
		puff.position = origin + Vector3(sin(t * 0.5) * t * 0.17, t + 5, cos(t * 0.8) * t * 0.1)
		puff.scale = Vector3.ONE * (1 + t * 0.23)
	for resource in resources.values():
		if is_instance_valid(resource):
			resource.rotation.y += _delta * 0.22

func _update_air(delta: float) -> void:
	if home_distance() < 22.0:
		air = minf(MAX_AIR, air + delta * 35.0)
		if progress.cargo > 0:
			var amount := progress.deposit()
			hud.toast("Home again. %d fragments stored. Your village is saved." % amount)
			_save()
	else:
		var old := air
		air = maxf(0.0, air - delta)
		if old > 75 and air <= 75:
			hud.toast("Life support at 25%. Follow the home bearing to refill.")
		if air <= 0:
			recall_home()

func home_distance() -> float:
	return camera.position.distance_to(HOME)

func home_direction() -> String:
	var direction := (HOME - camera.position).normalized()
	var relative := camera.basis.inverse() * direction
	if relative.z > 0.25:
		return "BEHIND YOU"
	if relative.x > 0.35:
		return "TURN RIGHT"
	if relative.x < -0.35:
		return "TURN LEFT"
	return "AHEAD"

func _refresh_chunks(immediate: bool = false) -> void:
	var center := generator.chunk_at(camera.position)
	if center == last_chunk and not immediate:
		return
	last_chunk = center
	chunk_queue.clear()
	var wanted: Array[Vector2i] = []
	for x in range(center.x - VIEW_RADIUS, center.x + VIEW_RADIUS + 1):
		for z in range(center.y - VIEW_RADIUS, center.y + VIEW_RADIUS + 1):
			wanted.append(Vector2i(x, z))
	for chunk in chunks.keys():
		if not wanted.has(chunk):
			var node: Node3D = chunks[chunk]
			for item in node.get_children():
				if item.has_meta("resource_id"):
					resources.erase(item.get_meta("resource_id"))
			node.queue_free()
			chunks.erase(chunk)
	wanted.sort_custom(func(a: Vector2i, b: Vector2i): return (a - center).length_squared() < (b - center).length_squared())
	for chunk in wanted:
		if not chunks.has(chunk):
			if immediate:
				_create_chunk(chunk)
			else:
				chunk_queue.append(chunk)

func _create_chunk(chunk: Vector2i) -> void:
	var root := Node3D.new()
	add_child(root)
	chunks[chunk] = root
	var terrain := MeshInstance3D.new()
	terrain.mesh = generator.mesh_for(chunk)
	terrain.material_override = seabed_material
	root.add_child(terrain)
	var rng := generator.rng_for(chunk)
	var stone: Material = garden.rock_material
	for i in range(9):
		var x := (chunk.x + rng.randf()) * generator.CHUNK_SIZE
		var z := (chunk.y + rng.randf()) * generator.CHUNK_SIZE
		if Vector2(x, z).length() < 17:
			continue
		var at := Vector3(x, generator.height_at(x, z), z)
		var size := rng.randf_range(1.0, 4.2)
		var rock := Forms.sphere(root, at, Vector3(size * 2, size, size * 1.4), stone)
		rock.mesh = VentGarden.crag_mesh(i % 4)
		rock.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
	var positions := generator.resource_positions(chunk)
	for i in range(positions.size()):
		_spawn_resource(root, generator.resource_id(chunk, i), positions[i])

func _spawn_resource(parent: Node3D, id: String, point: Vector3) -> void:
	if progress.collected.has(id):
		return
	var node := Node3D.new()
	node.position = point
	node.set_meta("resource_id", id)
	parent.add_child(node)
	var mineral := Forms.material(Color("9c9a7b"), 0.03, 0.1)
	node.scale = Vector3.ONE * 0.45
	var mesh := Forms.cylinder(node, Vector3.ZERO, 0.55, 1.5, mineral, 0.0)
	mesh.rotation.z = 0.2
	Forms.cylinder(node, Vector3(0.45, -0.3, 0.1), 0.3, 0.9, mineral, 0.0).rotation.z = -0.5
	resources[id] = node

func _setup_intro_resources() -> void:
	for i in range(8):
		var x := -12.0 + i * 3.0
		var z := -20.0 - sin(i * 0.8) * 6.0
		_spawn_resource(self, "intro:%d" % i, Vector3(x, generator.height_at(x, z) + 1.0, z))

func _pick_target() -> void:
	target = null
	var nearest := 16.0
	for animal in animals:
		var distance := camera.position.distance_to(animal.position)
		if distance < nearest and not progress.discovered.has(animal.record.id):
			nearest = distance
			target = {"kind": "creature", "node": animal, "distance": distance}
	for id in resources.keys():
		var node: Node3D = resources[id]
		if not is_instance_valid(node):
			continue
		var distance := camera.position.distance_to(node.position)
		if distance < 7.0 and distance < nearest:
			nearest = distance
			target = {"kind": "resource", "node": node, "id": id, "distance": distance}
	if garden.specimen != null:
		var distance := camera.position.distance_to(garden.specimen.position + Vector3(0, 2, 0))
		if distance < 12 and (target == null or distance < nearest):
			target = {"kind": "specimen", "node": garden.specimen, "distance": distance}

func interaction_prompt() -> String:
	if target != null:
		if target.kind == "specimen":
			return "RIFTIA COLONY  ·  %d m\nExamine the organism and its bacterial partnership" % roundi(target.distance)
		if target.kind == "creature":
			return "LIFE DETECTED  ·  %d m\nScan %s" % [roundi(target.distance), target.node.record.name]
		return "MINERAL FRAGMENT  ·  %d m\nCollect and bring it home" % roundi(target.distance)
	if home_distance() < 22:
		return "PELAGIC STATION\nLife support refilling · cargo deposited automatically"
	return "Investigate the crimson plumes. Examine the life that thrives here."

func interact() -> void:
	if hud.modal:
		return
	_pick_target()
	if target == null:
		hud.toast("Move closer: 16 m to scan an animal, 7 m to collect a fragment.")
		return
	if target.kind == "creature":
		if progress.scan(target.node.record.id):
			hud.toast("Documented: %s. Read its story in your field journal." % target.node.record.name)
	elif target.kind == "specimen":
		hud.show_specimen()
		return
	else:
		if progress.collect(target.id):
			var node: Node3D = target.node
			resources.erase(target.id)
			node.queue_free()
			hud.toast("Fragment collected · %d / 20 carried" % progress.cargo)
		else:
			hud.toast("Cargo full. Return to Pelagic Station to deposit your fragments.")
	_save()
	_pick_target()

func build_home() -> void:
	if hud.modal:
		return
	if home_distance() >= 22:
		hud.toast("Return within 22 m of Pelagic Station to expand your village.")
		return
	progress.deposit()
	if progress.build_module():
		_add_capsule(progress.modules - 1)
		hud.toast("A new capsule lights up the deep. Village expanded!")
		_save()
	else:
		hud.toast("Village complete for this prototype." if progress.modules >= progress.MAX_MODULES else "Gather %d stored fragments for the next capsule." % progress.build_cost())

func recall_home() -> void:
	progress.cargo = floori(progress.cargo * 0.5)
	camera.position = SPAWN
	velocity = Vector3.ZERO
	yaw = 0
	pitch = -0.12
	view_yaw = yaw
	view_pitch = pitch
	view_roll = 0
	air = MAX_AIR
	_refresh_chunks()
	_save()
	hud.toast("Rescue complete. Half your cargo was lost; your journal is safe.")

func _save() -> void:
	if not progress.save_game():
		hud.toast("Saving is unavailable. Progress will last for this session only.")

func clear_touch_controls() -> void:
	touch_controls.reset()
	var held := touch_buttons.values()
	touch_buttons.clear()
	for button in held:
		if is_instance_valid(button):
			_release_touch_button(button)
	if is_instance_valid(hud) and is_instance_valid(hud.pad):
		hud.pad.reset()
		hud.vertical = 0

func _update_touch_vertical() -> void:
	var vertical := 0.0
	for button in touch_buttons.values():
		if is_instance_valid(button) and not button.disabled:
			vertical += float(button.get_meta("swim_vertical", 0.0))
	hud.vertical = clampf(vertical, -1.0, 1.0)

func _press_touch_button(button: Button) -> void:
	# BaseButton only exposes a persistent pressed visual in toggle mode.
	# Touch capture owns the lifetime; restore the normal button mode on release.
	button.set_meta("native_original_toggle", button.toggle_mode)
	button.toggle_mode = true
	button.set_pressed_no_signal(true)
	button.button_down.emit()

func _release_touch_button(button: Button) -> void:
	if button.has_meta("native_original_toggle"):
		button.set_pressed_no_signal(false)
		button.toggle_mode = bool(button.get_meta("native_original_toggle"))
		button.remove_meta("native_original_toggle")
	button.button_up.emit()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(hud) or hud.modal:
		return
	# Standard Controls use one emulated mouse; gameplay touch is routed per finger.
	# Modal menus and the specimen viewer keep their existing GUI input path.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var button: Button = hud.touch_button_at(event.position)
			if button != null:
				if touch_buttons.values().has(button):
					get_viewport().set_input_as_handled()
					return
				touch_buttons[event.index] = button
				if not button.disabled:
					_press_touch_button(button)
				_update_touch_vertical()
				get_viewport().set_input_as_handled()
				return
			var width: float = hud.root.size.x
			var height: float = hud.root.size.y
			var look_area := Rect2(Vector2(width * 0.30, 0), Vector2(width * 0.70, height))
			var role: String = touch_controls.press(event.index, event.position, hud.pad.get_global_rect(), look_area)
			if role == "move":
				hud.pad.begin_touch(event.index, event.position)
			if role != "":
				get_viewport().set_input_as_handled()
		else:
			if touch_buttons.has(event.index):
				var button: Button = touch_buttons[event.index]
				touch_buttons.erase(event.index)
				if is_instance_valid(button):
					_release_touch_button(button)
					_update_touch_vertical()
					if not event.canceled and not button.disabled and button.get_global_rect().has_point(event.position):
						button.pressed.emit()
				get_viewport().set_input_as_handled()
				return
			var role: String = touch_controls.release(event.index)
			if role == "move":
				hud.pad.reset()
			if role != "":
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if touch_buttons.has(event.index):
			get_viewport().set_input_as_handled()
			return
		var routed: Dictionary = touch_controls.drag(event.index, event.position)
		if routed.is_empty():
			return
		if routed.role == "move":
			hud.pad.drag_touch(event.position)
		else:
			_rotate_view(routed.delta * 0.004)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_J:
			if hud.modal:
				hud.close_modal()
			else:
				hud.show_journal()
		if event.physical_keycode == KEY_ESCAPE:
			if hud.modal:
				hud.close_modal()
			else:
				hud.show_welcome()
		if not hud.modal:
			match event.physical_keycode:
				KEY_E: interact()
				KEY_B: build_home()
				KEY_H: hud.show_recall()
	if hud.modal:
		return
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and touch_controls.positions.is_empty() and touch_buttons.is_empty() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_rotate_view(event.relative * 0.003)

func _rotate_view(delta: Vector2) -> void:
	yaw -= delta.x
	pitch = clampf(pitch - delta.y, -1.35, 1.35)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		progress.save_game()
		get_tree().quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
		progress.save_game()
		clear_touch_controls()
