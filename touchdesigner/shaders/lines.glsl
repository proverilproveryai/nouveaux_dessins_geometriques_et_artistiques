// NDGA independent segments: Cantor chords 70-73, Moirages 213-216, Cubes en dimension K 217-246.
// Every thread writes one END of one segment (2 points per segment, LineBreak on the first).
// Cantor: around an N-gon, chord pairs (C->D) and (E->F) chosen by offsets H1..H3; the I-th point of
//         a 5-level Cantor set on each chord is joined (32 segments per vertex M).
// Moire:  K pairs of source segments, N+1 segments lerp(seg0, J/N) -> lerp(seg1, J/N).
// Cubes:  2^K hypercube vertices projected with K basis vectors; edge (vertex I, axis Q) drawn when
//         bit Q of I is 0 (every edge once). Edges with bit Q = 1 are culled (Alive = 0).
// uPhase (live): Cantor = polygon rotation, Moire = sliding of the lerp parameter,
//                Cubes = per-axis rotation of the projection basis (a "turning" hypercube).
// Uniforms: uD dessin, uP = (p0 density-scaled, p1, p2, p3) from meta.
// Output: book space NP=480 -> [-1,1], y-up.

#define PI 3.14159265359

vec2 cantorPt(int I, vec2 A, vec2 B)
{
	const int K = 5;
	int IS = I;
	float RS = 0.0;
	for (int LS = 0; LS <= K - 1; LS++)
	{
		int JS = IS % 2;
		if (LS > 0) RS += float(JS) * 2.0 / pow(3.0, float(K - LS));
		else RS = float(JS) / pow(3.0, float(K - 1));
		IS /= 2;
	}
	return RS * (A - B) + B;
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int seg = int(id) / 2;
	int endp = int(id) % 2;
	vec2 p = vec2(0.0);   // in [0,1] book space (NP units / 480)
	int alive = 1;

	if (uD >= 70 && uD <= 73)
	{
		int N = uP.x;
		int M = seg / 32, I = seg % 32;
		float AN = uPhase * 2.0 * PI;
		vec2 C = 0.5 + 0.5 * vec2(cos(2.0 * PI * float(M) / float(N) + AN), sin(2.0 * PI * float(M) / float(N) + AN));
		vec2 D = 0.5 + 0.5 * vec2(cos(2.0 * PI * float(M + uP.y) / float(N) + AN), sin(2.0 * PI * float(M + uP.y) / float(N) + AN));
		vec2 E = 0.5 + 0.5 * vec2(cos(2.0 * PI * float(M + uP.z) / float(N) + AN), sin(2.0 * PI * float(M + uP.z) / float(N) + AN));
		vec2 F = 0.5 + 0.5 * vec2(cos(2.0 * PI * float(M + uP.w) / float(N) + AN), sin(2.0 * PI * float(M + uP.w) / float(N) + AN));
		p = (endp == 0) ? cantorPt(I, C, D) : cantorPt(I, E, F);
	}
	else if (uD >= 213 && uD <= 216)
	{
		int N = uP.x;
		int I = seg / (N + 1), J = seg % (N + 1);
		// segment endpoints XD/YD -> XA/YA, 2 per family I (book listing, normalised by NP)
		vec4 S[8];
		if (uD == 213) { S[0] = vec4(0, 0, 1, 0); S[1] = vec4(0.25, 1, 0.75, 1); S[2] = vec4(0, 1, 1, 1); S[3] = vec4(0.25, 0, 0.75, 0); }
		else if (uD == 214) { S[0] = vec4(0.375, 0, 0.5, 0); S[1] = vec4(0, 1, 1, 1); S[2] = vec4(0.5, 0, 0.625, 0); S[3] = vec4(0, 1, 1, 1); }
		else if (uD == 215) {
			S[0] = vec4(0, 0, 0, 0); S[1] = vec4(1, 0, 1, 1); S[2] = vec4(0.125, 0, 0.125, 0); S[3] = vec4(1, 0, 1, 1);
			S[4] = vec4(1, 1, 1, 1); S[5] = vec4(0, 0, 0, 1); S[6] = vec4(0.875, 1, 0.875, 1); S[7] = vec4(0, 0, 0, 1); }
		else { S[0] = vec4(0, 0, 0, 1); S[1] = vec4(1, 1, 1, 0); S[2] = vec4(0, 0, 1, 0); S[3] = vec4(1, 1, 0, 1); }
		float L = fract(float(J) / float(N) + uPhase);
		if (uPhase == 0.0) L = float(J) / float(N);
		vec4 s = S[2 * I + endp];
		p = L * s.xy + (1.0 - L) * s.zw;
	}
	else
	{
		int K = uP.x;
		int I = seg / K, Q = seg % K;
		vec2 B[10];
		B[0] = vec2(1, 0); B[1] = vec2(0, 1); B[2] = vec2(0.5, 0.5); B[3] = vec2(-0.25, 0.25); B[4] = vec2(0.125, 0.375);
		B[5] = vec2(-1.0 / 16.0, 5.0 / 16.0); B[6] = vec2(3.0 / 32.0, 1.0 / 32.0); B[7] = vec2(-1.0 / 64.0, 7.0 / 64.0);
		B[8] = vec2(3.0 / 128.0, 11.0 / 128.0); B[9] = vec2(-3.0 / 256.0, 13.0 / 256.0);
		vec2 O = vec2(1.0 / 6.0, 1.0 / 20.0);
		if (uD >= 225 && uD <= 229) {
			B[3] = vec2(0.25, 0.125); B[4] = vec2(-0.125, 0.25); B[5] = vec2(1.0 / 16.0, 3.0 / 16.0);
			B[6] = vec2(1.0 / 32.0, -1.0 / 64.0); B[7] = vec2(1.0 / 64.0, 1.0 / 32.0); B[8] = vec2(3.0 / 128.0, 1.0 / 128.0);
			O = vec2(0.10, 0.1); }
		else if (uD >= 230 && uD <= 236) { for (int l = 0; l < K; l++) { float W = PI * (float(l) + 0.5) / float(K); B[l] = 3.0 * vec2(cos(W), sin(W)) / float(K); } O = vec2(0.5, 0.05); }
		else if (uD >= 237 && uD <= 241) { for (int l = 0; l < K; l++) { float W = PI * float(l) / float(K); B[l] = vec2(cos(W), sin(W)) / float(l + 1); } O = vec2(0.15, 0.1); }
		else if (uD >= 242) { for (int l = 0; l < K; l++) { float W = PI * float(l) / float(K - 1); B[l] = 3.0 * vec2(cos(W), sin(W)) / float(K); } O = vec2(0.5, 0.15); }
		if (uPhase != 0.0)
			for (int l = 0; l < K; l++) { float a = uPhase * 2.0 * PI * (1.0 + 0.37 * float(l)); float c = cos(a), s = sin(a); B[l] = vec2(c * B[l].x - s * B[l].y, s * B[l].x + c * B[l].y); }
		vec2 X1 = O;
		for (int l = 0; l < K; l++) if (((I >> l) & 1) == 1) X1 += B[l] * 0.45;
		alive = (((I >> Q) & 1) == 0) ? 1 : 0;
		p = (endp == 0) ? X1 : X1 + B[Q] * 0.45;
		if (uD >= 220 && uD <= 224) { vec2 q = 2.0 * p - 1.0; q.y = 0.9 * q.y - 0.18333; p = 0.5 * q + 0.5; }
	}

	oTDPoint_P[id] = vec3(2.0 * p - 1.0, 0.0);
	oTDPoint_LineBreak[id] = (endp == 0) ? 1 : 0;
	oTDPoint_Alive[id] = alive;
}
