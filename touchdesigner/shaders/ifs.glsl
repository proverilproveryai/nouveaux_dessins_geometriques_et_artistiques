// NDGA "Fractales multivoques", DESSIN 267-286: a base polyline copied through every chain of maps
// of length H, for every level H in [H1, H2] (all levels are drawn, not only the last one).
// Book: copy index I < K^H; its base-K digits (least significant first) pick the map applied at each step.
// GPU: thread -> (level H, copy I, vertex l) by subtracting per-level offsets sum K^h.
// 267-272: map i = rotate(2 PI i / K) o (scale R3, offset R2), book space [-1,1].
// 273-286: per-DESSIN maps (affine and a few non-linear: 275, 281, 282), book space [0,1].
// Live: uTwist rotates each map's result a little more per level (about the drawing's centre).
// Uniforms: uD, uKH = (K, H1, H2, M).

#define PI 3.14159265359

vec2 base(int d, int l, int M)
{
	float fl = float(l), fM = float(M);
	if (d <= 272)
	{
		float W = 2.0 * PI * fl / fM;
		if (d == 269) W += PI / 2.0;
		if (d == 271 || d == 272) W = 2.0 * PI * fl * 4.0 / fM + PI / 2.0;
		float R1 = (d == 272) ? 0.5 : 1.0;
		return R1 * vec2(cos(W), sin(W));
	}
	switch (d)
	{
	case 273: return vec2(0.5 + 0.5 * cos(PI * fl / fM), 0.5 * sin(PI * fl / fM));
	case 274: { float Q = 2.0 * PI * fl / fM; return vec2(cos(Q), sin(Q)); }
	case 276: { vec2 m[7] = vec2[7](vec2(0.5, 1), vec2(0.5, 0.5), vec2(0, 0.5), vec2(0, 1), vec2(1, 1), vec2(1, 0.5), vec2(0.5, 0.5)); return m[l]; }
	case 277: case 281: case 282: { float W = 2.0 * fl * PI / fM; return vec2(0.5 + 0.5 * cos(W), 0.5 + 0.5 * sin(W)); }
	case 283: case 284: case 285: case 286: { vec2 m[5] = vec2[5](vec2(0, 0), vec2(0.5, 0), vec2(0.5, 0.5), vec2(0, 0.5), vec2(0, 0)); return m[l]; }
	default: { vec2 m[5] = vec2[5](vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1), vec2(0, 0)); return m[l]; } // 275 278 279 280
	}
}

