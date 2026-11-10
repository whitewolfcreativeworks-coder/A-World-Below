shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;
uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_map : hint_depth_texture, repeat_disable, filter_nearest;
uniform float motion_amount = 1.0;
uniform float thermal_amount = 0.0;
uniform float swim_speed = 0.0;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    float depth = texture(depth_map, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    float distance_m = min(length(view.xyz / view.w), 180.0);
    // Small optical disturbance near the vent mixing zone, not surface waves.
    vec2 ripple = vec2(sin(SCREEN_UV.y * 18.0 + TIME * 0.55), cos(SCREEN_UV.x * 15.0 + TIME * 0.43));
    vec2 offset = ripple * 0.0006 * thermal_amount * motion_amount * smoothstep(2.0, 12.0, distance_m);
    vec3 color = texture(screen, clamp(SCREEN_UV + offset, vec2(0.001), vec2(0.999))).rgb;
    vec3 transmission = exp(-vec3(0.014, 0.004, 0.002) * distance_m);
    color = mix(vec3(0.008, 0.035, 0.052), color, transmission);
    float vignette = 1.0 - smoothstep(0.25, 0.85, length((SCREEN_UV - 0.5) * vec2(1.1, 1.0))) * (0.30 + min(swim_speed / 10.0, 1.0) * 0.05);
    ALBEDO = color * vignette;
}
