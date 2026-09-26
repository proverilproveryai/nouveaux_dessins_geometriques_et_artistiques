// NDGA "Transformations", DESSIN 123-142: in-betweens of two curves (123-132 Lissajous->Lissajous,
// 133-142 Lissajous->square).
// Curve A: (CX + R cos(H1 w), CY + R sin(H2 w)),  curve B: same with its own R/CX/CY/H1/H2 + phase A0.
// For layer L in [K1..K2] draw closed polyline lerp(B, A, L/K). One strip per layer (N+1 points).
// Uniforms: uNK = (N, K, K1, layers)  uA = (R, CX, CY, H1) of A   uB = (R, CX, CY, H1) of B
//           uX = (H2 of A, H2 of B, A0 of B, special129)          uAnim = (phase added to curve A, blend shift)
// Book space is [0,1] (NP*X) -> output [-1,1], y-up.

#define PI 3.14159265359

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int N = uNK.x;
	int ppl = N + 1;
	int layer = int(id) / ppl;
	int i = int(id) % ppl;
	float w = 2.0 * PI * float(i) / float(N);
	int special = int(uX.w + 0.5);     // 1: DESSIN 129 (R/6 squash)  2: B is a square (133-142)  3: square + 141 (YA R/5)
	bool sp = special == 1;

	vec2 a = vec2(uA.y + uA.x * (sp ? 1.0 / 6.0 : 1.0) * cos(uA.w * w + uAnim.x),
	              uA.z + uA.x * (special == 3 ? 0.2 : 1.0) * sin(uX.x * w + uAnim.x));
	vec2 b = vec2(uB.y + uB.x * cos(uB.w * w + uX.z),
	              uB.z + uB.x * (sp ? 1.0 / 6.0 : 1.0) * sin(uX.y * w + uX.z));
	if (special >= 2)
	{
		// book: AN = int(4I/N) PI/2 + A0, walk the side from corner AN to corner AN + PI/2
		float t4 = 4.0 * float(i) / float(N);
		float side = min(floor(t4), 3.0);
		float JR = t4 - side;
		float AN = side * PI / 2.0 + uX.z;
		vec2 c1 = uB.yz + uB.x * vec2(cos(AN), sin(AN));
		vec2 c2 = uB.yz + uB.x * vec2(cos(AN + PI / 2.0), sin(AN + PI / 2.0));
		b = JR * c2 + (1.0 - JR) * c1;
	}

	float LR = float(uNK.z + layer) / float(uNK.y) + uAnim.y;
	vec2 p = LR * a + (1.0 - LR) * b;

	oTDPoint_P[id] = vec3(2.0 * p - 1.0, 0.0);
	oTDPoint_LineBreak[id] = (i == 0) ? 1 : 0;
}
