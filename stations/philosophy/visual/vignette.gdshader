shader_type canvas_item;
// Sahne kenar kararması. anger arttıkça kenarlar kırmızıya döner, repaired arttıkça yeşil-camgöbeği ışık gelir.

uniform float vignette : hint_range(0.0, 1.0) = 0.6;
uniform float anger : hint_range(0.0, 1.0) = 0.0;
uniform float repaired : hint_range(0.0, 1.0) = 0.0;
uniform vec4 anger_color : source_color = vec4(0.898, 0.392, 0.353, 1.0);
uniform vec4 repair_color : source_color = vec4(0.435, 0.890, 0.757, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 1.15;
	float d = clamp(length(p) * 1.45, 0.0, 1.0);
	float edge = smoothstep(0.45, 1.0, d);
	float t = max(anger, repaired * (1.0 - anger));
	vec3 tint = mix(repair_color.rgb, anger_color.rgb, anger);
	vec3 col = mix(vec3(0.0), tint, t * 0.85);
	float alpha = edge * mix(vignette, 0.5, t);
	COLOR = vec4(col, clamp(alpha, 0.0, 0.8));
}
