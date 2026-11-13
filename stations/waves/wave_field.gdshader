shader_type canvas_item;
// İki noktasal kaynağın girişim alanı. Tepe camgöbeği, çukur amber. Yıkıcı girişim çizgileri (düğüm) soluk beyaz.
uniform vec2 field_cm = vec2(40.0, 28.0);
uniform vec2 s1_cm = vec2(6.0, 8.0);
uniform vec2 s2_cm = vec2(6.0, 20.0);
uniform float k = 3.14;
uniform float omega = 37.7;
uniform float t = 0.0;
uniform float two = 1.0;

void fragment() {
	vec2 p = UV * field_cm;
	float r1 = distance(p, s1_cm);
	float r2 = distance(p, s2_cm);
	float u = cos(k * r1 - omega * t) + two * cos(k * r2 - omega * t);
	float a = u / (1.0 + two);
	float envelope = mix(1.0, abs(cos(0.5 * k * (r2 - r1))), two);
	vec3 col = vec3(0.025, 0.05, 0.085);
	col += vec3(0.10, 0.78, 0.72) * pow(max(a, 0.0), 1.6) * 1.15;
	col += vec3(0.96, 0.56, 0.20) * pow(max(-a, 0.0), 1.6) * 0.6;
	col += vec3(1.0) * smoothstep(0.10, 0.0, envelope) * 0.07 * two;
	COLOR = vec4(col, 1.0);
}
