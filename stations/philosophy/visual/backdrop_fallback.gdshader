shader_type canvas_item;
// Arka plan görseli yokken kullanılan yedek zemin: gece gözlemevi paleti, sol üstte tek amber ışık.

uniform vec4 base_color : source_color = vec4(0.027, 0.043, 0.071, 1.0);
uniform vec4 lamp_color : source_color = vec4(0.949, 0.651, 0.353, 1.0);
uniform vec2 lamp_pos = vec2(0.18, 0.30);
uniform float lamp_strength = 0.34;
uniform float floor_line = 0.82;

void fragment() {
	vec2 uv = UV;
	vec3 sky = mix(vec3(0.060, 0.095, 0.150), base_color.rgb, uv.y);
	float d = distance(uv * vec2(1.78, 1.0), lamp_pos * vec2(1.78, 1.0));
	float glow = exp(-d * 3.4) * lamp_strength;
	vec3 col = sky + lamp_color.rgb * glow;
	// zemin: karanlık, ışığı yansıtan şerit
	float f = smoothstep(floor_line - 0.01, floor_line + 0.02, uv.y);
	vec3 floor_col = mix(vec3(0.045, 0.060, 0.082), vec3(0.020, 0.028, 0.040), (uv.y - floor_line) * 5.0);
	floor_col += lamp_color.rgb * exp(-d * 4.6) * 0.10;
	col = mix(col, floor_col, f);
	COLOR = vec4(col, 1.0);
}
