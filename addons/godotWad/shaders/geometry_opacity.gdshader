shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx,depth_prepass_alpha;
uniform sampler2D texture_albedo : source_color,filter_linear,repeat_enable;

//uniform sampler2D color_map : hint_albedo;
uniform vec4 tint : source_color = vec4(1,1,1,1);
uniform float alpha  = 1.0;
uniform vec2 scrolling = vec2(0,0);
uniform vec4 emission : source_color;
uniform sampler2D texture_emission : hint_default_black;
uniform float emission_energy : hint_range(0,16) = 1.0;

void vertex() {

	if (scrolling.x != 0.0)
		UV.x += -scrolling.x*TIME*0.15;

	if (scrolling.y != 0.0)
		UV.y += scrolling.y*TIME*0.15;

}

void fragment()
{
	vec2 base_uv = UV;
	vec2 texelCords;


	vec4 albedo_tex = texture(texture_albedo,base_uv);
	int index = int(albedo_tex.r*255.0);


	//vec4 pix = texelFetch(color_map, ivec2(index, 0),0);

	//ALPHA_SCISSOR_THRESHOLD = 0.4;
	ALBEDO = albedo_tex.rgb* tint.rgb;
	ALPHA = alpha * albedo_tex.a;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb + emission_tex) * emission_energy;


}