// NDGA turtle — "SOUS PROGRAMME POUR ARRONDIR" (DESSIN 183-212). Input 1 = placed points.
// For every step, with X0, X1, X2 = positions before-previous, previous and current:
//   V = X1 - X0, W = X2 - X1, and for K4 = 0..S:  XQ = (X0 + X2 + cos(a)(-W) + sin(a) V) / 2, a = PI/2 K4/S
// i.e. a quarter ellipse through the midpoints of the two adjacent segments replaces the corner.
// Book pen rules: the first step and every pen-up step (D) print all S+1 points as moves, so only the
// last of them survives here (Alive = 0 for the others, LineBreak = 1 on it). Edge starts are moves too.
// Thread = (placed point, k), numbered point * (S+1) + k. Uniforms: uD, uF, uL = (leaves, S).

#define PI 3.14159265359

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int S = uL.y;
	int leaves = uL.x;
	int total = uF.w * (leaves + 1);
	int pi = int(id) / (S + 1);
	int k = int(id) % (S + 1);
	if (pi >= total) { oTDPoint_Alive[id] = 0; oTDPoint_LineBreak[id] = 1; oTDPoint_P[id] = vec3(0.0); return; }
	int j = pi % (leaves + 1);

	vec3 X2 = TDInPoint_P(1, uint(pi));
	if (j == 0)
	{
		oTDPoint_P[id] = X2; oTDPoint_Alive[id] = 0; oTDPoint_LineBreak[id] = 1;
		return;
	}
	vec3 X1 = TDInPoint_P(1, uint(pi - 1));
	vec3 X0 = (j >= 2) ? TDInPoint_P(1, uint(pi - 2)) : X1;
	vec3 V = X1 - X0, W = X2 - X1;
	float a = PI / 2.0 * float(k) / float(S);
	vec3 XQ = (X0 + X2 + cos(a) * (-W) + sin(a) * V) / 2.0;

	bool pen = (j == 1) || (TDInPoint_LineBreak(1, uint(pi)) == 1);
	oTDPoint_P[id] = XQ;
	oTDPoint_Alive[id] = (pen && k < S) ? 0 : 1;
	oTDPoint_LineBreak[id] = (pen && k == S) ? 1 : 0;
}
