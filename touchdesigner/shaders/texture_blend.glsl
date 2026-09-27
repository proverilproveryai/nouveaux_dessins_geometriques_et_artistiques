// texture/blend: Color.rgb = mix(base, op(base, texture), uMix); alpha kept
// uBlend: 0 replace, 1 multiply, 2 add
void main(){
	const uint id = TDIndex(); if (id >= TDNumElements()) return;
	vec4 c = TDInPoint_Color(0, id);
	vec3 t = TDInPoint_Texc(0, id).rgb;
	vec3 r = (uBlend == 0) ? t : (uBlend == 1) ? c.rgb * t : c.rgb + t;
	oTDPoint_Color[id] = vec4(mix(c.rgb, r, uMix), c.a);
}
