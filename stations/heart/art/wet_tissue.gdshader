shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap, repeat_enable;
uniform vec4 tissue_tint : source_color = vec4(0.96, 0.91, 0.89, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.22;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.28;

void fragment() {
	ALBEDO = texture(albedo_map, UV).rgb * tissue_tint.rgb;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = mix(texture(roughness_map, UV).r, 0.24, wetness);
	METALLIC = 0.0;
	SPECULAR = 0.58;
}
