shader_type spatial;
render_mode blend_mix, unshaded,cull_disabled;

uniform samplerCube cube_map : source_color,filter_nearest;
uniform float emission_energy : hint_range(0,16) = 1.0;

void fragment(){
	vec3 dir = (INV_VIEW_MATRIX * vec4(normalize(VERTEX), 0.0)).xyz;
	ALBEDO = texture(cube_map, dir).rgb;
	EMISSION = vec3(1,1,1) * emission_energy;
}
