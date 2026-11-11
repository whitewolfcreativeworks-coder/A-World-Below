extends CanvasLayer

const TouchPad = preload("res://scripts/touch_pad.gd")
const LifeSonar = preload("res://scripts/life_sonar.gd")
const Inspector = preload("res://scripts/specimen_inspector.gd")
const INK := Color("c9e5e1")
const MINT := Color("82ddc4")
var game: Node3D
var root: Control
var depth_label: Label
var home_label: Label
var oxygen: ProgressBar
var oxygen_label: Label
var cargo_label: Label
var objective_label: Label
var prompt_label: Label
var toast_label: Label
var interact_button: Button
var build_button: Button
var sound_button: Button
var sway_button: Button
var pad: Control
var overlay: PanelContainer
var overlay_content: VBoxContainer
var modal := true
var vertical := 0.0
var toast_time := 0.0
var last_prompt := ""
var music_buttons: Array[Button] = []
var music_panel: VBoxContainer
var sonar: Control
var specimen_view: Control

func _init(owner_game: Node3D = null) -> void:
	game = owner_game

func _ready() -> void:
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func(): root.size = get_viewport().get_visible_rect().size)
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	root.theme = theme
	var status := VBoxContainer.new()
	_place(status, Vector2(30, 26), Vector2(320, 200))
	status.add_child(_label("A  W O R L D  B E L O W", 16, MINT))
	depth_label = _label("1,400 m", 30)
	status.add_child(depth_label)
	status.add_child(_label("VENT GARDEN  /  RESEARCH EXPEDITION", 12, Color("78a3a7")))
	home_label = _label("", 15)
	status.add_child(home_label)
	sonar = LifeSonar.new()
	sonar.game = game
	sonar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(sonar, Vector2(30, 160), Vector2(180, 205))
	music_panel = VBoxContainer.new()
	_place(music_panel, Vector2(30, 365), Vector2(178, 230))
	music_panel.add_theme_constant_override("separation", 3)
	music_panel.add_child(_label("SOUNDTRACK", 12, MINT))
	for i in range(game.MUSIC_NAMES.size()):
		var index: int = i
		var button := _button(game.MUSIC_NAMES[i], func(): game.select_music(index))
		button.custom_minimum_size.y = 32
		button.add_theme_stylebox_override("normal", _style(Color(0.025,0.12,0.15,0.9), 4))
		for style_name in ["normal", "hover", "pressed"]:
			var style := button.get_theme_stylebox(style_name).duplicate()
			style.content_margin_top = 7
			style.content_margin_bottom = 7
			button.add_theme_stylebox_override(style_name,style)
		music_buttons.append(button)
		music_panel.add_child(button)
	var volume := HBoxContainer.new()
	music_panel.add_child(volume)
	volume.add_child(_button("VOL −", func(): game.set_music_volume(game.music_volume-0.15); refresh_music()))
	volume.add_child(_button("VOL +", func(): game.set_music_volume(game.music_volume+0.15); refresh_music()))
	music_panel.add_child(_button("LIFE CATALOG", show_catalog))
	for button in music_panel.find_children("*", "Button", true, false):
		button.custom_minimum_size.y = 32
		for style_name in ["normal", "hover", "pressed"]:
			var compact_style: StyleBoxFlat = button.get_theme_stylebox(style_name).duplicate()
			compact_style.content_margin_top = 6
			compact_style.content_margin_bottom = 6
			button.add_theme_stylebox_override(style_name,compact_style)
	refresh_music()
	var right := VBoxContainer.new()
	_place(right, Vector2(-340, 26), Vector2(310, 150), Control.PRESET_TOP_RIGHT)
	var actions := HBoxContainer.new()
	right.add_child(actions)
	actions.add_child(_button("JOURNAL [J]", show_journal))
	sound_button = _button("SOUND OFF", func(): game.toggle_audio())
	actions.add_child(sound_button)
	sway_button = _button("SWAY ON" if game.sway_enabled else "SWAY OFF", func(): game.toggle_sway())
	actions.add_child(sway_button)
	right.add_child(_button("SPECIMEN 01 · EXAMINE IN 3D", show_specimen))
	oxygen_label = _label("LIFE SUPPORT  ·  100%", 14)
	right.add_child(oxygen_label)
	oxygen = ProgressBar.new()
	oxygen.custom_minimum_size = Vector2(300, 5)
	oxygen.show_percentage = false
	oxygen.add_theme_stylebox_override("background", _style(Color("14343f"), 3))
	oxygen.add_theme_stylebox_override("fill", _style(MINT, 3))
	right.add_child(oxygen)
	cargo_label = _label("", 15)
	right.add_child(cargo_label)
	objective_label = _label("", 15, Color("b0c5ba"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(objective_label)
	var reticle := _label("·", 34, Color(0.6, 0.9, 0.85, 0.65))
	_place(reticle, Vector2(-5, -20), Vector2(12, 40), Control.PRESET_CENTER)
	prompt_label = _label("", 19)
	_place(prompt_label, Vector2(-280, -190), Vector2(560, 60), Control.PRESET_CENTER_BOTTOM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label = _label("", 19, MINT)
	_place(toast_label, Vector2(-270, 178), Vector2(540, 65), Control.PRESET_CENTER_TOP)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pad = TouchPad.new()
	_place(pad, Vector2(30, -185), Vector2(150, 150), Control.PRESET_BOTTOM_LEFT)
	var swim := _label("SWIM", 12, Color("7ca3a6"))
	_place(swim, Vector2(85, -36), Vector2(90, 22), Control.PRESET_BOTTOM_LEFT)
	var controls := VBoxContainer.new()
	_place(controls, Vector2(-220, -252), Vector2(190, 226), Control.PRESET_BOTTOM_RIGHT)
	var height_buttons := HBoxContainer.new()
	controls.add_child(height_buttons)
	var up := _button("RISE", func(): pass)
	up.set_meta("swim_vertical", 1.0)
	up.button_down.connect(func(): vertical = 1.0)
	up.button_up.connect(func(): vertical = 0.0)
	height_buttons.add_child(up)
	var down := _button("DIVE", func(): pass)
	down.set_meta("swim_vertical", -1.0)
	down.button_down.connect(func(): vertical = -1.0)
	down.button_up.connect(func(): vertical = 0.0)
	height_buttons.add_child(down)
	interact_button = _button("SCAN / COLLECT  [E]", func(): game.interact())
	controls.add_child(interact_button)
	build_button = _button("EXPAND HOME  [B]", func(): game.build_home())
	controls.add_child(build_button)
	controls.add_child(_button("RETURN HOME  [H]", show_recall))
	var hint := _label("WASD swim  ·  drag to look  ·  Space / C rise / dive  ·  Shift cruise", 13, Color("7caaae"))
	_place(hint, Vector2(-320, -32), Vector2(640, 25), Control.PRESET_CENTER_BOTTOM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	show_welcome()

func _place(node: Control, at: Vector2, dimensions: Vector2, preset: int = Control.PRESET_TOP_LEFT) -> void:
	root.add_child(node)
	node.set_anchors_and_offsets_preset(preset)
	node.offset_left = at.x
	node.offset_top = at.y
	node.offset_right = at.x + dimensions.x
	node.offset_bottom = at.y + dimensions.y

func _label(text: String, font_size: int = 18, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style(color: Color, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.12, 0.15, 0.90)))
	button.add_theme_stylebox_override("hover", _style(Color("23505a")))
	button.add_theme_stylebox_override("pressed", _style(Color("36736f")))
	button.pressed.connect(callback)
	return button

func _open_modal() -> void:
	modal = true
	game.clear_touch_controls()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(overlay):
		overlay.free()
	overlay = PanelContainer.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.005, 0.035, 0.055, 0.94), 0))
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 42)
	overlay.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	overlay_content = VBoxContainer.new()
	overlay_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_content.add_theme_constant_override("separation", 14)
	scroll.add_child(overlay_content)

