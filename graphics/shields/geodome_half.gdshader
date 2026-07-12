shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform float shatter_progress : hint_range(0.0, 1.5) = 0.0;
uniform float explode_dist : hint_range(0.0, 5.0) = 1.4;
uniform float fade_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;
uniform float fresnel_noise_amount : hint_range(0.0, 10.0) = 4.0;
uniform vec4 shield_color : source_color;

varying float v_seed;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void vertex() {
	v_seed = COLOR.r;
	VERTEX += NORMAL * shatter_progress * explode_dist * (0.5 + v_seed);
}

void fragment() {
	// Is there a way to add individualized flicker to each mesh piece?
	float flicker = hash11(v_seed * 91.7 + floor(TIME * 18.0));
	float noisy_power = fresnel_power + flicker * fresnel_noise_amount * fade_amount;
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), noisy_power);
	ALBEDO = shield_color.rgb;
	ALPHA = fresnel * (1.0 - fade_amount);
}