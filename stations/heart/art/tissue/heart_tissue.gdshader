shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap, repeat_enable;
uniform vec4 tissue_tint : source_color = vec4(0.98, 0.92, 0.89, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.30;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.34;
uniform float subsurface : hint_range(0.0, 1.0) = 0.24;
uniform float micro_ripple : hint_range(0.0, 0.1) = 0.018;

void fragment() {
	vec2 uv = UV;
	vec3 base = texture(albedo_map, uv).rgb * tissue_tint.rgb;
	// A restrained, broad vessel undertone adds depth without baking an anatomy pattern into the UV.
	float vessel_trace = sin((uv.x * 21.0 + sin(uv.y * 13.0) * 0.22) * 6.28318);
	float fine_trace = sin((uv.y * 67.0 + sin(uv.x * 31.0) * 0.16) * 6.28318);
	float vessel_mask = smoothstep(0.88, 0.98, vessel_trace) * 0.05;
	base = mix(base, base * vec3(0.70, 0.76, 0.88), vessel_mask);
	ALBEDO = base;

	vec3 sampled_normal = texture(normal_map, uv).rgb * 2.0 - 1.0;
	float ripple_x = cos(uv.y * 211.0 + sin(uv.x * 83.0)) * micro_ripple;
	float ripple_y = sin(uv.x * 197.0 + cos(uv.y * 71.0)) * micro_ripple;
	NORMAL_MAP = normalize(sampled_normal + vec3(ripple_x, ripple_y, 0.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength;

	float map_roughness = texture(roughness_map, uv).r;
	float surface_variation = 0.025 * fine_trace;
	ROUGHNESS = clamp(mix(map_roughness, 0.20, wetness) + surface_variation, 0.12, 0.78);
	METALLIC = 0.0;
	SPECULAR = mix(0.34, 0.58, wetness);
	SSS_STRENGTH = subsurface;
	BACKLIGHT = vec3(0.22, 0.065, 0.045) * subsurface;
}
