shader_type spatial;
render_mode blend_mix, specular_phong;

uniform float speed : hint_range(-1,1) = 0.0;

//colors
uniform sampler2D noise1; //add Godot noise here
uniform sampler2D noise2; //add Godot noise here
uniform sampler2D normalmap : hint_normal; //add Godot noise here, enable as_normalmap
uniform vec4 color : hint_color;
uniform vec4 edge_color : hint_color;
uniform float color_scale;

//foam
uniform float edge_scale = 0.25;
uniform float near = 0.1;
uniform float far = 100.0;



float rim(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}


void fragment(){
	float time = TIME * speed * 0.25;
	vec3 n1 = texture(noise1, UV2 + time).rgb * color_scale;
	vec3 n2 = texture(noise2, UV2 - time * 0.2).rgb * color_scale;
	
	vec2 uv_movement = UV2 * 8.0;
	uv_movement += TIME * speed;
	
	float sum = (n1.r + n2.r) - 1.0;
	
	
	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = rim(FRAGCOORD.z);
	float diff = z_depth - z_pos;
	
	vec2 displacement = vec2(sum * 0.05);
	diff += displacement.x * 50.0;
	
	
	vec4 col = mix(edge_color, color, step(edge_scale, diff));
	
	vec4 alpha = vec4(1.0);
	alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);
	
	
	float fin = 0.0;
	if (sum > 0.0 && sum < 0.4) fin = 0.1;
	if (sum > 0.4 && sum < 0.8) fin = 0.0;
	if (sum > 0.8) fin = 1.0;
	
	ALBEDO = vec3(fin) + mix(alpha.rgb, col.rgb, color.a);
//	ALBEDO = mix((n1.rgb + n2.rgb) * 0.5, col.rgb, color.a);
	
	NORMAL_MAP = texture(normalmap, uv_movement).rgb;
	ROUGHNESS = 0.1;
	SPECULAR = 1.0;
}