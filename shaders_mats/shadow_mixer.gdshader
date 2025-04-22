shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture;
uniform sampler2D shadow;

void fragment() {
	COLOR = vec4(texture(screen, SCREEN_UV).rgb * texture(shadow, SCREEN_UV).r, 1.0);
}
