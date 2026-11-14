shader_type canvas_item;
// Baş ve yüz yamaları üzerinde çalışan organik mikro-deformasyon shader'ı.
// Kenarlarda (safe = 0) deformasyon sıfır olduğu için gövde (body.png) ile dikiş izi yapmaz;
// iç bölgede ise baş eğimi, konuşma onayı (nod), çene/sakal esnemesi, kaş ve göz hareketi üretir.

uniform vec2 head_shift = vec2(0.0, 0.0);
uniform float head_tilt : hint_range(-0.12, 0.12) = 0.0;
uniform float jaw_open : hint_range(0.0, 1.0) = 0.0;
uniform float brow_lift : hint_range(-1.0, 1.0) = 0.0;
uniform float eye_squint : hint_range(0.0, 1.0) = 0.0;
uniform float cheek_blush : hint_range(0.0, 1.0) = 0.0;
uniform float mouth_y_uv : hint_range(0.3, 0.7) = 0.48;

float gauss(float x, float mu, float sigma) {
	float d = (x - mu) / sigma;
	return exp(-0.5 * d * d);
}

void fragment() {
	vec2 uv = UV;
	// Kenar emniyet zarfı: yama sınırlarında deformasyon tam sıfırdır, omuz/gövdeyle dikiş izi olmaz
	float sx = smoothstep(0.06, 0.24, uv.x) * (1.0 - smoothstep(0.76, 0.94, uv.x));
	float sy = smoothstep(0.04, 0.16, uv.y) * (1.0 - smoothstep(0.76, 0.94, uv.y));
	float safe = sx * sy;

	// 0. Başın boyun pivotu (0.5, 0.70) etrafında yumuşak eğilmesi ve mikro-odak kayması
	vec2 pivot = vec2(0.5, 0.70);
	vec2 rel = uv - pivot;
	float c = cos(head_tilt * safe);
	float s = sin(head_tilt * safe);
	uv = pivot + vec2(rel.x * c - rel.y * s, rel.x * s + rel.y * c) - head_shift * safe;

	// 1. Alt çene ve sakal esnemesi (konuşurken kesintisiz hareket)
	float jaw_zone_y = smoothstep(mouth_y_uv - 0.03, mouth_y_uv + 0.08, uv.y) * (1.0 - smoothstep(0.72, 0.92, uv.y));
	float jaw_zone_x = gauss(uv.x, 0.5, 0.19);
	float jaw_pull = jaw_open * jaw_zone_y * jaw_zone_x * safe;
	uv.y -= jaw_pull * 0.024;

	// 2. Kaş kuşağı hareketi (+ şaşkınlık/kıpırtı, - çatma/düşünme)
	float brow_y = gauss(uv.y, 0.31, 0.045);
	float brow_inner = gauss(uv.x, 0.5, 0.18);
	uv.y += brow_lift * brow_y * brow_inner * safe * 0.015;
	float frown = max(-brow_lift, 0.0);
	uv.x += (0.5 - uv.x) * frown * brow_y * brow_inner * safe * 0.026;

	// 3. Göz kısma / mikro kırpma
	float eye_band = gauss(uv.y, 0.37, 0.032) * (gauss(uv.x, 0.38, 0.07) + gauss(uv.x, 0.62, 0.07));
	float eye_dir = sign(0.375 - uv.y);
	uv.y -= eye_dir * eye_squint * eye_band * safe * 0.011;

	vec4 tex = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));

	// 4. Doğal elmacık/yanak kızarması (yalnızca sıcak ten piksellerinde etkili)
	float cheek_mask = gauss(uv.y, 0.43, 0.05) * (gauss(uv.x, 0.35, 0.08) + gauss(uv.x, 0.65, 0.08) + 0.5 * gauss(uv.x, 0.5, 0.06));
	float skin_warmth = clamp((tex.r - tex.b) * 2.2, 0.0, 1.0);
	float blush_amt = cheek_blush * cheek_mask * skin_warmth * safe * 0.42;
	tex.rgb = mix(tex.rgb, vec3(0.86, 0.30, 0.26) * length(tex.rgb) * 0.85, blush_amt);

	COLOR = tex * COLOR;
}
