shader_type spatial;
render_mode cull_disabled;
uniform vec4 tissue_color : source_color = vec4(0.65, 0.55, 0.4, 1.0);
uniform float plume = 0.0;
varying vec3 local_point;

void vertex() {
    local_point = VERTEX;
    float tip = smoothstep(2.4, 3.1, VERTEX.y) * plume;
    VERTEX.x += sin(TIME * 0.7 + VERTEX.y * 10.0) * 0.012 * tip;
    VERTEX.z += cos(TIME * 0.53 + VERTEX.y * 8.0) * 0.009 * tip;
}

void fragment() {
    float grain = fract(sin(dot(floor(local_point * 650.0), vec3(12.989, 78.233, 42.41))) * 43758.54);
    float rings = sin(local_point.y * 240.0 + sin(local_point.x * 18.0) * 0.4);
    float stain = 0.82 + 0.18 * smoothstep(0.0, 2.3, local_point.y);
    ALBEDO = tissue_color.rgb * stain * (0.90 + grain * 0.13 + rings * 0.025 * (1.0 - plume));
    ROUGHNESS = mix(0.49, 0.34, plume) + grain * 0.1;
    SPECULAR = 0.38;
    RIM = 0.3 * plume;
    RIM_TINT = 0.5;
}
