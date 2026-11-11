extends SceneTree
const Sonar = preload("res://scripts/life_sonar.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(Sonar.project_contact(Vector3(0,0,-55),0).is_equal_approx(Vector2(0,-0.5)),"North contact must be ahead when facing north")
	check(Sonar.project_contact(Vector3(55,0,0),-PI/2).is_equal_approx(Vector2(0,-0.5)),"East contact must be ahead when facing east")
	check(Sonar.project_contact(Vector3(0,0,-55),-PI/2).is_equal_approx(Vector2(-0.5,0)),"North must move left when facing east")
	check(Sonar.heading_degrees(-TAU-PI/2)==90,"Compass heading must wrap")
	var game: Node3D = load("res://scenes/ocean.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(not game.audio_enabled,"Audio must wait for user gesture")
	game.hud.close_modal()
	await process_frame
	check(game.audio_enabled and game.audio.playing,"Entering ocean must start ambient audio")
	check(game.habitat.colony_positions.size()>15,"Habitat must contain multiple coral colonies")
	var branch: Transform3D = game.habitat.batches.coral.transforms[1]
	check(absf(branch.basis.y.normalized().x)>0.4,"Coral branches must spread sideways rather than collapse into vertical rods")
	check(game.habitat.schools.multimesh.instance_count==48,"Small moving life must be present")
	check(game.life_contacts().size()>game.animals.size(),"Sonar must include benthic colonies and specimen")
	game.habitat.paused = false
	var original: Vector3 = game.habitat.swarm_positions[0]
	game.habitat._process(1)
	check(not game.habitat.swarm_positions[0].is_equal_approx(original),"Small life must move")
	game.habitat.paused=true
	original = game.habitat.swarm_positions[0]
	game.habitat._process(1)
	check(game.habitat.swarm_positions[0].is_equal_approx(original),"Modal pause must stop habitat animation")
	for i in range(4):
		await game.select_music(i)
		check(game.music_index==i and game.audio.stream.loop and game.audio.playing,"Every cue must be selectable and loop")
	game.set_music_volume(0)
	check(game.audio.volume_db<=-69,"Zero music volume must be effectively silent")
	game.toggle_audio()
	check(not game.audio.playing and not game.flow_audio.playing,"Mute must stop both sound layers")
	game.hud.show_music()
	await process_frame
	var scroll: ScrollContainer = game.hud.music_tracks
	var start: Vector2 = scroll.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.index = 9
	touch.position = start
	touch.pressed = true
	root.push_input(touch,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 9
	drag.position = start-Vector2(0,100)
	root.push_input(drag,true)
	touch.position = drag.position
	touch.pressed = false
	root.push_input(touch,true)
	await process_frame
	check(scroll.scroll_vertical>0 and game.music_index==3,"A native swipe must scroll without selecting a different track")
	var button: Button = game.hud.music_buttons[3]
	touch.position = button.get_global_rect().get_center()
	touch.pressed = true
	root.push_input(touch,true)
	touch.pressed = false
	root.push_input(touch,true)
	await create_timer(0.4).timeout
	check(game.music_index==3 and game.audio_enabled,"A tap on a revealed track must select it and enable audio")
	game.hud.close_modal()
	await process_frame
	check(not game.hud.modal and not is_instance_valid(game.hud.music_panel),"Closing Music must dismiss the card and resume gameplay")
	game.hud.show_catalog()
	await process_frame
	check(game.hud.modal and game.hud.overlay_content.find_children("*","TextureRect",true,false).size()==1,"Catalog must display real microscopy")
	check(game.hud.music_button.get_global_rect().end.y < game.hud.pad.get_global_rect().position.y,"Compact music button must not cover joystick")
	game.hud.close_modal()
	game.free()
	print("Living ocean checks: %d passed / %d" % [checks-failures,checks])
	quit(1 if failures else 0)
