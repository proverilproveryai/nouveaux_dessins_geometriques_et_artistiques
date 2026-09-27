// NDGA Von Koch, DESSIN 60-69: Koch curve on every edge of regular M-gons (stacked / gridded).
// Generator: N=4 segments, length 1/3 each, turn angles [0, +a, -a, 0] (a = uAng.x, book = 60 deg).
//
// GPU trick: the book walks the curve step by step (a serial sum). Here every thread computes its
// vertex position directly from the base-N digits of its index: at each level it adds the chord of
// every earlier sub-generator. Chord of a sub-generator of depth d = LL * e^{i AA} * G^d, where
// G = sum_s L[s] e^{i A[s]} (complex). O(K*N) per point, no scan, fully parallel.
// For a != 60 deg |G| != 1, so the curve is renormalised by G^-K to keep the polygon closed.
//
// Layout: instance (layer / grid cell) -> M edges -> (4^Kmax + 1) vertices per edge, one strip per edge
// (the book lifts the pen at every edge). Layers with K < Kmax are resampled onto the same count.
// Uniforms: uD dessin, uMKP = (M, Kmax, points per edge, depth offset), uAng = (generator angle, spin per layer)

#define PI 3.14159265359
#define NG 4

vec2 cmul(vec2 a, vec2 b) { return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }
vec2 cdiv(vec2 a, vec2 b) { return vec2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / dot(b, b); }
vec2 cexp(float a) { return vec2(cos(a), sin(a)); }

float GA[NG];
const float GL = 1.0 / 3.0;

// vertex j (0..4^K) of a Koch edge of depth K, starting at 0, chord z0 = L0 * e^{i A0}
vec2 kochVertex(int j, int K, vec2 z0, vec2 G, vec2 Gpow[8])
{
	vec2 zn = cdiv(z0, Gpow[K]);          // renormalise so the edge still ends at its vertex
	int total = 1;
	for (int t = 0; t < K; t++) total *= NG;
	if (j >= total) return z0;
	vec2 p = vec2(0.0);
	vec2 dir = zn;                        // LL * e^{i AA} as one complex number
	int T1 = j;
	int R = total;
	for (int J = K - 1; J >= 0; J--)
	{
		R /= NG;
		int t = T1 / R;
		for (int s = 0; s < t; s++)
			p += cmul(cmul(dir, GL * cexp(GA[s])), Gpow[J]);
		dir = cmul(dir, GL * cexp(GA[t]));
		T1 -= t * R;
	}
	return p;
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int M = uMKP.x, Kmax = uMKP.y, ppe = uMKP.z;
	int inst = int(id) / (M * ppe);
	int rem = int(id) % (M * ppe);
	int edge = rem / ppe;
	int v = rem % ppe;

	float a = uAng.x;
	GA[0] = 0.0; GA[1] = a; GA[2] = -a; GA[3] = 0.0;
	vec2 G = vec2(0.0);
	for (int s = 0; s < NG; s++) G += GL * cexp(GA[s]);
	vec2 Gpow[8];
	Gpow[0] = vec2(1.0, 0.0);
	for (int t = 1; t < 8; t++) Gpow[t] = cmul(Gpow[t - 1], G);

	// ---- per-instance polygon (book formulas) ----
	float L = float(inst), Q = 0.0;
	float Rr = 1.0, XC = 0.0, YC = 0.0, AD = PI / 2.0;
	int K = 3;
	float s3 = sqrt(3.0);
	switch (uD)
	{
	case 60: Rr = 1.0 / pow(s3, L); AD = PI / 2.0 + L * PI / 6.0; K = 2; break;
	case 61: Rr = 1.0 / pow(s3, L); AD = PI / 2.0 + L * PI / 6.0; K = 4 - int(L / 2.0); break;
	case 62: Rr = 1.0 / pow(s3, L / 2.0); AD = PI / 2.0 + L * PI / 12.0; K = 4 - int(L / 3.0); break;
	case 63: Rr = pow(0.5, floor(L / 8.0)) / 4.0; AD = PI * L / 4.0; XC = 3.0 * Rr * cos(AD); YC = 3.0 * Rr * sin(AD); K = 3 - int(L / 16.0); break;
	case 64: Rr = pow(0.5, floor(L / 18.0)) / 4.0; AD = 2.0 * PI * L / 18.0; XC = 3.0 * Rr * cos(AD); YC = 3.0 * Rr * sin(AD); K = 3 - int(L / 36.0); break;
	case 65: Rr = 1.0; AD = PI / 2.0; YC = 0.001; K = int(L); break;
	case 66: L = float(inst / 5); Q = float(inst % 5); Rr = sqrt(2.0) / 6.0; XC = (L - 2.0) / 3.0; YC = (Q - 2.0) / 3.0; AD = PI / 4.0; break;
	case 67: {
		// book loop: L 4..7, Q from 0 while L+Q <= 10  -> 7,6,5,4 cells
		int c = inst, l = 4;
		while (c >= 11 - l) { c -= 11 - l; l++; }
		L = float(l); Q = float(c);
		XC = 0.5 + Q / 8.0 - L / 8.0; YC = -1.5 + (Q + L) * s3 / 8.0; Rr = s3 / 12.0; break; }
	case 68: L = float(inst / 7); Q = float(inst % 7); Rr = 0.25; XC = (L - 3.0) * 4.0 / 21.0; YC = (Q - 3.0) * 4.0 / 21.0; break;
	case 69: L = float(inst / 9); Q = float(inst % 9); Rr = 1.0 / 3.0; XC = (L - 2.0) * 4.0 / 21.0; YC = (Q - 4.0) * 4.0 / 21.0; break;
	}
	AD += uAng.y * float(inst);
	K = clamp(K + uMKP.w, 0, Kmax);

	float W0 = -2.0 * PI * float(edge) / float(M) + AD;
	float W1 = -2.0 * PI * float(edge + 1) / float(M) + AD;
	vec2 P0 = vec2(XC, YC) + Rr * cexp(W0);
	vec2 P1 = vec2(XC, YC) + Rr * cexp(W1);
	vec2 z0 = P1 - P0;

	// resample depth-K edge onto the fixed 4^Kmax + 1 vertex count
	int d = 1;
	for (int t = 0; t < Kmax - K; t++) d *= NG;
	int j = v / d;
	float f = float(v % d) / float(d);
	vec2 pa = kochVertex(j, K, z0, G, Gpow);
	vec2 pb = (f > 0.0) ? kochVertex(j + 1, K, z0, G, Gpow) : pa;
	vec2 p = P0 + mix(pa, pb, f);

	oTDPoint_P[id] = vec3(p, 0.0);
	oTDPoint_LineBreak[id] = (v == 0) ? 1 : 0;
}
