shader_type canvas_item;
// Kilatan putih saat battler terkena serangan atau merapal sihir.

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// COLOR sudah berisi warna tekstur dikali modulate.
	vec4 c = COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);
}
