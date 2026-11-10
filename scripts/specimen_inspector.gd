extends HBoxContainer
## Real 3D inspection in its own lit world. The illustration is not a specimen scan.
signal closed

const Garden = preload("res://scripts/vent_garden.gd")
var pivot: Node3D
var view_camera: Camera3D
var viewport: SubViewport
var stage: SubViewportContainer
var title_label: Label
var detail: Label
var scale_label: Label
var angle := 0.45
var elevation := 0.0
var distance := 5.5
var focus := Vector3.ZERO
var current_feature := "whole"
var touch_positions: Dictionary = {}
var last_pinch := 0.0
var reviewed: Array[String] = []
var turned_by_user := false
var auto_rotate := false
var record: Dictionary

func _ready() -> void:
	record = JSON.parse_string(FileAccess.get_file_as_string("res://data/specimens.json")).riftia
	add_theme_constant_override("separation", 24)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.9
	add_child(left)
	var header := Label.new()
	header.text = "SPECIMEN 01    /    RIFTIA PACHYPTILA"
	header.add_theme_color_override("font_color", Color("8fd2c9"))
	header.add_theme_font_size_override("font_size", 14)
	left.add_child(header)
	stage = SubViewportContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.stretch = true
	stage.custom_minimum_size = Vector2(380, 400)
	stage.gui_input.connect(_orbit_input)
	left.add_child(stage)
	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 700)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	stage.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("04121c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c2d2d3")
	env.ambient_light_energy = 0.4
	var environment := WorldEnvironment.new()
	environment.environment = env
	world.add_child(environment)
	pivot = Node3D.new()
	world.add_child(pivot)
	var model := Garden.make_specimen()
	model.position.y = -1.5
	pivot.add_child(model)
	view_camera = Camera3D.new()
	view_camera.fov = 37
	view_camera.near = 0.02
	world.add_child(view_camera)
	_light(world, Vector3(2.5, 2.5, 4), Color("fff0dc"), 2.5)
	_light(world, Vector3(-3, 1.3, 1), Color("72b6de"), 1.0)
	_light(world, Vector3(0, 2, -2), Color("9bd5ec"), 2.0)
	scale_label = Label.new()
	scale_label.text = "Drag to orbit  ·  Pinch or scroll to zoom  ·  Illustrative proportions"
	scale_label.add_theme_font_size_override("font_size", 13)
	scale_label.add_theme_color_override("font_color", Color("75969e"))
	scale_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(scale_label)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 340
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(side)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	scroll.add_child(right)
	title_label = Label.new()
	title_label.text = "Life without\nsunlight."
	title_label.add_theme_font_size_override("font_size", 36)
	right.add_child(title_label)
	var scientific := Label.new()
	scientific.text = "GIANT TUBEWORM\nRiftia pachyptila"
	scientific.add_theme_color_override("font_color", Color("c78985"))
	right.add_child(scientific)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("font_size", 18)
	right.add_child(detail)
	var part_buttons := HBoxContainer.new()
	right.add_child(part_buttons)
	for feature in ["plume", "tube", "symbiosis"]:
		var id: String = feature
		part_buttons.add_child(_button(feature.capitalize(), func(): show_feature(id)))
	var zoom := HBoxContainer.new()
	right.add_child(zoom)
	zoom.add_child(_button("− Zoom", func(): distance = minf(9.0, distance * 1.25)))
	zoom.add_child(_button("+ Zoom", func(): distance = maxf(0.65, distance / 1.25)))
	zoom.add_child(_button("Reset", func(): show_feature("whole")))
	var provenance := Label.new()
	provenance.text = "Anatomical illustration\nFine structure is interpretive, not microscopy."
	provenance.add_theme_font_size_override("font_size", 12)
	provenance.add_theme_color_override("font_color", Color("81969b"))
	provenance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(provenance)
	right.add_child(_button("SCIENTIFIC REFERENCE", func(): OS.shell_open(record.source)))
	side.add_child(_button("BACK TO THE VENT GARDEN", func(): closed.emit()))
	show_feature("whole")

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("143039")
	normal.set_corner_radius_all(5)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", normal)
	var active := normal.duplicate()
	active.bg_color = Color("2c565d")
	button.add_theme_stylebox_override("hover", active)
	button.add_theme_stylebox_override("pressed", active)
	button.pressed.connect(action)
	return button

func _light(world: Node3D, at: Vector3, color: Color, power: float) -> void:
	var node := OmniLight3D.new()
	node.position = at
	node.light_color = color
	node.light_energy = power
	node.omni_range = 12
	world.add_child(node)

func show_feature(id: String) -> void:
	current_feature = id
	if not reviewed.has(id):
		reviewed.append(id)
	match id:
		"plume":
			focus = Vector3(0.15, 1.25, 0)
			distance = 1.35
		"tube":
			focus = Vector3(0.1, -0.1, 0)
			distance = 3.2
		"symbiosis":
			focus = Vector3.ZERO
			distance = 5.5
		_:
			focus = Vector3.ZERO
			distance = 5.5
	detail.text = record.get(id, record.whole)

func _process(delta: float) -> void:
	if auto_rotate:
		angle += delta * 0.12
	var direction := Vector3(sin(angle) * cos(elevation), sin(elevation), cos(angle) * cos(elevation))
	view_camera.position = focus + direction * distance
	view_camera.look_at(focus)

func _orbit_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_orbit(event.relative)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(0.65, distance * 0.88)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(9, distance / 0.88)
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_positions[event.index] = event.position
		else:
			touch_positions.erase(event.index)
		last_pinch = 0
	if event is InputEventScreenDrag:
		touch_positions[event.index] = event.position
		if touch_positions.size() == 1:
			_orbit(event.relative)
		elif touch_positions.size() >= 2:
			var values := touch_positions.values()
			var current: float = values[0].distance_to(values[1])
			if last_pinch > 0 and current > 0:
				distance = clampf(distance * last_pinch / current, 0.65, 9.0)
			last_pinch = current
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion:
		stage.accept_event()

func _orbit(delta: Vector2) -> void:
	turned_by_user = true
	angle += delta.x * 0.008
	elevation = clampf(elevation + delta.y * 0.006, -0.65, 0.65)
