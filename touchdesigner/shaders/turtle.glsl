// NDGA turtle fractals — step generator. DESSIN 143-182 (Fractales générales), 183-212 (arrondies),
// 74-76 (turtle driven by the (N-1)-adic valuation of the step index).
//
// Book 143-212: for step index I, walk its base-N digits from the top: at each level pick generator
// segment T3 (= digit, or N-1-digit when the orientation EE is reversed), then
//   AA += BB*EE*A[T3], LL *= L[T3], BB *= 1-2B[T3], EE *= 1-2E[T3]; C[T3] = stop recursing (the whole
//   subtree becomes ONE straight step and I jumps by N^J); D[T3] = pen up.
// A step depends only on its own digits -> every step is computed in parallel; positions come from
// the prefix sum in `scan`, then `place` adds the edge start.
// C makes the book skip whole subtrees (177 walks 5^10 indices to draw ~4k steps). Here threads are
// numbered by LIVE leaf only: leaves(d) = nt + nr*leaves(d-1) per subtree, and each thread decodes its
// leaf ordinal into the digit path by subtracting subtree sizes -> no wasted threads.
// 74-76: heading(i) = AA * sum_{j<=i} (min(v_{N-1}(j), K-1) + 1), closed form by Legendre:
//   sum_{j=1..i} min(v(j), K-1) = sum_{t=1..K-1} floor(i / b^t), plus K for j = 0.
//
// Output per edge e: point 0 = edge start (Step 0, LineBreak 1), points 1..Leaves = steps.
// Units: book pixels (NP = 480) -> normalised [-1,1] (factor 2/480).
// Uniforms: uD, uF = (family, N, K, edges), uL = (leaves, round S), uWarp (angle scale - 1).

#define PI 3.14159265359
#define MAXN 18

float Lg[MAXN]; float Ag[MAXN]; int Bg[MAXN]; int Cg[MAXN]; int Dg[MAXN]; int Eg[MAXN];

