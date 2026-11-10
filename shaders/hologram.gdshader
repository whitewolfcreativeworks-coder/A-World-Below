shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec4 scan_color : source_color = vec4(0.13, 0.75, 0.92, 1.0);
uniform float shell_offset = 0.0015;
uniform float plume = 0.0;
varying vec3 sample_point;

void vertex() {
    sample_point = VERTEX;
    // Keep the scan shell aligned with the animated respiratory plume.
    float tip = smoothstep(2.4, 3.1, VERTEX.y) * plume;
    VERTEX.x += sin(TIME * 0.7 + VERTEX.y * 10.0) * 0.012 * tip;
    VERTEX.z += cos(TIME * 0.53 + VERTEX.y * 8.0) * 0.009 * tip;
    VERTEX += NORMAL * shell_offset;
}

void fragment() {
    float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);
    float contours = pow(0.5 + 0.5 * sin(sample_point.y * 175.0), 18.0);
    float sweep = pow(0.5 + 0.5 * sin(sample_point.y * 4.0 - TIME * 0.9), 16.0);
    float cells = pow(0.5 + 0.5 * sin(sample_point.x * 180.0), 28.0) * 0.13;
    ALBEDO = scan_color.rgb * (0.55 + sweep * 0.45);
    ALPHA = clamp(rim * 0.25 + contours * 0.12 + sweep * 0.08 + cells, 0.0, 0.42);
}
