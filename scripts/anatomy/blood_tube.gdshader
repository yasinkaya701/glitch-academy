shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always;
// Hortumun içinde akan kan: cam duvar, içeride debiyle ilerleyen yumuşak koyu ve açık kümeler.
// `phase` koddan, işaretli debinin integraliyle gelir: akış tersine dönünce desen de geri kayar.

uniform vec4 blood_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float phase = 0.0;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float cycles = 12.0;

void fragment() {
	float x = (UV.x - phase) * cycles;
	float clump = 0.5 + 0.3 * sin(x * 6.2831) + 0.2 * sin(x * 13.7 + 1.9);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	vec3 col = blood_color.rgb * mix(0.55, 0.55 + 0.6 * clump, amount);
	ALBEDO = col;
	ROUGHNESS = 0.12;
	SPECULAR = 0.9;
	EMISSION = col * (0.12 + 0.2 * amount);
	ALPHA = clamp(mix(0.34, 0.78, amount) + rim * 0.22, 0.0, 0.95);
}
