shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform sampler2D texture_albedo : source_color,filter_nearest,repeat_enable;


uniform vec3 sectorLight : source_color = vec3(1,1,1);
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
	vec4 albedo_tex = texture(texture_albedo,base_uv);


	ALPHA_SCISSOR_THRESHOLD = 1.0;
	ALBEDO = albedo_tex.rgb;//* tint.rgb;
	ALPHA *= alpha * albedo_tex.a ;
	EMISSION =  sectorLight * ALBEDO * emission_energy;


}
