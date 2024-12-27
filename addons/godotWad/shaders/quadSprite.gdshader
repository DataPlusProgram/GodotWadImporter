// NOTE: Shader automatically converted from Godot Engine 4.2.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,alpha_to_coverage_and_one;
//uniform vec4 albedo : source_color = vec4(1.0,1.0,1.0,1.0);
uniform sampler2D texture_albedo : source_color,filter_nearest,repeat_enable;
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float alpha_scissor_threshold = 0.145;
uniform float alpha_antialiasing_edge;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_nearest,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_nearest,repeat_enable;
uniform float specular;
uniform float metallic;
uniform vec3 uv1_scale = vec3(1.0,1.0,1.0);
uniform vec3 uv1_offset;
uniform vec3 uv2_scale = vec3(1.0,1.0,1.0);
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}






void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb * tint.rgb;
	//float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	//METALLIC = metallic_tex * metallic;
	//vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	//float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	//ROUGHNESS = roughness_tex * roughness;
	//SPECULAR = specular;
	ALPHA *= albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	ALPHA_ANTIALIASING_EDGE = alpha_antialiasing_edge;
	//ALPHA_TEXTURE_COORDINATE = UV * vec2(albedo_texture_size);

}
