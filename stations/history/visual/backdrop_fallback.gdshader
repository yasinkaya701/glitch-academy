shader_type canvas_item;
// Atmosferik revak/avlu arka planı: sol üstten süzülen sıcak altın saat (golden hour) ışık huzmeleri,
// alan derinliği içinde yumuşak taş sütun silüetleri ve sıcak taş zemin.

uniform float era_mode : hint_range(0.0, 1.0) = 0.0; // 0: Antik Yunan (mermer/kehribar), 1: İslam Altın Çağı (kemer/turkuaz-altın)
uniform float repair_warmth : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	// 1. Derin alacakaranlık-altın saat gökyüzü gradyanı
	vec3 sky_top = mix(vec3(0.055, 0.085, 0.135), vec3(0.045, 0.090, 0.130), era_mode);
	vec3 sky_horizon = mix(vec3(0.22, 0.16, 0.12), vec3(0.24, 0.17, 0.11), era_mode);
	sky_horizon += vec3(0.10, 0.07, 0.03) * repair_warmth;
	float h_curve = smoothstep(0.0, 0.78, uv.y);
	vec3 col = mix(sky_top, sky_horizon, h_curve);

	// 2. Uzak planda bulanık (alan derinliği / bokeh) revak sütunları
	float horizon_y = 0.76;
	if (uv.y < horizon_y) {
		float x_rep = fract(uv.x * 5.5 + 0.15);
		// Yumuşak kenarlı bulanık sütun gövdeleri
		float col_mask = smoothstep(0.32, 0.42, x_rep) * (1.0 - smoothstep(0.58, 0.68, x_rep));
		float top_beam = smoothstep(0.04, 0.14, uv.y);
		// Kemer veya arşitrav geçişi
		float arch = smoothstep(0.12, 0.24, uv.y + 0.09 * cos((x_rep - 0.5) * 6.28318 * era_mode));
		float structure = clamp(col_mask * top_beam + (1.0 - arch), 0.0, 1.0);
		// Karakterin arkasındaki sağ-orta bölgeyi (uv.x 0.50..0.82) daha sakin tut
		float center_calm = 1.0 - 0.55 * exp(-pow((uv.x - 0.66) / 0.18, 2.0));
		vec3 stone_dark = mix(vec3(0.045, 0.058, 0.082), vec3(0.040, 0.062, 0.085), era_mode);
		col = mix(col, stone_dark, structure * center_calm * 0.65);
	}

	// 3. Sol üstten sağ alta süzülen hacimsel güneş huzmeleri (god rays)
	vec2 sun_origin = vec2(0.08, -0.12);
	vec2 rel = uv - sun_origin;
	float angle = atan(rel.y, rel.x);
	float dist = length(rel * vec2(1.4, 1.0));
	float ray1 = exp(-pow((angle - 0.52) / 0.16, 2.0));
	float ray2 = exp(-pow((angle - 0.82) / 0.22, 2.0));
	float ray3 = exp(-pow((angle - 0.28) / 0.14, 2.0));
	float rays = (ray1 * 0.55 + ray2 * 0.45 + ray3 * 0.35) * exp(-dist * 1.15);
	vec3 sun_col = vec3(0.98, 0.73, 0.42) * (1.0 + 0.35 * repair_warmth);
	col += sun_col * rays * 0.42;

	// 4. Sıcak taş avlu zemini (perspektif karartması + ışık yansıması)
	float floor_t = smoothstep(horizon_y - 0.02, horizon_y + 0.03, uv.y);
	float depth_y = clamp((uv.y - horizon_y) / (1.0 - horizon_y), 0.0, 1.0);
	vec3 floor_far = vec3(0.11, 0.095, 0.088);
	vec3 floor_near = vec3(0.035, 0.040, 0.052);
	vec3 floor_col = mix(floor_far, floor_near, pow(depth_y, 0.75));
	// Zemine düşen sıcak güneş lekesi
	float pool = exp(-pow((uv.x - 0.42) / 0.28, 2.0) - pow((uv.y - 0.84) / 0.10, 2.0));
	floor_col += sun_col * pool * 0.16;
	col = mix(col, floor_col, floor_t);

	COLOR = vec4(col, 1.0);
}
