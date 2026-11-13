shader_type sky;

float star_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float star_field(vec2 coordinates, float density, float frequency, float radius) {
	vec2 cell = floor(coordinates * density);
	vec2 offset = vec2(star_hash(cell), star_hash(cell + 17.0));
	vec2 position = 0.22 + offset * 0.56;
	float distance_to_star = length(fract(coordinates * density) - position);
	float core = 1.0 - smoothstep(radius * 0.22, radius, distance_to_star);
	return core * smoothstep(frequency, 1.0, star_hash(cell + 48.0));
}

void sky() {
	vec2 sky_position = vec2(atan(EYEDIR.x, -EYEDIR.z), asin(EYEDIR.y));
	float horizon = exp(-abs(EYEDIR.y + 0.05) * 3.4);
	float band = exp(-abs(dot(EYEDIR, normalize(vec3(-0.44, 0.87, -0.21)))) * 13.0);
	vec3 background = mix(vec3(0.008, 0.015, 0.034), vec3(0.045, 0.076, 0.128), horizon);
	background += band * vec3(0.021, 0.030, 0.052);
	float distant_stars = star_field(sky_position, 105.0, 0.60, 0.11);
	float nearby_stars = star_field(sky_position + 23.0, 52.0, 0.78, 0.075);
	COLOR = background + distant_stars * vec3(0.28, 0.40, 0.52) + nearby_stars * vec3(0.76, 0.79, 0.72);
}
