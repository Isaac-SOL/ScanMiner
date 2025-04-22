shader_type canvas_item;

uniform bool vertical;
uniform sampler2D screen: hint_screen_texture;

const vec2 pixel_size = vec2(1.0 / 320.0, 1.0 / 180.0);

void fragment() {
	vec2 pixel_offset = vertical ? vec2(pixel_size.x, 0) : vec2(0, pixel_size.y);
	vec4 color = vec4(0.0);
	vec2 off1 = pixel_offset * 1.411764705882353;
	vec2 off2 = pixel_offset * 3.2941176470588234;
	vec2 off3 = pixel_offset * 5.176470588235294;
	
	vec4 this_color = texture(screen, SCREEN_UV);
	if (this_color.r > 0.5) {
		COLOR = vec4(1.0, 1.0, 1.0, 1.0);
	} else {
		color += this_color * 0.1964825501511404;
		color += texture(screen, SCREEN_UV + off1) * 0.2969069646728344;
		color += texture(screen, SCREEN_UV - off1) * 0.2969069646728344;
		color += texture(screen, SCREEN_UV + off2) * 0.09447039785044732;
		color += texture(screen, SCREEN_UV - off2) * 0.09447039785044732;
		color += texture(screen, SCREEN_UV + off3) * 0.010381362401148057;
		color += texture(screen, SCREEN_UV - off3) * 0.010381362401148057;
		COLOR = sqrt(sqrt(color));
	}
	
}
