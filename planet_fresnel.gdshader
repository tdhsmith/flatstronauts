shader_type canvas_item;

//float fresnel(float amount, vec3 normal, vec3 view)
//{
	//return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
//}

uniform vec4 glow_color = vec4(0.0, 0.7, 0.9, 1.0);
uniform float glow_intensity = 0.5;
uniform float dropoff_factor = 2.5;
uniform float overflow_percentage = 10.0;
uniform bool use_wibbles = true;

float fresnel(float amount, vec2 coord, float overrun)
{
	float r_squared = (coord.x * coord.x) + (coord.y * coord.y);
	if (r_squared > 1.0) {
		return clamp((1.0 + overrun - r_squared) / overrun, 0.0, 1.0);
	}
	return pow(clamp(r_squared, 0.0, 1.0), amount / 2.0);
}

uniform float wibbliness = 0.75;
uniform float wibble_subdivision = 20.0;
void vertex() {
	if (use_wibbles) {
		VERTEX += wibbliness * vec2(cos(TIME+wibble_subdivision*(UV.x + UV.y)), sin(TIME+wibble_subdivision*(UV.y + UV.x)));
	}
}

void fragment(){
	vec4 base_color = texture(TEXTURE, UV);
	float basic_fresnel = fresnel(dropoff_factor, vec2(1.0 - (2.0*UV.x), 1.0 - (2.0*UV.y)), overflow_percentage / 100.0);
	COLOR = (basic_fresnel * glow_color * glow_intensity) + base_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
