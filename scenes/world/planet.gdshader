shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 light_direction = vec3(-0.85, 0.44, 0.27);
uniform vec3 ocean_color : source_color = vec3(0.035, 0.13, 0.25);
uniform vec3 land_color : source_color = vec3(0.25, 0.41, 0.36);
uniform vec3 light_land_color : source_color = vec3(0.52, 0.54, 0.38);
uniform float relief : hint_range(0.0, 1.0) = 1.0;

varying vec3 sphere_position;
varying vec3 world_normal;

float hash_3d(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.73, 0.34));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float value_noise(vec3 position) {
	vec3 cell = floor(position);
	vec3 f = fract(position);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash_3d(cell), hash_3d(cell + vec3(1, 0, 0)), u.x),
			mix(hash_3d(cell + vec3(0, 1, 0)), hash_3d(cell + vec3(1, 1, 0)), u.x), u.y),
		mix(mix(hash_3d(cell + vec3(0, 0, 1)), hash_3d(cell + vec3(1, 0, 1)), u.x),
			mix(hash_3d(cell + vec3(0, 1, 1)), hash_3d(cell + vec3(1, 1, 1)), u.x), u.y), u.z
	);
}

float terrain(vec3 p) {
	float a = value_noise(p);
	float b = value_noise(p * 2.1 + 19.4);
	float c = value_noise(p * 4.4 + 45.1);
	float d = value_noise(p * 9.0 + 12.0);
	return 0.53 * a + 0.25 * b + 0.15 * c + 0.07 * d;
}

void vertex() {
	sphere_position = normalize(VERTEX);
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 p = normalize(sphere_position);
	vec3 direction = normalize(world_normal);
	vec3 sun = normalize(light_direction);
	float sun_dot = dot(direction, sun);
	float light_level = smoothstep(-0.20, 0.80, sun_dot);
	float continental_height = terrain(p * 4.1 + vec3(8.0, 1.1, 5.6));
	float coastline = smoothstep(0.49, 0.525, continental_height);
	float altitude = smoothstep(0.52, 0.74, continental_height);
	float shallows = (1.0 - coastline) * smoothstep(0.45, 0.51, continental_height);
	vec3 sea = ocean_color * (0.88 + value_noise(p * 34.0) * 0.25);
	sea += vec3(0.025, 0.10, 0.10) * shallows;
	vec3 surface = mix(sea, mix(land_color, light_land_color, altitude), coastline * relief);
	float clouds = smoothstep(0.52, 0.71, terrain(p * vec3(8.0, 13.0, 8.0) + 3.4));
	float wisps = smoothstep(0.46, 0.65, terrain(p * vec3(17.0, 26.0, 17.0) + 34.2));
	surface = mix(surface, vec3(0.65, 0.77, 0.81), clouds * (0.45 + 0.36 * wisps) * relief);
	float limb = pow(1.0 - max(dot(normalize(NORMAL), VIEW), 0.0), 3.5);
	float air = limb * (0.15 + smoothstep(-0.35, 0.8, sun_dot) * 0.63) * relief;
	float twilight = smoothstep(-0.27, 0.04, sun_dot) * (1.0 - smoothstep(0.02, 0.45, sun_dot));
	vec3 color = surface * (0.12 + light_level * 0.88);
	color += vec3(0.11, 0.35, 0.59) * air;
	color += vec3(0.12, 0.18, 0.24) * limb * twilight * relief;
	ALBEDO = color;
}
