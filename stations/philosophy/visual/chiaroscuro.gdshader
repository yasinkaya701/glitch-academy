shader_type canvas_item;
render_mode blend_mix;

// Dengeli, doğal ve sinematik portre ışıklandırması
// Aşırı karartma, yanma veya çamurlaşma yapmaz;
// Yalnızca karakterin formunu ortaya çıkaran yumuşak gün ışığı,
// çok hafif sıcak-soğuk ton ayrımı ve doğal fırça derinliği ekler.

uniform float light_warmth : hint_range(0.0, 1.0) = 0.45;
uniform float contrast_lift : hint_range(0.0, 1.0) = 0.22;
uniform float rim_subtle : hint_range(0.0, 1.0) = 0.24;
uniform float film_grain : hint_range(0.0, 1.0) = 0.06;

float hash(vec2 p) {
	vec2 q = fract(p * vec2(123.34, 456.21));
	q += dot(q, q + 45.32);
	return fract(q.x * q.y);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a <= 0.005) {
		discard;
	}

	vec3 rgb = col.rgb;
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));

	// 1. Doğal Yönlü Işık Gradyanı (Sağ üstten hafif, dengeli bir parlama)
	// Karakterin yüzünü ve bakış yönünü yumuşakça aydınlatır
	float key_grad = smoothstep(-0.25, 0.85, (UV.x - 0.40) * 0.9 + (0.55 - UV.y) * 1.1);
	vec3 warm_sun = vec3(1.05, 1.01, 0.96);
	vec3 cool_ambient = vec3(0.95, 0.97, 1.01);
	vec3 light_tint = mix(cool_ambient, warm_sun, key_grad * light_warmth);

	// 2. Dengeli Kontrast (Plastik solgunluğu alır, ama gölgeleri zifiri yapmaz)
	// Gölge tabanı %88'de tutularak detaylar korunur
	vec3 balanced = pow(rgb, vec3(1.0 - contrast_lift * 0.15));
	balanced = mix(balanced * 0.92, balanced * 1.06, key_grad * 0.65 + 0.35);
	balanced *= light_tint;

	// 3. Zarif Kenar Işığı (Rim Light) - Karakteri arka plandan doğalca ayırır
	vec2 tex_pixel = 1.0 / vec2(textureSize(TEXTURE, 0));
	float a_right = texture(TEXTURE, UV + vec2(tex_pixel.x * 3.5, 0.0)).a;
	float a_left = texture(TEXTURE, UV - vec2(tex_pixel.x * 3.5, 0.0)).a;
	float edge = clamp((col.a - a_left) * 1.2, 0.0, 1.0) * smoothstep(0.12, 0.75, 1.0 - UV.x);
	balanced += vec3(0.98, 0.92, 0.80) * (edge * rim_subtle * smoothstep(0.15, 0.65, 1.0 - UV.y));

	// 4. Çok İnce Organik Film/Boya Greni (Yapay AI pürüzsüzlüğünü nazikçe kırar)
	float grain = (hash(UV * vec2(380.0, 480.0)) - 0.5) * film_grain * 0.12;
	balanced += vec3(grain);

	// 5. Alta doğru çok hafif, doğal tablo geçişi
	float fade_bottom = smoothstep(1.10, 0.45, UV.y);
	balanced *= mix(0.88, 1.0, fade_bottom);

	COLOR = vec4(clamp(balanced, 0.0, 1.0), col.a);
}