vec2 mapK(int d, int i, vec2 p, int K)
{
	float x = p.x, y = p.y;
	if (d <= 272)
	{
		float R2 = 0.5, R3 = 0.5;
		if (d == 268) { R2 = 0.5; R3 = 1.0 / 3.0; }
		if (d == 270) { R2 = 1.0 / sqrt(3.0); R3 = 1.0 / 3.0; }
		float W = 2.0 * PI * float(i) / float(K), C = cos(W), S = sin(W);
		return vec2(R3 * x * C - (R2 + R3 * y) * S, R3 * x * S + (R2 + R3 * y) * C);
	}
	switch (d)
	{
	case 273: return (i == 0) ? vec2(x / 2.0, y / 2.0) : vec2(1.0 - x / 2.0, -y / 2.0);
	case 274: return (i == 0) ? vec2(-0.5 - y / 2.0, x / 2.0) : vec2(0.5 - y / 2.0, x / 2.0);
	case 275: {
		vec2 q = vec2(x * x / 3.0, y * y / 3.0);
		vec2 o[5] = vec2[5](vec2(1.0 / 3.0, 1.0 / 3.0), vec2(0, 1.0 / 3.0), vec2(1.0 / 3.0, 0), vec2(2.0 / 3.0, 1.0 / 3.0), vec2(1.0 / 3.0, 2.0 / 3.0));
		return q + o[i]; }
	case 276: case 277:
		if (i == 0) return vec2(x / 2.0, y / 2.0);
		if (i == 1) return vec2(x / 2.0 + 0.5, y / 2.0);
		if (i == 2) return vec2(x / 4.0 + 1.0 / 8.0, y / 4.0 + 5.0 / 8.0);
		return vec2(x / 4.0 + 5.0 / 8.0, y / 4.0 + 5.0 / 8.0);
	case 278: {
		if (i == 0) return vec2(x / 3.0, y / 3.0);
		if (i == 1) return vec2(1.0 - x / 3.0, y / 3.0);
		if (i == 2) return vec2(1.0 - x / 3.0, 1.0 - y / 3.0);
		if (i == 3) return vec2(x / 3.0, 1.0 - y / 3.0);
		float CO = cos(PI / 4.0), SI = sin(PI / 4.0), R3 = sqrt(2.0) / 3.0;
		return vec2(R3 * (CO * x - SI * y) + 0.5, R3 * (SI * x + CO * y) + 1.0 / 6.0); }
	case 279: case 280: {
		vec2 o[5] = vec2[5](vec2(1.0 / 3.0, 0), vec2(0, 1.0 / 3.0), vec2(1.0 / 3.0, 1.0 / 3.0), vec2(2.0 / 3.0, 1.0 / 3.0), vec2(1.0 / 3.0, 2.0 / 3.0));
		return vec2(x / 3.0, y / 3.0) + o[i]; }
	case 281: {
		float a = x * x / 2.0, b = y * y / 2.0;
		if (i == 0) return vec2(a, b); if (i == 1) return vec2(1.0 - a, b); if (i == 2) return vec2(a, 1.0 - b); return vec2(1.0 - a, 1.0 - b); }
	case 282: {
		float a = x * x / 3.0, b = y * y / 3.0;
		if (i == 0) return vec2(a, b); if (i == 1) return vec2(1.0 - a, b); if (i == 2) return vec2(a, 1.0 - b); if (i == 3) return vec2(1.0 - a, 1.0 - b);
		return vec2(1.0 / 3.0 + x / 3.0, 1.0 / 3.0 + y / 3.0); }
	case 283: return (i == 0) ? vec2(1.0 - x / 2.0, 1.0 - y / 2.0) : vec2(0.5 + y / 2.0, x / 2.0);
	case 284:
		if (i == 0) return vec2(0.5 + x / 2.0, y / 4.0);
		if (i == 1) return vec2(x / 2.0, 0.5 + y / 2.0);
		if (i == 2) return vec2(1.0 / 8.0 + x / 4.0, 1.0 / 8.0 + y / 4.0);
		return vec2(1.0 - x / 4.0, 1.0 - y / 2.0);
	case 285:
		if (i == 0) return vec2(0.5 + x / 2.0, 0.25 + y / 2.0);
		if (i == 1) return vec2(x / 2.0, 0.5 + y / 2.0);
		if (i == 2) return vec2(1.0 / 8.0 + x / 4.0, 1.0 / 8.0 + y / 4.0);
		return vec2(0.75 + x / 4.0, y / 4.0);
	default: // 286
		if (i == 0) return vec2(0.5 + x / 2.0, y / 2.0);
		if (i == 1) return vec2(x / 2.0, 0.5 + y / 2.0);
		if (i == 2) return vec2(x / 4.0 + 1.0 / 8.0, 1.0 / 8.0 + y / 4.0);
		if (i == 3) return vec2(1.0 - x / 4.0, 1.0 - y / 4.0);
		return vec2(0.5 + x / 4.0, 0.5 + y / 4.0);
	}
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int K = uKH.x, H1 = uKH.y, H2 = uKH.z, M = uKH.w;
	int copy = int(id) / (M + 1);
	int l = int(id) % (M + 1);

	int H = H1, n = 1;
	for (int h = 0; h < H1; h++) n *= K;          // K^H1
	while (H < H2 && copy >= n) { copy -= n; n *= K; H++; }

	vec2 p = base(uD, l, M);
	vec2 ctr = (uD <= 272) ? vec2(0.0) : vec2(0.5);
	int I0 = copy;
	for (int j = 0; j < H; j++)
	{
		int I2 = I0 % K;
		p = mapK(uD, I2, p, K);
		if (uTwist != 0.0) { float c = cos(uTwist), s = sin(uTwist); vec2 q = p - ctr; p = ctr + vec2(c * q.x - s * q.y, s * q.x + c * q.y); }
		I0 /= K;
	}

	vec2 o;
	if (uD <= 272) o = p;                                   // NP/2 (1 + X)
	else if (uD == 274) o = 2.0 * (0.5 * (p + 1.0)) - 1.0;  // DESSINE maps (X+1)/2 first, then NP*X
	else o = 2.0 * p - 1.0;                                 // NP * X
	if (uD == 273) o.y += 2.0 / 2.25;                       // p5 port: translate(0, -NP/2.25)

	oTDPoint_P[id] = vec3(o, 0.0);
	oTDPoint_LineBreak[id] = (l == 0) ? 1 : 0;
}
