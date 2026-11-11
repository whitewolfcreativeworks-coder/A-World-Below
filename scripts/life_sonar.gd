extends Control
## A fictional short-range biological sensor. North is world -Z.
const RANGE := 110.0
var game: Node3D
var sweep := 0.0

static func project_contact(offset: Vector3, heading: float) -> Vector2:
	return Vector2(offset.x, offset.z).rotated(heading) / RANGE

static func heading_degrees(heading: float) -> int:
	return posmod(roundi(rad_to_deg(-heading)), 360)

func _process(delta: float) -> void:
	sweep = fmod(sweep + delta * 0.7, TAU)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var center := Vector2(85, 90)
	var radius := 65.0
	draw_circle(center, 76, Color(0.01, 0.07, 0.09, 0.93))
	for fraction in [0.5, 1.0]:
		draw_arc(center, radius * fraction, 0, TAU, 64, Color("275259"), 1.0, true)
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color("21434b"))
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color("21434b"))
	draw_line(center, center + Vector2(sin(sweep), -cos(sweep)) * radius, Color(0.4, 0.9, 0.8, 0.4), 2, true)
	var font := ThemeDB.fallback_font
	for cardinal in [["N", Vector2(0,-1)], ["E", Vector2(1,0)], ["S", Vector2(0,1)], ["W", Vector2(-1,0)]]:
		var p: Vector2 = cardinal[1].rotated(game.yaw) * 70
		draw_string(font, center + p + Vector2(-4,4), cardinal[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a1cfc9"))
	var count := 0
	var nearest := INF
	for contact in game.life_contacts():
		var offset: Vector3 = contact - game.camera.position
		if offset.length() > RANGE:
			continue
		var point := center + project_contact(offset, game.yaw) * radius
		draw_circle(point, 3.2, Color("82ddc4"))
		if absf(offset.y) > 5:
			var sign_y := -1.0 if offset.y > 0 else 1.0
			draw_line(point + Vector2(-2,sign_y*6), point + Vector2(0,sign_y*8), Color("82ddc4"), 1.0, true)
		count += 1
		nearest = minf(nearest, offset.length())
	var home := project_contact(game.HOME - game.camera.position, game.yaw).limit_length(0.95)
	draw_rect(Rect2(center + home * radius - Vector2(3,3), Vector2(6,6)), Color("edc28d"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-5),center+Vector2(-4,5),center+Vector2(4,5)]), Color.WHITE)
	draw_string(font, Vector2(12,13), "LIFE SONAR  %03d°" % heading_degrees(game.yaw), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c9e5e1"))
	var caption := "%d CONTACTS · %d m" % [count,roundi(nearest)] if count else "NO LIFE IN RANGE"
	draw_string(font, Vector2(4,179), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("82ddc4"))
	draw_string(font, Vector2(4,195), "110 m | HOME: gold square", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9cb9ba"))
