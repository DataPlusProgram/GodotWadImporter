shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR.rgb = 1.0 - textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR.a = texture(TEXTURE , UV).a;
}