shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.72);
uniform float inner_radius = 0.22;
uniform float outer_radius = 0.82;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv * vec2(1.15, 1.0));
	float alpha = smoothstep(inner_radius, outer_radius, distance_from_center) * vignette_color.a;
	COLOR = vec4(vignette_color.rgb, alpha);
}