void setGen(int fam, int N)
{
	for (int t = 0; t < MAXN; t++) { Lg[t] = 0.0; Ag[t] = 0.0; Bg[t] = 0; Cg[t] = 0; Dg[t] = 0; Eg[t] = 0; }
	float r5 = sqrt(5.0), r2 = sqrt(2.0);
	switch (fam)
	{
	case 0: case 8: {
		float a0 = (fam == 0) ? -atan(sqrt(3.0) / 25.0) : -atan(sqrt(3.0 / 25.0));
		for (int t = 0; t < 7; t++) Lg[t] = sqrt(1.0 / 7.0);
		Ag[0] = a0; Ag[1] = a0 + PI / 3.0; Ag[2] = a0 + PI; Ag[3] = a0 + 2.0 * PI / 3.0; Ag[4] = a0; Ag[5] = a0; Ag[6] = Ag[3] + PI;
		Bg[1] = 1; Bg[2] = 1; Bg[6] = 1; Eg[1] = 1; Eg[2] = 1; Eg[6] = 1; break; }
	case 1:
		Lg[0] = 0.5; Lg[1] = r5 / 6.0; Lg[2] = 1.0 / 3.0; Lg[3] = 2.0 * Lg[1]; Lg[4] = 1.0 / 3.0; Lg[5] = Lg[1]; Lg[6] = 0.5;
		Ag[1] = atan(2.0); Ag[2] = PI; Ag[3] = -Ag[1]; Ag[4] = PI; Ag[5] = Ag[1];
		Cg[1] = 1; Cg[3] = 1; Cg[5] = 1; break;
	case 2:
		for (int t = 0; t < 7; t++) Lg[t] = 1.0 / 3.0; Lg[4] = 1.0 / sqrt(3.0);
		Ag[0] = PI / 3.0; Ag[1] = PI / 3.0; Ag[3] = -PI / 3.0; Ag[4] = -5.0 * PI / 6.0;
		Bg[0] = 1; Bg[4] = 1; Bg[5] = 1; break;
	case 3:
		Lg[0] = 0.5; Lg[1] = 0.5; Lg[2] = 0.5; Ag[0] = PI / 3.0; Ag[2] = -PI / 3.0; Bg[0] = 1; Bg[2] = 1; break;
	case 4:
		Lg[0] = 1.0; for (int t = 1; t < 9; t++) Lg[t] = 0.5;
		Ag[1] = 3.0 * PI / 4.0; Ag[2] = -PI / 4.0; Ag[3] = PI / 4.0; Ag[4] = 5.0 * PI / 4.0; Ag[5] = -PI / 4.0; Ag[6] = 3.0 * PI / 4.0; Ag[7] = -3.0 * PI / 4.0; Ag[8] = PI / 4.0;
		Cg[0] = 1; Cg[2] = 1; Cg[4] = 1; Cg[6] = 1; Cg[8] = 1; Dg[2] = 1; Dg[4] = 1; Dg[6] = 1; Dg[8] = 1; break;
	case 5:
		Lg[0] = 1.0; for (int t = 1; t < 5; t++) Lg[t] = 1.0 / r2;
		Ag[1] = PI / 4.0; Ag[2] = 5.0 * PI / 4.0; Ag[3] = -PI / 4.0; Ag[4] = 3.0 * PI / 4.0;
		Cg[0] = 1; Cg[2] = 1; Cg[4] = 1; Dg[2] = 1; Dg[4] = 1; break;
	case 6:
		Lg[0] = 1.0 / 3.0; Lg[1] = 1.0 / 6.0; Lg[2] = 1.0 / 3.0; Lg[3] = 1.0 / 6.0; Lg[4] = 1.0 / 6.0; Lg[5] = 1.0 / 3.0; Lg[6] = 1.0 / 6.0; Lg[7] = 1.0 / 3.0; Lg[8] = 1.0 / 3.0;
		Ag[1] = PI / 2.0; Ag[3] = -PI / 2.0; Ag[4] = -PI / 2.0; Ag[5] = -PI; Ag[6] = PI / 2.0;
		Dg[7] = 1; break;
	case 7: {
		Lg[0] = r5 / 4.0; Lg[1] = 3.0 / 8.0; Lg[2] = sqrt(73.0) / 8.0; Lg[3] = 3.0 / 8.0; Lg[4] = sqrt(41.0) / 8.0;
		Lg[5] = sqrt(40.0) / 8.0; Lg[6] = Lg[0]; Lg[7] = sqrt(68.0) / 8.0; Lg[8] = Lg[5]; Lg[9] = Lg[8]; Lg[10] = Lg[7];
		Lg[11] = Lg[0]; Lg[12] = Lg[5]; Lg[13] = 1.0; Lg[14] = sqrt(10.0) / 8.0; Lg[15] = Lg[14]; Lg[16] = Lg[14]; Lg[17] = Lg[14];
		Ag[0] = atan(2.0); Ag[2] = atan(8.0 / 3.0) + PI; Ag[4] = atan(-4.0 / 5.0) + PI; Ag[5] = atan(-3.0) + PI;
		Ag[6] = atan(0.5); Ag[7] = atan(-0.25); Ag[8] = atan(3.0) + PI; Ag[9] = atan(-3.0); Ag[10] = atan(0.25) + PI;
		Ag[11] = atan(-0.5) + PI; Ag[12] = atan(3.0); Ag[14] = atan(1.0 / 3.0); Ag[15] = atan(1.0 / 3.0) + PI;
		Ag[16] = atan(-1.0 / 3.0); Ag[17] = atan(-1.0 / 3.0) + PI;
		for (int t = 0; t < 18; t++) Cg[t] = 1; Cg[1] = 0; Cg[3] = 0;
		Dg[0] = 1; Dg[1] = 1; Dg[2] = 1; Dg[3] = 1; Dg[4] = 1; Dg[15] = 1; Dg[17] = 1; break; }
	case 9: case 10: case 11:
		Lg[0] = 1.0 / 3.0; Lg[1] = 1.0 / 3.0; Lg[2] = 2.0 / 3.0; Lg[3] = 1.0 / 3.0; Lg[4] = 1.0 / 3.0; Lg[5] = 1.0 / 3.0;
		Ag[1] = 2.0 * PI / 3.0; Ag[3] = -PI; Ag[4] = -PI / 3.0; Bg[1] = 1; Bg[4] = 1; break;
	case 12:
		Lg[0] = 0.25; Lg[1] = r2 / 4.0; Lg[2] = Lg[1]; Lg[3] = Lg[1]; Lg[4] = Lg[1]; Lg[5] = 0.5; Lg[6] = 0.25;
		Ag[1] = -PI / 4.0; Ag[2] = PI / 4.0; Ag[3] = 3.0 * PI / 4.0; Ag[4] = -3.0 * PI / 4.0;
		Bg[0] = 1; Bg[2] = 1; Bg[4] = 1; Bg[6] = 1; Cg[5] = 1; Eg[1] = 1; Eg[3] = 1; break;
	case 13:
		Lg[0] = 1.0 / r2; Lg[1] = 0.5; Lg[2] = 0.5; Ag[0] = PI / 4.0; Ag[1] = -PI / 2.0; Bg[0] = 1; break;
	case 14:
		for (int t = 0; t < 4; t++) Lg[t] = 0.5; Ag[0] = PI / 2.0; Ag[3] = -PI / 2.0; Bg[0] = 1; Bg[3] = 1; break;
	case 15:
		for (int t = 0; t < 9; t++) Lg[t] = 1.0 / 3.0;
		Ag[2] = PI / 2.0; Ag[3] = PI; Ag[4] = -PI / 2.0; Ag[5] = -PI / 2.0; Ag[7] = PI / 2.0; break;
	case 16:
		for (int t = 0; t < 9; t++) Lg[t] = 1.0 / 3.0;
		Ag[1] = PI / 2.0; Ag[3] = -PI / 2.0; Ag[4] = PI; Ag[5] = -PI / 2.0; Ag[7] = PI / 2.0; Cg[4] = 1; break;
	}
	for (int t = 0; t < MAXN; t++) Ag[t] *= (1.0 + uWarp);
}

