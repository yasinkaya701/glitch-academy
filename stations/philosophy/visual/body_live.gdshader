shader_type canvas_item;
// Tam boy filozof gövdesi için canlı nefes, omuz kalkışı, üst gövde salınımı
// ve konuşurken el/önkol jesti (gesture) üreten organik deformasyon shader'ı.

uniform float breath : hint_range(-1.0, 1.0) = 0.0;
uniform float speak_gesture : hint_range(0.0, 1.0) = 0.0;
uniform float gesture_phase : hint_range(0.0, 6.28318) = 0.0;
uniform float lean_x : hint_range(-1.0, 1.0) = 0.0;
uniform float slump : hint_range(0.0, 1.0) = 0.0;

float gauss(float x, float mu, float sigma) {
	float d = (x - mu) / sigma;
	return exp(-0.5 * d * d);
}

void fragment() {
	vec2 uv = UV;
	// Ayak tabanları (uv.y > 0.90) yere sağlam basar; üst gövde (uv.y < 0.85) canlı hareket eder
	float upper_body = 1.0 - smoothstep(0.65, 0.92, uv.y);
	float safe_edge = smoothstep(0.02, 0.10, uv.x) * (1.0 - smoothstep(0.90, 0.98, uv.x))
		* smoothstep(0.02, 0.08, uv.y) * (1.0 - smoothstep(0.92, 0.99, uv.y));

	// 1. Üst gövde ağırlık aktarımı ve hafif öne/yana eğilme
	uv.x -= lean_x * upper_body * safe_edge * 0.016;

	// 2. Göğüs ve omuz nefes hareketi (uv.y = 0.18 .. 0.42)
	float chest_band = gauss(uv.y, 0.28, 0.09);
	uv.y += breath * chest_band * safe_edge * 0.010;
	uv.x -= (uv.x - 0.5) * breath * chest_band * safe_edge * 0.018;

	// 3. Hafıza kaybı çöküklüğü (slump): omuzlar hafif düşük
	float shoulder_band = gauss(uv.y, 0.24, 0.08) * (gauss(uv.x, 0.28, 0.12) + gauss(uv.x, 0.72, 0.12));
	uv.y -= slump * shoulder_band * safe_edge * 0.012;

	// 4. Konuşurken el ve önkol jestleri (geniş ve yumuşak zarf: parmaklarda kırılma yapmaz)
	float arm_y = gauss(uv.y, 0.36, 0.11);
	float left_arm = arm_y * gauss(uv.x, 0.28, 0.15);
	float right_arm = arm_y * gauss(uv.x, 0.68, 0.15);

	float g_l = sin(gesture_phase) * 0.5 + 0.5;
	float g_r = sin(gesture_phase * 1.25 + 1.4) * 0.5 + 0.5;

	uv.y += speak_gesture * (left_arm * g_l * 0.014 + right_arm * g_r * 0.016) * safe_edge;
	uv.x += speak_gesture * (left_arm * g_l * 0.010 - right_arm * g_r * 0.011) * safe_edge;

	COLOR = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0))) * COLOR;
}
