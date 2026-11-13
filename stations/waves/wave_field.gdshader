shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Surface height and color both come from the same two-source superposition.
uniform vec2 field_cm = vec2(40.0, 28.0);
uniform vec2 s1_cm = vec2(6.0, 8.0);
uniform vec2 s2_cm = vec2(6.0, 20.0);
uniform float k = 3.14;
uniform float omega = 37.7;
uniform float t = 0.0;
uniform float two = 1.0;

varying float wave_value;
varying float nodal_envelope;

void vertex() {
	vec2 p = UV * field_cm;
	float r1 = distance(p, s1_cm);
	float r2 = distance(p, s2_cm);
	float first = cos(k * r1 - omega * t);
	float second = two * cos(k * r2 - omega * t);
	wave_value = first + second;
	nodal_envelope = mix(1.0, abs(cos(0.5 * k * (r2 - r1))), two);
	VERTEX.y += 0.045 * wave_value / (1.0 + two);
}

void fragment() {
	float normalized_height = wave_value / (1.0 + two);
	float crest = pow(max(normalized_height, 0.0), 1.55);
	float trough = pow(max(-normalized_height, 0.0), 1.55);
	float nodes = (1.0 - smoothstep(0.035, 0.16, nodal_envelope)) * two;
	vec3 base = vec3(0.045, 0.14, 0.20);
	vec3 teal = vec3(0.09, 0.72, 0.69);
	vec3 amber = vec3(0.98, 0.58, 0.22);
	vec3 node_line = vec3(0.74, 0.92, 0.92);
	ALBEDO = base + teal * crest * 0.92 + amber * trough * 0.68 + node_line * nodes * 0.16;
	EMISSION = teal * crest * 0.38 + amber * trough * 0.3 + node_line * nodes * 0.045;
	METALLIC = 0.06;
	ROUGHNESS = 0.32;
}
