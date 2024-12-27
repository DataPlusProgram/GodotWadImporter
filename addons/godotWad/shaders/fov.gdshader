// NOTE: Shader automatically converted from Godot Engine 3.6.beta2's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx,unshaded;
uniform vec4 albedo : source_color = vec4(1.0,1.0,1.0,1.0);
uniform sampler2D texture_albedo : source_color,filter_nearest,repeat_disable;
uniform float specular;
uniform float metallic;
uniform float alpha_scissor_threshold = 1.0;
uniform float roughness : hint_range(0,1);
uniform vec2 pixelSize = vec2(1.0,1.0);
uniform vec2 offset = vec2(0.0,0.0);
uniform vec3 uv1_scale = vec3(1.0,1.0,1.0);
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform float fov : hint_range(20,120) = 90;

float mapValue(float x, float in_min, float in_max, float out_min, float out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


void vertex() {
    // Adjust UV coordinates based on scale and offset
    UV = UV * uv1_scale.xy + uv1_offset.xy;

    // Calculate the oneTanFov and aspect ratio
    float oneTanFov = 1.0 / tan(fov * 0.5 * 3.141592 / 180.0);
    float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

    // Scale the vertex positions

	float textureWidth = float(textureSize(texture_albedo, 0).x);
	float textureHeight = float(textureSize(texture_albedo, 0).y);

    VERTEX.x *= textureWidth * pixelSize.x * 0.01 * 1.0;
    VERTEX.y *= textureHeight * pixelSize.y * 0.01 * 1.0;

    // Calculate the height of the sprite
    float sprite_height = textureHeight * pixelSize.y * 0.01;
	float sprite_width = textureWidth * pixelSize.x * 0.01;

    // Shift vertices up by half the sprite's height to align the top with the center of the screen
    VERTEX.y -= sprite_height / 2.0;
	VERTEX.x += sprite_width / 2.0;
	//y=0.109; //top of screen
	//y=-0.109; bottom of screen
	//note in these case it's relative postion (+/-) not absolute (=)
	//mapping [0,168] to [0,resolution.y] is too big

	float top = 0.03;
	float bottom = -0.109;//constant


	float mapped_value = mapValue(offset.y,-168.0,0.0,bottom,top);//cant use viewport range because its two streched compared to the orignal doom range, small changes in y will send the sprite a good distance up the screen

	VERTEX.y += mapped_value;

	//float left = -0.196;
	//float right = 0.196;

	float left = -0.125;
	float right = -left;

	float mapped_valueX = mapValue(-offset.x,0.0,320.0,left,right);

	//VERTEX.x +=left;
	VERTEX.x += mapped_valueX;

	VERTEX.y = -VERTEX.y;
    PROJECTION_MATRIX[1][1] = oneTanFov;
    PROJECTION_MATRIX[0][0] = oneTanFov / aspect;

    POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0);
    //POSITION.z = mix(POSITION.z, 0.0, -0.999);
}




void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD=alpha_scissor_threshold;//this fixes invis box
}
