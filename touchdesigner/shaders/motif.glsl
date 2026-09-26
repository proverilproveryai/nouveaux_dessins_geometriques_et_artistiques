// NDGA "Motifs répétés", DESSIN 1-20: a small base polyline copied through the product of
// K parameterised transforms (mirrors, rotations, lattice shifts, scalings).
// Book: nested odometer over E_k in [0, T_k), then apply TRANSFORME[0..K-1] in order.
// GPU: thread -> (copy c, vertex l); digits of c in mixed radix (T_0 fastest) give E_0..E_{K-1}.
// Pen lifts: book Z[l]==1 -> LineBreak (always vertex 0; DESSIN 15 also 4, 9, 12).
// Live: uAnim.x = extra twist added to every rotation step (radians per E), uAnim.y = base motif scale.
// Uniforms: uD dessin, uKM = (K, M), uT0/uT1 = transform counts T0..T5 (only used for decoding).
// Output: book space [-1,1] (NP*(X+1)/2), y-up. DESSIN 9/13 keep the p5 port's y squash.

#define PI 3.14159265359

// rotation by E steps of 2PI/n (twist applied per step)
vec2 ROTE(vec2 p, float E, float n) { float c = cos(E * (2.0 * PI / n + uAnim.x)), s = sin(E * (2.0 * PI / n + uAnim.x)); return vec2(c * p.x - s * p.y, c * p.y + s * p.x); }

vec2 baseMotif(int d, int l)
{
	float R2 = sqrt(3.0) / 2.0, R3 = sqrt(3.0);
	float fl = float(l);
	switch (d)
	{
	case 1: case 2: case 3: { vec2 m[3] = vec2[3](vec2(0.1, 0.0), vec2(0.15, 0.2), vec2(0.0, 0.15)); return m[l]; }
	case 4: { vec2 m[5] = vec2[5](vec2(0, 0), vec2(-R2, 0.5), vec2(0, 1), vec2(R2, 0.5), vec2(0, 0)); return m[l]; }
	case 5: { vec2 m[4] = vec2[4](vec2(-1, 1), vec2(-1, 3), vec2(0, 0), vec2(1, 3)); return m[l]; }
	case 6: { vec2 m[6] = vec2[6](vec2(0, 0), vec2(-1, 1), vec2(-1, 3), vec2(1, 3), vec2(1, 1), vec2(0, 0)); return m[l]; }
	case 7: { vec2 m[6] = vec2[6](vec2(0, 0), vec2(2, 0), vec2(2.5, R3 / 2.0), vec2(2, R3), vec2(1, R3), vec2(0, 0)); return m[l]; }
	case 8: { vec2 m[2] = vec2[2](vec2(-1, 3), vec2(2, 0)); return m[l]; }
	case 9: { vec2 m[3] = vec2[3](vec2(-R2, 0.5), vec2(0, 0.5), vec2(0, 0)); return m[l]; }
	case 10: { float W = 2.0 * fl * PI / 8.0; return vec2(cos(W), 0.2 + sin(W) / 3.0); }
	case 11: { vec2 m[3] = vec2[3](vec2(-1, 2), vec2(0, 3), vec2(2, 0)); return m[l]; }
	case 12: case 19: {
		if (d == 12) { vec2 m[3] = vec2[3](vec2(-1, 0), vec2(-R2 / 3.0, 2.0 / 3.0), vec2(2.0 * R2, 2)); return m[l]; }
		vec2 m[2] = vec2[2](vec2(-R2 / 2.0, -0.25), vec2(R2, 1.25)); return m[l]; }
	case 13: { vec2 m[5] = vec2[5](vec2(0, 0), vec2(-R2, 0.5), vec2(0, 0.25), vec2(R2, 0.5), vec2(0, 0)); return m[l]; }
	case 14: { vec2 m[5] = vec2[5](vec2(0, 0), vec2(-0.5, 0.5), vec2(0, 1), vec2(0.5, 0.5), vec2(0, 0)); return m[l]; }
	case 15: { float W = 2.0 * fl * PI / 16.0 / 5.0; return vec2(cos(W * 5.0), 1.0 + sin(3.0 * W) / 2.0); }
	case 16: { float W = 2.0 * fl * PI / 16.0 / 10.0; return vec2(cos(W * 5.0), 1.0 + sin(3.0 * W)); }
	case 17: { vec2 m[5] = vec2[5](vec2(0, 0), vec2(0, 2), vec2(3, 3), vec2(2, 0), vec2(0, 0)); return m[l]; }
	case 18: { vec2 m[4] = vec2[4](vec2(-R2, 0.5), vec2(0, 0.75), vec2(0, 0.25), vec2(R2, 0.5)); return m[l]; }
	case 20: { float W = 2.0 * fl * PI / 12.0; return vec2(cos(W), sin(W)); }
	}
	return vec2(0.0);
}

