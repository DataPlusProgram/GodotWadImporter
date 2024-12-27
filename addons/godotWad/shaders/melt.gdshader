shader_type canvas_item;

//Incremented by outside script to move effect
uniform float timer = 0.0;

//Array size determines how many vertical strips appear
uniform float[256] y_offsets;

//Texture to melt away, example above uses a duplicate screen texture as a transition
uniform sampler2D melt_tex;

//Controls whether the effect can play
uniform bool melting = false;

void fragment() {
	vec2 tex_uv = SCREEN_UV;
	if (melting)
	{
		float index = tex_uv.x * float(y_offsets.length());
		tex_uv.y -= timer * y_offsets[int(index)];

		if (tex_uv.y < 0.0 || tex_uv.y > 1.0) discard;
	}

	COLOR = texture(melt_tex, tex_uv);
}