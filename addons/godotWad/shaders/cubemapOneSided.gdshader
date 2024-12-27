shader_type spatial;
render_mode blend_mix, unshaded;

uniform vec4 emission : source_color;
uniform sampler2D texture_emission : hint_default_black;
uniform float emission_energy : hint_range(0,16) = 1.0;
uniform samplerCube cube_map : source_color,filter_nearest;


void fragment(){
	vec3 dir = (INV_VIEW_MATRIX * vec4(normalize(VERTEX), 0.0)).xyz;
	ALBEDO = texture(cube_map, dir).rgb;

	vec2 base_uv = UV;
	vec3 emission_tex = texture(texture_emission,base_uv).rgb;
	EMISSION = (emission.rgb + emission_tex) * emission_energy;
}