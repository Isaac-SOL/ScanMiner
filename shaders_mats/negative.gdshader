shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture;
uniform sampler2D shadow;
uniform sampler2D noise: repeat_enable;
uniform vec2 emitter_position = vec2(0.5);
uniform float screen_edge = 0.4;
uniform float noise_strength = 1.0;

const vec2 pixel_size = vec2(1.0 / 320.0, 1.0 / 180.0);

vec3 sigmoid(vec3 x) {
	return ((1.0 / (1.0 + exp(-x))) - 0.5) * 2.0;
}

void fragment() {
	float n1 = (texture(noise, SCREEN_UV + vec2(TIME, 0)).r - 0.5) * 2.0;
	
	vec2 emitter_vec = SCREEN_UV - emitter_position;
	float emitter_dist = length(emitter_vec);
	float norm_dist = emitter_dist / screen_edge;
	norm_dist += (norm_dist + 0.1) * n1 * noise_strength * 0.05;
	vec3 color_dist = norm_dist * vec3(0.99, 1.0, 1.01);
	vec3 new_dist = sigmoid(color_dist) * 2.0 * screen_edge;
	
	vec2 eff_uv_r = emitter_position + normalize(emitter_vec) * new_dist.r;
	vec2 eff_uv_g = emitter_position + normalize(emitter_vec) * new_dist.g;
	vec2 eff_uv_b = emitter_position + normalize(emitter_vec) * new_dist.b;
	
	vec4 scr_r = texture(screen, eff_uv_r);
	vec4 scr_g = texture(screen, eff_uv_g);
	vec4 scr_b = texture(screen, eff_uv_b);
	
	COLOR.rgb = 1.0 - vec3(scr_r.r, scr_g.g, scr_b.b);
}