// edge e endpoints in book pixels
void edgeOf(int fam, int e, out vec2 a, out vec2 b)
{
	float NP = 480.0;
	a = vec2(0.0); b = vec2(NP, 0.0);
	switch (fam)
	{
	case 0: case 8: a = vec2(NP / 9.0, NP / 5.0); b = vec2(8.0 * NP / 9.0, NP / 5.0); break;
	case 1: case 6: a = vec2(0.0, NP / 2.0); b = vec2(NP, NP / 2.0); break;
	case 2: case 3: a = vec2(0.0, NP / 5.0); b = vec2(NP, NP / 5.0); break;
	case 4: a = vec2(NP / 2.0, 0.0); b = vec2(NP / 2.0, NP / 2.0); break;
	case 5: a = vec2(NP / 2.0, 0.0); b = vec2(NP / 2.0, NP / 4.0); break;
	case 7: a = vec2(NP / 6.0, NP / 2.0); b = vec2(NP * 35.0 / 48.0, NP / 2.0); break;
	case 9: { float w0 = 2.0 * float(e) * PI / 6.0, w1 = 2.0 * float(e + 1) * PI / 6.0;
		a = NP / 2.0 * (1.0 + vec2(cos(w0), sin(w0))); b = NP / 2.0 * (1.0 + vec2(cos(w1), sin(w1))); break; }
	case 10: case 11: { float r = (fam == 10) ? 0.7 : 0.65;
		float w0 = -(4.0 * float(e) + 3.0) * PI / 6.0, w1 = -(4.0 * float(e + 1) + 3.0) * PI / 6.0;
		a = NP / 2.0 * (1.0 + r * vec2(cos(w0), sin(w0))); b = NP / 2.0 * (1.0 + r * vec2(cos(w1), sin(w1))); break; }
	case 12: a = vec2(0.0, NP); b = vec2(NP, 0.0); break;
	case 13: a = vec2(NP / 9.0, 7.0 * NP / 9.0); b = vec2(NP / 9.0, -7.0 * NP / 9.0); break;
	case 14: a = vec2(0.0); b = vec2(NP, 0.0); break;
	case 15: case 16: a = vec2(0.0); b = vec2(NP, NP); break;
	}
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int fam = uF.x, N = uF.y, K = uF.z;
	int leaves = uL.x;
	int e = int(id) / (leaves + 1);
	int j = int(id) % (leaves + 1);      // 0 = edge start, 1.. = steps
	vec2 step = vec2(0.0);
	int pen = (j == 0) ? 1 : 0;

	if (j > 0 && fam >= 20)
	{
		// ---- 74-76 ----
		int i = j - 1;
		float LL = (fam == 20) ? 480.0 / 150.0 : ((fam == 21) ? 480.0 / 100.0 : 480.0 / 170.0);
		float AA = (fam == 20) ? 2.0 * PI / 3.0 : ((fam == 21) ? 4.0 * PI / 5.0 : PI / 2.0);
		int P = (fam == 20) ? 3 : ((fam == 21) ? 5 : 4);   // AA * P is a multiple of 2 PI
		int b = N - 1;
		int c = (i + 1) + (K - 1);
		int bt = 1;
		for (int t = 1; t <= K - 1; t++) { bt *= b; c += i / bt; }
		float heading = (uWarp == 0.0) ? AA * float(c % P) : 2.0 * PI * fract(float(c) * AA * (1.0 + uWarp) / (2.0 * PI));
		step = LL * vec2(cos(heading), sin(heading));
	}
	else if (j > 0)
	{
		// ---- general turtle: decode live leaf (j-1) into its digit path ----
		setGen(fam, N);
		int nt = 0;
		for (int t = 0; t < N; t++) nt += Cg[t];
		int nr = N - nt;
		int fcount[21];
		fcount[0] = 1;
		for (int d = 1; d <= K; d++) fcount[d] = nt + nr * fcount[d - 1];

		vec2 a, b; edgeOf(fam, e, a, b);
		vec2 dv = b - a;
		float AA = atan(dv.y, dv.x);
		float LL = length(dv);
		float BB = 1.0, EE = 1.0;
		int DD = 0;
		int o = j - 1;
		for (int J = K - 1; J >= 0; J--)
		{
			int T3 = 0; bool stop = false;
			for (int T2 = 0; T2 < N; T2++)
			{
				int t3 = (EE > 0.0) ? T2 : N - 1 - T2;
				int size = (Cg[t3] == 1) ? 1 : fcount[J];
				if (o < size) { T3 = t3; break; }
				o -= size;
			}
			AA += BB * EE * Ag[T3];
			LL *= Lg[T3];
			BB *= float(1 - 2 * Bg[T3]);
			EE *= float(1 - 2 * Eg[T3]);
			DD = Dg[T3];
			if (Cg[T3] == 1) break;
		}
		step = LL * vec2(cos(AA), sin(AA));
		pen = DD;
	}

	oTDPoint_Step[id] = vec3(step * (2.0 / 480.0), 0.0);
	oTDPoint_LineBreak[id] = pen;
	oTDPoint_Alive[id] = 1;
	oTDPoint_Edge[id] = e;
	oTDPoint_P[id] = vec3(0.0);
}
