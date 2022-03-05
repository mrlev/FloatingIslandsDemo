shader_type spatial;
render_mode unshaded, cull_disabled;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

bool colorMatch(vec3 c1, vec3 c2, float maxDiff) {
    return (
        abs(c1.r - c2.r) < maxDiff
        || abs(c1.b - c2.b) < maxDiff
        || abs(c1.b - c2.b) < maxDiff
    );
}

void fragment() {
	vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 1));
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	float px = 0.5/screen_size.x;
	float py = 0.5/screen_size.y;
	float d = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	float du = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(0.0, py)).x;
	float dd = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(0.0, -py)).x;
	float dr = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(px, 0.0)).x;
	float dl = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(-px, 0.0)).x;	
	float dq = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(-px, py)).x;
	float de = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(px, py)).x;
	float dz = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(-px, -py)).x;
	float dc = texture(DEPTH_TEXTURE, SCREEN_UV+vec2(px, -py)).x;
		
	float amount = abs(abs(abs(d)-abs(du)) - abs(abs(d)-abs(dd))) + abs(abs(abs(d)-abs(dl)) - abs(abs(d)-abs(dr))) + abs(abs(abs(d)-abs(dq)) - abs(abs(d)-abs(dc))) + abs(abs(abs(d)-abs(dz)) - abs(abs(d)-abs(de)));
	if (amount > 0.000001)
	{
		amount = 0.1;
	}
	ALBEDO = screen_color.xyz - (screen_color.xyz * amount);
}
