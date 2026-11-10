shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying float distance_to_eye;
varying float beam;

void vertex() {
    vec3 view_point = (VIEW_MATRIX * MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    distance_to_eye = length(view_point);
    beam = pow(max(-view_point.z / max(distance_to_eye, 0.01), 0.0), 8.0);
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX *= mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
    float dot_shape = 1.0 - smoothstep(0.05, 0.5, length(UV - 0.5));
    float fade = smoothstep(0.3, 1.0, distance_to_eye) * (1.0 - smoothstep(12.0, 22.0, distance_to_eye));
    ALBEDO = vec3(0.48, 0.72, 0.77) * (0.4 + beam * 0.6);
    ALPHA = dot_shape * fade * (0.15 + beam * 0.65) * COLOR.a;
}
