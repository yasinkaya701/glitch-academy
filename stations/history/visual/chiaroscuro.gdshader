shader_type canvas_item;
render_mode blend_mix;

// Tarihî ve felsefi portreler için sade, doğal müze tablosu sunumu.
// Yapay rim-light (parlayan kenar halkası), yapay renk tonlaması ve dijital gren kaldırılmıştır.
// Tablonun orijinal otantik fırça dokusunu ve renklerini birebir korur.

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a <= 0.005) {
		discard;
	}

	// Yalnızca tablonun alt kısmının sahneye yumuşakça oturması için hafif geçiş
	float fade_bottom = smoothstep(1.08, 0.75, UV.y);
	col.a *= fade_bottom;

	COLOR = col;
}
