shader_type canvas_item;

uniform float screen_height = 620.0;
uniform float line_period = 4.0;
uniform float dim_alpha = 0.12;

void fragment() {
	float stripe = step(line_period - 1.0, mod(UV.y * screen_height, line_period));
	COLOR = vec4(0.0, 0.0, 0.0, stripe * dim_alpha);
}
