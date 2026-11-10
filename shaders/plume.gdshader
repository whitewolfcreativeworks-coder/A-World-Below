shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D turbulence : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(0.08, 0.12, 0.15, 0.36);

void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float n = texture(turbulence, UV * 1.8 + vec2(TIME * 0.014, -TIME * 0.02)).r;
    float shape = 1.0 - smoothstep(0.2, 1.0, length(p) + (n - 0.5) * 0.5);
    ALBEDO = tint.rgb;
    ALPHA = shape * tint.a * COLOR.a;
}
