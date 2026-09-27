// texture/coord: Tuv = lookup coordinate for every point
// Input 0: points with Cs = (cumulative length, strip ordinal 1..S) from a prefix sum.
// Input 1: bounds (Min / Max of P).
// uMode: 0 position XY, 1 polar, 2 along strip, 3 strip number, 4 point number
// uSpace: 0 frame (+-1), 1 bounds.  uIndex: 1 = sample index (raw integer index, pixel units)
uint firstGE(float s, uint n) {          // first i with Cs.y >= s
	uint lo = 0u, hi = n;
	while (lo < hi) { uint m = (lo + hi) / 2u; if (TDInPoint_Cs(0, m).y >= s) hi = m; else lo = m + 1u; }
	return lo;
}
void main(){
	const uint id = TDIndex(); if (id >= TDNumElements()) return;
	uint n = TDNumElements();
	vec3 p = TDInPoint_P(0, id);
	vec2 lo = vec2(-1.0), hi = vec2(1.0);
	if (uSpace == 1) { lo = TDInPoint_Min(1, 0u).xy; hi = TDInPoint_Max(1, 0u).xy; }
	vec2 size = max(hi - lo, vec2(1e-6));
	vec2 uv;
	bool idx = (uIndex == 1) && (uMode >= 2);
	if (uMode == 0) {
		uv = (p.xy - lo) / size;
	} else if (uMode == 1) {
		vec2 d = (p.xy - 0.5 * (lo + hi)) / (0.5 * max(size.x, size.y));
		uv = vec2(atan(d.y, d.x) / 6.28318530718 + 0.5, length(d));
	} else {
		vec2 c = TDInPoint_Cs(0, id);
		float u;
		if (uMode == 2) {
			uint s = firstGE(c.y, n);
			uint e = firstGE(c.y + 0.5, n) - 1u;
			float l0 = TDInPoint_Cs(0, s).x, l1 = TDInPoint_Cs(0, e).x;
			u = idx ? float(id - s) : (c.x - l0) / max(l1 - l0, 1e-9);
		} else if (uMode == 3) {
			float S = TDInPoint_Cs(0, n - 1u).y;
			u = idx ? c.y - 1.0 : (c.y - 1.0) / max(S - 1.0, 1.0);
		} else {
			u = idx ? float(id) : float(id) / max(float(n) - 1.0, 1.0);
		}
		uv = vec2(u, idx ? 0.0 : 0.5);
	}
	oTDPoint_Tuv[id] = uv * uScale + uOffset;
}
