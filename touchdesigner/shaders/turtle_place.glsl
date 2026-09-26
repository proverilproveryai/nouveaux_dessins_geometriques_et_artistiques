// NDGA turtle — placement. Input 0 = `scan` (Sum = inclusive prefix sum of Step over the whole POP).
// accumulatePOP cannot reset per curve, so each edge subtracts the running sum at its own start point:
//   P = start(edge) + Sum[id] - Sum[first point of the edge]   (the start point's own Step is 0).
// Then the p5 port's per-DESSIN translate/scale fixes are applied (converted to normalised y-up space).
// Uniforms: uD, uF = (family, N, K, edges), uL = (leaves, round S).

#define PI 3.14159265359

vec2 edgeStart(int fam, int e)
{
	float NP = 480.0;
	switch (fam)
	{
	case 0: case 8: return vec2(NP / 9.0, NP / 5.0);
	case 1: case 6: return vec2(0.0, NP / 2.0);
	case 2: case 3: return vec2(0.0, NP / 5.0);
	case 4: case 5: return vec2(NP / 2.0, 0.0);
	case 7: return vec2(NP / 6.0, NP / 2.0);
	case 9: { float w = 2.0 * float(e) * PI / 6.0; return NP / 2.0 * (1.0 + vec2(cos(w), sin(w))); }
	case 10: case 11: { float r = (fam == 10) ? 0.7 : 0.65; float w = -(4.0 * float(e) + 3.0) * PI / 6.0; return NP / 2.0 * (1.0 + r * vec2(cos(w), sin(w))); }
	case 12: return vec2(0.0, NP);
	case 13: return vec2(NP / 9.0, 7.0 * NP / 9.0);
	case 20: return vec2(3.0 * NP / 4.0, NP / 4.0);
	case 21: return vec2(0.3 * NP, NP / 8.0);
	case 22: return vec2(0.75 * NP, 0.2401 * NP);
	}
	return vec2(0.0);   // 14, 15, 16
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int leaves = uL.x;
	int e = int(id) / (leaves + 1);
	uint first = uint(e * (leaves + 1));
	vec3 s = TDInPoint_Sum(0, id) - TDInPoint_Sum(0, first);
	vec2 p = edgeStart(uF.x, e) * (2.0 / 480.0) - 1.0 + s.xy;

	int d = uD;
	if (d == 144) p += vec2(70.0, -30.0) * (2.0 / 480.0);
	else if (d == 145) p += vec2(130.0, -60.0) * (2.0 / 480.0);
	else if (d == 146) p += vec2(185.0, -70.0) * (2.0 / 480.0);
	else if ((d >= 153 && d <= 161) || (d >= 170 && d <= 182)) p.y = 0.85 * p.y + 0.025;   // translate(0,30) scale(1,.85)
	else if (d >= 162 && d <= 169) p.y -= 50.0 * 2.0 / 480.0;                              // translate(0,50)
	else if (d >= 183 && d <= 186) p.y += 35.0 * 2.0 / 480.0;                              // translate(0,-35)
	else if (d == 190 || d == 191) p.y -= 45.0 * 2.0 / 480.0;                              // translate(0,45)
	else if (d >= 197 && d <= 200) p.y = 0.675 * p.y + 0.690625;                            // scale(1,.675) translate(0,-130)

	oTDPoint_P[id] = vec3(p, 0.0);
}
