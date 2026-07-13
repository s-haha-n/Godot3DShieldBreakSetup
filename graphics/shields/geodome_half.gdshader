shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform float tumble : hint_range(0.0, 20.0) = 6.0;
uniform float expand : hint_range(0.0, 5.0) = 0.0;
uniform float fade_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;
uniform float fresnel_noise_amount : hint_range(0.0, 10.0) = 4.0;
uniform vec4 shield_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);

varying float v_seed;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

mat3 get_rotation_matrix(vec3 u, float rot) {
	float c = cos(rot);
	float s = sin(rot);
	float t = 1.0 - c;
	return mat3(
		vec3(u.x * u.x * t + c, u.x * u.y * t - u.z * s, u.x * u.z * t + u.y * s),
		vec3(u.x * u.y * t + u.z * s, u.y * u.y * t + c, u.y * u.z * t - u.x * s),
		vec3(u.x * u.z * t - u.y * s, u.y * u.z * t + u.x * s, u.z * u.z * t + c)
	);
}

void vertex() {
	float seed = COLOR.r;
	v_seed = seed;

	vec3 pivot = NORMAL * dot(VERTEX, NORMAL);
	vec3 local = VERTEX - pivot;

	local = get_rotation_matrix(vec3(0.0, 1.0, 0.0), TIME * tumble * (0.4 + seed)) * local;

	VERTEX = pivot + local + NORMAL * expand * (0.5 + seed);
}

void fragment() {
	float flicker = hash11(v_seed * 91.7 + floor(TIME * 18.0));
	float noisy_power = fresnel_power + flicker * fresnel_noise_amount * fade_amount;
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), noisy_power);
	ALBEDO = shield_color.rgb;
	ALPHA = fresnel * (1.0 - fade_amount);
}