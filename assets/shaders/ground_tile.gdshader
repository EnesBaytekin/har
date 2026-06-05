shader_type spatial;

uniform sampler2D u_texture : source_color;
uniform float u_tile_size = 1.0;
uniform vec4 u_color = vec4(1.0);

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = world_pos.xz / u_tile_size;
	vec4 tex = texture(u_texture, uv);
	ALBEDO = tex.rgb * u_color.rgb;
}