vec2 transformK(int d, int k, vec2 p, float E)
{
	float x = p.x, y = p.y;
	float R2 = sqrt(3.0) / 2.0, R3 = sqrt(3.0);
	float e = 0.001;
	switch (d)
	{
	case 1:
		if (k == 0) return vec2((1.0 - 2.0 * E) * x, y);
		if (k == 1) return vec2(x, (1.0 - 2.0 * E) * y);
		if (k == 2) return ROTE(p, E, 8.0);
		if (k == 3) return vec2(x + (E - 1.0) / 2.0, y);
		return vec2(x, y + (E - 1.0) / 2.0);
	case 2:
		if (k == 0) return vec2((1.0 - 2.0 * E) * x, y);
		if (k == 1) return vec2(x, (1.0 - 2.0 * E) * y);
		if (k == 2) return ROTE(p, E, 8.0);
		if (k == 3) return vec2(x / 2.0 + (E - 3.0) / 4.0, y / 2.0);
		if (k == 4) return vec2(x, y + (E - 3.0) / 4.0);
		return vec2(x + E / 8.0, y + E / 8.0);
	case 3:
		if (k == 0) return vec2((1.0 - 2.0 * E) * x, y);
		if (k == 1) return vec2(x, (1.0 - 2.0 * E) * y);
		if (k == 2) return ROTE(p, E, 8.0);
		if (k == 3) return vec2(x / 2.0 + (E - 2.0) / 4.0, y / 2.0);
		if (k == 4) return vec2(x, y + (E - 2.0) / 4.0);
		return ROTE(p, E, 8.0);
	case 4:
		if (k == 0) return ROTE(p, E, 3.0);
		if (k == 1) return vec2((E - 2.0) * R2 + x, (E - 2.0) * 1.5 + y);
		return vec2((-(E - 2.0) * R2 + x) / 6.0 + e, ((E - 2.0) * 1.5 + y) / 6.0 + e);
	case 5: case 6: case 17:
		if (k == 0) return ROTE(p, E, 4.0);
		if (k == 1) return vec2((E - 2.0) * 4.0 + x, (E - 2.0) * 2.0 + y);
		return vec2((-2.0 * (E - 2.0) + x) / 16.0 + e, (4.0 * (E - 2.0) + y) / 16.0 + e);
	case 7:
		if (k == 0) return ROTE(p, E, 6.0);
		if (k == 1) return vec2((E - 2.0) * 4.5 + x, -(E - 2.0) * R3 / 2.0 + y);
		return vec2((-(E - 2.0) * 1.5 + x) / 16.0 + e, ((E - 2.0) * R3 * 2.5 + y) / 16.0 + e);
	case 8:
		if (k == 0) return ROTE(p, E, 4.0);
		if (k == 1) return vec2((E - 2.0) * 4.0 + x, (E - 2.0) * 2.0 + y);
		return vec2((-2.0 * (E - 2.0) * 1.5 + x) / 16.0 + e, (4.0 * (E - 2.0) + y) / 16.0 + e);
	case 9:
		if (k == 0) return ROTE(p, E, 6.0);
		if (k == 1) return vec2((E - 4.0) * R2 + x, (E - 4.0) * 1.5 + y);
		return vec2((-(E - 4.0) * R2 + x) / 9.0 + e, (E - 4.0 + y) / 9.0 + e);
	case 10: case 15: case 16:
		if (k == 0) return ROTE(p, E, (d == 10) ? 12.0 : 6.0);
		if (k == 1) return vec2((E - 3.0) / 6.0 + x / 12.0, y / 12.0);
		return vec2(1.3 * (mod(E, 2.0) / 12.0 + x), 1.3 * (R3 * (E - 2.0) / 12.0 + y));
	case 11:
		if (k == 0) return vec2((1.0 - 2.0 * E) * x, y);
		if (k == 1) return ROTE(p, E, 4.0);
		if (k == 2) return vec2((E - 3.0) * 4.0 + x, y);
		return vec2(x / 15.0 + e, ((E - 3.0) * 4.0 + y) / 15.0 + e);
	case 12: case 19:
		if (k == 0) return ROTE(p, E, (d == 12) ? 6.0 : 3.0);
		if (k == 1) return vec2(x, 1.0 - (1.0 - 2.0 * E) * (1.0 - y));
		if (k == 2) return vec2((E - 2.0) * R2 * 2.0 + x, (E - 2.0) * 3.0 + y);
		return vec2((-(E - 2.0) * R2 * 2.0 + x) / 10.0 + e, ((E - 2.0) * 3.0 + y) / 10.0 + e);
	case 13:
		if (k == 0) return ROTE(p, E, 3.0);
		if (k == 1) return vec2(x, 0.5 - (1.0 - 2.0 * E) * (0.5 - y));
		if (k == 2) return vec2((E - 2.0) * R2 + x, (E - 2.0) * 1.5 + y);
		return vec2((-(E - 2.0) * R2 + x) / 6.0 + e, ((E - 2.0) * 1.5 + y) / 6.0 + e);
	case 14:
		if (k == 0) return ROTE(p, E, 3.0);
		if (k == 1) return vec2((E - 2.0) * R2 + x, (E - 2.0) * 1.5 + y);
		return vec2((-(E - 2.0) * R2 + x) / 5.0 + e, ((E - 2.0) * 1.5 + y) / 5.0 + e);
	case 18:
		if (k == 0) return ROTE(p, E, 3.0);
		if (k == 1) return vec2(x, 0.5 - (1.0 - 2.0 * E) + (0.5 - y));   // sic, as in the book listing
		if (k == 2) return vec2((E - 3.0) * R2 + x, (E - 3.0) * 1.5 + y);
		return vec2((-(E - 3.0) * R2 + x) / 6.0 + e, ((E - 3.0) * 1.5 + y) / 6.0 + e);
	case 20: {
		float s = pow(0.5, E);
		if (k == 0) return vec2(-1.0 + s * (1.0 + x), y * s);
		if (k == 1) return vec2(1.0 + s * (-1.0 + x), y * s);
		if (k == 2) return vec2(s * x, -1.0 + s * (1.0 + y));
		return vec2(s * x, 1.0 + s * (-1.0 + y)); }
	}
	return p;
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int K = uKM.x, M = uKM.y;
	int c = int(id) / (M + 1);
	int l = int(id) % (M + 1);
	int Tn[6] = int[6](uT0.x, uT0.y, uT0.z, uT1.x, uT1.y, uT1.z);

	vec2 p = baseMotif(uD, l) * uAnim.y;
	for (int k = 0; k < K; k++)
	{
		float E = float(c % Tn[k]);
		c /= Tn[k];
		p = transformK(uD, k, p, E);
	}
	if (uD == 9)  p.y = 0.8 * p.y;
	if (uD == 13) p.y = 0.8 * p.y - 0.05;

	bool pen = (l == 0) || (uD == 15 && (l == 4 || l == 9 || l == 12));
	oTDPoint_P[id] = vec3(p, 0.0);
	oTDPoint_LineBreak[id] = pen ? 1 : 0;
}