func touch_button_at(point: Vector2) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node.is_visible_in_tree() and node.get_global_rect().has_point(point):
			return node
	return null

func _paragraph(text: String, color: Color = INK) -> void:
	var label := _label(text, 19, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_content.add_child(label)

func show_welcome() -> void:
	_open_modal()
	overlay.add_theme_stylebox_override("panel", _style(Color(0.005, 0.025, 0.04, 0.72), 0))
	overlay_content.add_child(_label("STUDY 04  /  SIGNALS OF LIFE", 14, MINT))
	overlay_content.add_child(_label("A World Below", 58))
	_paragraph("Life at the edge of the impossible.")
	_paragraph("Descend into a compact hydrothermal habitat. Examine a giant tubeworm in full 3D and discover the bacterial partnership that sustains it.")
	_paragraph("DISCOVER  /  EXAMINE  /  UNDERSTAND  /  INVENT", MINT)
	_paragraph("Follow green life contacts on the compass sonar; the gold square marks home. Choose a soundtrack on the left. Ambient sound begins when you enter.\nFeel the current and coast between strokes. Watch suspended particles drift past.\niPad: left pad to swim, drag to look, RISE / DIVE for depth. SWAY OFF reduces camera motion.\nIn the specimen viewer: rotate, zoom, and compare the optional holographic SCAN LAYER.")
	overlay_content.add_child(_button("ENTER THE VENT GARDEN", close_modal))
	overlay_content.add_child(_button("EXAMINE THE TUBEWORM · FULL 3D", show_specimen))
	overlay_content.add_child(_button("TOOLS & CREDITS", show_credits))
	_paragraph("Visual benchmark · original anatomical illustration · research-led fiction.\nThe existing village loop remains available; research-based technology progression is the next design direction.", Color("7fa5ab"))

func show_specimen() -> void:
	_open_modal()
	game.set_inspection_mode(true)
	overlay.add_theme_stylebox_override("panel", _style(Color("040e16"), 0))
	var scroll: Node = overlay_content.get_parent()
	var margin: Node = scroll.get_parent()
	scroll.queue_free()
	var inspector := Inspector.new()
	specimen_view = inspector
	margin.add_child(inspector)
	inspector.closed.connect(close_modal)

func close_modal() -> void:
	game.set_inspection_mode(false)
	if is_instance_valid(overlay):
		overlay.hide()
		overlay.queue_free()
	modal = false
	game.start_expedition()

func show_journal() -> void:
	_open_modal()
	overlay_content.add_child(_label("FIELD JOURNAL", 38))
	_paragraph("%d / %d inhabitants documented. Approach an animal within 16 m and choose SCAN. Observation leaves the animal undisturbed." % [game.progress.discovered.size(), game.records.size()], MINT)
	for record in game.records:
		if not game.progress.discovered.has(record.id):
			_paragraph("UNIDENTIFIED SIGNAL  /  Explore the water and seafloor.", Color("6b8c94"))
			continue
		overlay_content.add_child(_label(record.name + "  /  " + record.scientific, 24, MINT))
		_paragraph(record.habitat)
		_paragraph(record.fact)
		_paragraph(record.observe, Color("95b6bd"))
		var source: String = record.source
		overlay_content.add_child(_button("OPEN SCIENTIFIC REFERENCE ↗", func(): OS.shell_open(source)))
	overlay_content.add_child(_button("BACK TO THE OCEAN", close_modal))

func show_credits() -> void:
	_open_modal()
	overlay_content.add_child(_label("BUILT WITH OPEN SOURCE", 36))
	_paragraph("Godot Engine 4.6.3 · MIT license\nFastNoiseLite · MIT license · included with Godot\nBlender 4.3.2 · GPL production tool")
	_paragraph("Original models, interface graphics, and synthesized audio. Bare-rock material maps: Poly Haven, CC0. Research references: NOAA Ocean Exploration and MBARI. These organizations do not endorse this game.")
	_paragraph("Animal colors, scale, abundance, and coexistence are artistic simplifications. Capsule habitats and mineral gathering are fictional gameplay. A CC BY 4.0 scientific micrograph is included in LIFE CATALOG with attribution. Microscopy colors are not natural visible glow.")
	overlay_content.add_child(_button("GODOT LICENSE & THIRD-PARTY NOTICES ↗", func(): OS.shell_open("https://godotengine.org/license/")))
	overlay_content.add_child(_button("BACK TO THE OCEAN", close_modal))

func show_recall() -> void:
	_open_modal()
	overlay_content.add_child(_label("RETURN TO PELAGIC", 38))
	_paragraph("Emergency recall brings you home with your journal intact. Half your carried fragments are lost. Swimming back lets you keep everything.")
	overlay_content.add_child(_button("RECALL TO HOME", func(): game.recall_home(); close_modal()))
	overlay_content.add_child(_button("KEEP EXPLORING", close_modal))

func toast(text: String) -> void:
	toast_label.text = text
	toast_time = 5.0

func update_status(delta: float) -> void:
	depth_label.text = "%s m" % str(roundi(1400.0 - game.camera.position.y))
	var distance: float = game.home_distance()
	home_label.text = "HOME  %d m  ·  %s" % [roundi(distance), "SAFE HARBOR" if distance < 22 else game.home_direction()]
	oxygen.value = game.air / game.MAX_AIR * 100.0
	oxygen_label.text = "LIFE SUPPORT  ·  %d%%" % roundi(oxygen.value)
	if oxygen.value < 25:
		oxygen_label.modulate = Color("ffb180")
	else:
		oxygen_label.modulate = Color.WHITE
	cargo_label.text = "FRAGMENTS  %d / 20     STORED  %d" % [game.progress.cargo, game.progress.bank]
	if game.progress.modules >= game.progress.MAX_MODULES:
		objective_label.text = "Village complete for this prototype. Keep exploring."
	else:
		objective_label.text = "Next capsule: %d fragments · Village %d / %d" % [game.progress.build_cost(), game.progress.modules + 1, game.progress.MAX_MODULES + 1]
	if distance >= 22:
		objective_label.text = "RESEARCH FOCUS\nVent symbiosis · examine Specimen 01"
	build_button.disabled = distance >= 22 or game.progress.bank < game.progress.build_cost() or game.progress.modules >= game.progress.MAX_MODULES
	var prompt: String = game.interaction_prompt()
	prompt_label.text = prompt
	interact_button.disabled = game.target == null
	if game.target != null:
		if game.target.kind == "specimen":
			interact_button.text = "EXAMINE RIFTIA  [E]"
		else:
			interact_button.text = "SCAN ANIMAL  [E]" if game.target.kind == "creature" else "COLLECT FRAGMENT  [E]"
	else:
		interact_button.text = "SCAN / COLLECT  [E]"
	toast_time = maxf(0.0, toast_time - delta)
	toast_label.visible = toast_time > 0 and not modal

func refresh_music() -> void:
	for i in range(music_buttons.size()):
		music_buttons[i].text = ("> " if i == game.music_index else "") + game.MUSIC_NAMES[i]

func show_catalog() -> void:
	_open_modal()
	overlay_content.add_child(_label("ATLAS OF DEEP LIFE", 36, MINT))
	_paragraph("A growing research catalog, from midwater animals to microbial life. Listed candidates are not all implemented. Habitat and adaptation groups overlap; depth alone does not make an organism a thermophile.")
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/life_catalog.json"))
	for group in catalog:
		overlay_content.add_child(_label(group.title, 25, MINT))
		_paragraph(group.description)
		for entry in group.entries:
			_paragraph("%s  ·  %s\n%s" % [entry.name,entry.status,entry.note], Color("a6bec0"))
			var url: String = entry.source
			overlay_content.add_child(_button("SCIENTIFIC REFERENCE ↗",func(): OS.shell_open(url)))
	overlay_content.add_child(_label("REAL MICROSCOPY · VENT CHIMNEY SAMPLES", 24, MINT))
	var image := TextureRect.new()
	image.texture = load("res://assets/science/vent_microbes.webp")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(0,420)
	overlay_content.add_child(image)
	_paragraph("Confocal microscopy from Old City hydrothermal chimney samples. Imaging colors are not natural visible bioluminescence. Shapes alone do not identify species. This is a scientific observation, not a 3D skin.")
	_paragraph("Aurélien Lecoeuvre, Bénédicte Ménez, Mathilde Cannat, Valérie Chavagnac & Emmanuelle Gérard (2020). CC BY 4.0. Image unchanged; scaled for display.", Color("8cabad"))
	overlay_content.add_child(_button("IMAGE LICENSE · CC BY 4.0 ↗",func(): OS.shell_open("https://creativecommons.org/licenses/by/4.0/")))
	overlay_content.add_child(_button("MICROSCOPY PAPER ↗",func(): OS.shell_open("https://www.nature.com/articles/s41396-020-00816-7")))
	overlay_content.add_child(_button("BACK TO THE OCEAN",close_modal))
