/*
	アニメ水面シェーダー by あるる（きのもと 結衣）
	Anime Water Surface Shader by @arlez80

	MIT License
*/

shader_type spatial;
render_mode specular_phong;

uniform vec2 speed = vec2( 1.0, 1.0 );
uniform float voronoi_scale = 18.0;
uniform float noise_scale = 0.21;
uniform vec4 color : hint_color = vec4( 0.01, 0.5866666666666666, 1.0, 1.0 );
uniform vec4 light_color : hint_color = vec4( 1.0, 1.0, 1.0, 1.0 );
uniform sampler2D normalmap : hint_normal; //add Godot noise here, enable as_normalmap

vec2 random( vec2 pos )
{ 
	return fract(
		sin(
			vec2(
				dot(pos, vec2(12.9898,78.233))
			,	dot(pos, vec2(-148.998,-65.233))
			)
		) * 43758.5453
	);
}

float value_noise( vec2 pos )
{
	vec2 p = floor( pos );
	vec2 f = fract( pos );

	float v00 = random( p + vec2( 0.0, 0.0 ) ).x;
	float v10 = random( p + vec2( 1.0, 0.0 ) ).x;
	float v01 = random( p + vec2( 0.0, 1.0 ) ).x;
	float v11 = random( p + vec2( 1.0, 1.0 ) ).x;

	vec2 u = f * f * ( 3.0 - 2.0 * f );

	return mix( mix( v00, v10, u.x ), mix( v01, v11, u.x ), u.y );
}

float voronoi( vec2 v )
{
	vec2 v_floor = floor( v );
	vec2 v_fract = fract( v );

	float min_dist = 2.0;

	for( int y = -1; y <= 1; y ++ ) {
		for( int x = -1; x <= 1; x ++ ) {
			vec2 n = vec2( float( x ), float( y ) );
			vec2 p = random( v_floor + n );
			vec2 diff = p + n;
			float d = distance( v_fract, diff );

			min_dist = min( min_dist, d );
		}
	}

	return min_dist;
}

void fragment( )
{
	vec2 uv = UV2;
	vec2 noise_uv = UV2 + speed * TIME * 0.1;

	uv.x += (
		value_noise( noise_uv * 5.45432 ) * 0.5
	+	value_noise( noise_uv * 15.754824 ) * 0.25
	+	value_noise( noise_uv * 35.4274729 ) * 0.125
	+	value_noise( noise_uv * 95.65347829 ) * 0.0625
	+	value_noise( noise_uv * 285.528934 ) * 0.03125
	+	value_noise( noise_uv * 585.495328 ) * 0.015625
	+	value_noise( noise_uv * 880.553426553 ) * 0.0078125
	+	value_noise( noise_uv * 2080.5483905843 ) * 0.00390625
	) * noise_scale;

	vec2 v1 = uv * voronoi_scale + vec2( 100.0 + TIME ) * speed;
	vec2 v2 = uv * voronoi_scale + vec2( -100.0 + TIME * 0.83 ) * speed;

	float f = mix(
		voronoi( v1 ) * 1.1
	,	voronoi( v2 ) * 1.1
	,	sin( TIME * 0.758 ) * 0.5 + 0.5
	);

	NORMAL_MAP = texture(normalmap, noise_uv).rgb;
	ROUGHNESS = 0.1;
	SPECULAR = 1.0;
	ALBEDO = mix( light_color, color, clamp( 1.0 - f * f * f, 0.0, 1.0 ) ).rgb;
}
