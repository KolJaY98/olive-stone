shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep : source_color = vec4(0.18, 0.40, 0.50, 1.0);
uniform vec4 shallow : source_color = vec4(0.36, 0.66, 0.70, 1.0);
uniform float wave_height = 2.5;

varying float crest;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 0.6;
	crest = sin(w.x * 0.011 + t) * cos(w.z * 0.009 - t * 0.8);
	VERTEX.y += crest * wave_height;
}

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Shallower (lighter) towards the shore at the east edge of the sea plane.
	float shore = smoothstep(-2600.0, -1300.0, w.x);
	float sparkle = pow(max(0.0, sin(w.x * 0.05 + TIME * 1.3) * sin(w.z * 0.043 - TIME)), 6.0);
	vec3 col = mix(deep.rgb, shallow.rgb, shore * 0.85 + crest * 0.06);
	ALBEDO = col + vec3(sparkle * 0.18);
	ROUGHNESS = 0.25;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
