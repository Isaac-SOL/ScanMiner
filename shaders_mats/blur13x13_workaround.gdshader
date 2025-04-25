shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture;

const vec2 pixel_size = vec2(1.0 / 320.0, 1.0 / 180.0) * 5.5;

void fragment() {
	vec2 vert = vec2(pixel_size.x, 0);
	vec2 hori = vec2(0, pixel_size.y);
	
	bool in_light = false;
	in_light = in_light || texture(screen, SCREEN_UV).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV + vert).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV - vert).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV + hori).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV - hori).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV + vert + hori).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV - vert + hori).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV + vert - hori).r > 0.25;
	in_light = in_light || texture(screen, SCREEN_UV - vert - hori).r > 0.25;
	
	COLOR = vec4(1.0) * (in_light ? 1.0 : 0.0);
}
