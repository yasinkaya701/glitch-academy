shader_type canvas_item;

// Grade the contributed historical plates into the game's restrained graphite,
// parchment and amber palette without changing their period imagery.
uniform float grade_amount : hint_range(0.0, 1.0) = 0.78;
uniform float warm_light : hint_range(0.0, 1.0) = 0.24;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec3 rgb = source.rgb;
	float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 muted = mix(vec3(luma), rgb, 0.62);
	vec3 parchment = vec3(0.68, 0.64, 0.55);
	muted = mix(muted, muted * parchment * 1.36, warm_light);
	muted = (muted - vec3(0.5)) * 1.10 + vec3(0.46, 0.45, 0.41);
	// Keep the archive warm and readable while reserving deep values for the UI.
	muted *= smoothstep(0.0, 0.18, luma) * 0.18 + 0.82;
	rgb = mix(rgb, muted, grade_amount);
	COLOR = vec4(rgb, source.a);
}
