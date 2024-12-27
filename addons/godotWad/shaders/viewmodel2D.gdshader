shader_type spatial;
render_mode blend_mix,unshaded;

uniform vec4 albedo : source_color = vec4(1,1,1,1);
uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap,repeat_disable;
uniform vec2 pixelSize = vec2(1.0,1.0);
uniform float fov  = 90.0;
void vertex() {
	//float oneTanFov = 1.0f / tan(0.5f *(fov* PI / 180.0f));
	float oneTanFov = 1.0f / tan(0.5f * radians(fov));
	float aspect = (VIEWPORT_SIZE.x / VIEWPORT_SIZE.y);
	VERTEX.y +=  (float(textureSize(texture_albedo,0).y)/2.0)*pixelSize.y;

	//PROJECTION_MATRIX[0][0] = oneTanFov / aspect;

	PROJECTION_MATRIX[1][1] = -oneTanFov;
	PROJECTION_MATRIX[0][0] = oneTanFov/aspect; //this keeps the aspect ratio from wapring

	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
    POSITION.z = mix(POSITION.z, 0, 0.9);
	//POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);

    PROJECTION_MATRIX[2][2] *= 0.1f; // Draw viewmodel over  everything
	ivec2 dim = textureSize(texture_albedo,0);

}

void fragment() {
	vec2 base_uv = UV;
	vec2 texelCords;


	vec4 albedo_tex = texture(texture_albedo,base_uv);

	ALPHA =  albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	//ec3 emission_tex = texture(texture_emission,base_uv).rgb;
	//EMISSION = (emission.rgb + emission_tex) * emission_energy;

}
