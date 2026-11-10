extends CanvasLayer

const TouchPad = preload("res://scripts/touch_pad.gd")
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
var pad: Control
var overlay: PanelContainer
var overlay_content: VBoxContainer
var modal := true
var vertical := 0.0
var toast_time := 0.0
var last_prompt := ""

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
	depth_label = _label("1,400 m", 40)
	status.add_child(depth_label)
	status.add_child(_label("BATHYPELAGIC  /  PELAGIC STATION", 12, Color("78a3a7")))
	home_label = _label("", 15)
	status.add_child(home_label)
	var right := VBoxContainer.new()
	_place(right, Vector2(-340, 26), Vector2(310, 150), Control.PRESET_TOP_RIGHT)
	var actions := HBoxContainer.new()
	right.add_child(actions)
	actions.add_child(_button("FIELD JOURNAL  [J]", show_journal))
	sound_button = _button("SOUND OFF", func(): game.toggle_audio())
	actions.add_child(sound_button)
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
	up.button_down.connect(func(): vertical = 1.0)
	up.button_up.connect(func(): vertical = 0.0)
	height_buttons.add_child(up)
	var down := _button("DIVE", func(): pass)
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
	pad.reset()
	vertical = 0
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

func _paragraph(text: String, color: Color = INK) -> void:
	var label := _label(text, 19, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_content.add_child(label)

func show_welcome() -> void:
	_open_modal()
	overlay_content.add_child(_label("AN EXPEDITION INTO THE DEEP", 14, MINT))
	overlay_content.add_child(_label("A World Below", 58))
	_paragraph("Beyond the last sunlight, a small home glows.")
	_paragraph("Leave Pelagic Station. Follow the lights into a persistent, generated ocean. Observe its strange inhabitants, gather mineral fragments, and bring them home to grow your capsule village.")
	_paragraph("FIRST EXPEDITION\nScan an animal. Collect four fragments. Return within 22 m of the station to deposit them, then expand your home.", MINT)
	_paragraph("iPad: use the left swim pad, drag the open water to look, and hold RISE or DIVE.\nKeyboard: WASD to swim, drag to look, Space / C to rise / dive, E to interact.\nLife support refills near home. Your journal and village save on this device.")
	_paragraph("Early prototype · original stylized creatures · no accounts or paid services.\nThis first region is bathypelagic. Abyssal and hadal habitats are planned; the current ecosystem is a simplified fictional assemblage.", Color("7fa5ab"))
	overlay_content.add_child(_button("BEGIN EXPEDITION", close_modal))
	overlay_content.add_child(_button("TOOLS & CREDITS", show_credits))

func close_modal() -> void:
	if is_instance_valid(overlay):
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
	_paragraph("Godot Engine 4.6.3 · MIT license\nFastNoiseLite · MIT license · included with Godot\nBlender 4.3.2 · GPL production tool · available for the next art pass")
	_paragraph("All current models, interface graphics, and synthesized audio are original procedural work. Research references: NOAA Ocean Exploration and MBARI. These organizations do not endorse this game.")
	_paragraph("Animal colors, scale, abundance, and coexistence are artistic simplifications. Capsule habitats and mineral gathering are fictional gameplay. No licensed scientific footage is bundled.")
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
	build_button.disabled = distance >= 22 or game.progress.bank < game.progress.build_cost() or game.progress.modules >= game.progress.MAX_MODULES
	var prompt: String = game.interaction_prompt()
	prompt_label.text = prompt
	interact_button.disabled = game.target == null
	if game.target != null:
		interact_button.text = "SCAN ANIMAL  [E]" if game.target.kind == "creature" else "COLLECT FRAGMENT  [E]"
	else:
		interact_button.text = "SCAN / COLLECT  [E]"
	toast_time = maxf(0.0, toast_time - delta)
	toast_label.visible = toast_time > 0 and not modal
