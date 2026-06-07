shader_type canvas_item;

void fragment() {
	vec3 top = vec3(0.015, 0.025, 0.12);
	vec3 bot = vec3(0.01, 0.01, 0.04);
	COLOR.rgb = mix(top, bot, UV.y);
	COLOR.a = 1.0;
}
