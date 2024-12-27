shader_type spatial;
render_mode unshaded, depth_prepass_alpha, depth_draw_opaque;

uniform sampler2D S : source_color,filter_nearest,repeat_enable;
uniform sampler2D SW : source_color,filter_nearest,repeat_enable;
uniform sampler2D W : source_color,filter_nearest,repeat_enable;
uniform sampler2D NW : source_color,filter_nearest,repeat_enable;
uniform sampler2D N : source_color,filter_nearest,repeat_enable;
uniform sampler2D NE : source_color,filter_nearest,repeat_enable;
uniform sampler2D East : source_color,filter_nearest,repeat_enable;
uniform sampler2D SE : source_color,filter_nearest,repeat_enable;

varying vec3 forward;
uniform vec2 pixelSize = vec2(1.0,1.0);
uniform vec4 modulate  : source_color = vec4(1.0,1.0,1.0,1.0);

void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
    forward = MODEL_NORMAL_MATRIX * -NORMAL;
	vec3 objectPos = CAMERA_POSITION_WORLD;
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	vec3 cameraPos = (MODEL_MATRIX * vec4(0.0,0.0,0.0,1.0)).xyz;
	vec3 diff = normalize(vec3(cameraPos.x,0,cameraPos.z) - vec3(objectPos.x,0,objectPos.z));

	ivec2 dim;

	vec3 left = vec3(forward.z,0,-forward.x);
	float l_dot = dot(left,diff) ;
	float f_dot = dot(forward,diff);


	if (f_dot < -0.85)
		dim = textureSize(N,0);
	else if (f_dot > 0.85)
		dim = textureSize(S,0);
	else
		if (l_dot < 0.0)
			if (abs(f_dot) < 0.3)
				dim = textureSize(East, 0);
			else if (f_dot < 0.0)
				dim = textureSize(NE, 0);
			else
				dim = textureSize(SE, 0);
		else
			if (abs(f_dot) < 0.3)
				dim = textureSize(W, 0);
			else if (f_dot < 0.0)
				dim = textureSize(NW, 0);
			else
				dim = textureSize(SW, 0);


		VERTEX.x *= float(float(dim.x) * pixelSize.x);
		VERTEX.y *= float(float(dim.y) *  pixelSize.y);
		VERTEX.y += (float(dim.y)/2.0)*pixelSize.y;

}

void fragment() {
	vec3 objectPos = CAMERA_POSITION_WORLD;
	vec3 cameraPos = (MODEL_MATRIX * vec4(0.0,0.0,0.0,1.0)).xyz;
	vec3 diff = normalize(vec3(cameraPos.x,0,cameraPos.z) - vec3(objectPos.x,0,objectPos.z));

	vec4 tex;

	vec3 left = vec3(forward.z,0,-forward.x);

	float l_dot = dot(left,diff) ;
	float f_dot = dot(forward,diff);


	if (f_dot < -0.85)
		tex = texture(N,UV);
	else if (f_dot > 0.85)
		tex = texture(S,UV);
	else
		if (l_dot < 0.0)
			if (abs(f_dot) < 0.3)
				tex = texture(East, UV);
			else if (f_dot < 0.0)
				tex = texture(NE, UV);
			else
				tex = texture(SE, UV);
		else
			if (abs(f_dot) < 0.3)
				tex = texture(W, UV);
			else if (f_dot < 0.0)
				tex = texture(NW, UV);
			else
				tex = texture(SW, UV);

	ALBEDO = tex.rgb*modulate.rgb;
	ALPHA =  tex.a *modulate.a;
}