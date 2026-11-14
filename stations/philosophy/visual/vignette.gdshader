shader_type canvas_item;

uniform float anger : hint_range(0.0, 1.0) = 0.0;
uniform float repaired : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 d = (uv - vec2(0.58, 0.46)) * vec2(1.15, 1.0);
	float r = length(d);
	float vig = smoothstep(0.48, 0.98, r);

	// Sol alt diyalog alanı için yumuşak sinematik okuma gölgesi
	float left_scrim = smoothstep(0.62, 0.08, uv.x) * smoothstep(0.32, 0.88, uv.y) * 0.52;

	// Sağ üstten filozofun üzerine düşen sıcak altın güneş huzmesi
	float sun_glow = exp(-length((uv - vec2(0.72, 0.24)) * vec2(1.2, 1.4)) * 2.4) * (0.14 + 0.12 * repaired);

	vec3 base_dark = vec3(0.045, 0.045, 0.042);
	vec3 anger_col = vec3(0.32, 0.06, 0.05);
	vec3 gold_col = vec3(0.96, 0.78, 0.46);

	vec3 edge_col = mix(base_dark, anger_col, anger * 0.65);
	float edge_a = clamp(vig * (0.38 + anger * 0.24) + left_scrim, 0.0, 0.76);

	vec3 final_rgb = mix(edge_col, gold_col, clamp(sun_glow * 1.6, 0.0, 0.45));
	COLOR = vec4(final_rgb, max(edge_a - sun_glow * 0.35, 0.0));
}
