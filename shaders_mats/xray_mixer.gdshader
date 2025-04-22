shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture;
uniform sampler2D shadow;
uniform sampler2D noise: repeat_enable;
uniform float strength = 2.0;
uniform vec2 emitter_position = vec2(0.5);
uniform float mult_at_edge = 1.0;
uniform float screen_edge = 0.4;

const vec2 pixel_size = vec2(1.0 / 320.0, 1.0 / 180.0);

void fragment() {
	float n1 = texture(noise, SCREEN_UV + vec2(TIME, 0)).r;
	float n2 = texture(noise, (SCREEN_UV + vec2(0, TIME)).yx).r;
	float s = texture(shadow, SCREEN_UV).r;
	float norm_dist = length(SCREEN_UV - emitter_position) / screen_edge;
	float m = norm_dist * norm_dist * norm_dist * (mult_at_edge - 1.0) + 1.0;
	float factor = mix(5.0, 2.0, s);
	vec2 nvec = (vec2(n1, n2) - vec2(0.5)) * pixel_size * factor * m * strength;
	vec2 eff_uv = SCREEN_UV + nvec;
	
	float emitter_dist = length(eff_uv - emitter_position);
	if (emitter_dist > screen_edge) {
		eff_uv = mix(eff_uv, emitter_position, (emitter_dist - 0.5) / emitter_dist);
	}
	
	vec4 scr = texture(screen, eff_uv);
	scr = (scr + texture(screen, eff_uv)) / 2.0;
	
	float val = 0.299 * scr.r + 0.587 * scr.g + 0.114 * scr.b;
	val = 1.0 / (1.0 + exp(-(6.0*val) + 3.0));
	val = (val + 1.0) / 2.0;
	
	COLOR.rgb = vec3(val);
}
