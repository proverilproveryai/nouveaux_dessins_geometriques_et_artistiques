// NDGA "Champs": needles 77-84, threads from random seeds 85-102, threads from a grid 103-122.
// Needles: one 2-point segment of length K at angle AN(x,y) per random point.
// Threads: from each seed, M Euler steps of size K along AN(x,y); the book breaks the line as soon
//          as it leaves the unit square. GPU: thread = (seed, step j) integrates j steps from its own
//          seed (O(M) per thread, fully parallel); points after an exit get Alive = 0 (culled).
// Randomness: RND(i, k) = pcg hash of (Seed, index), optional smooth drift (Random page).
// Uniforms: uD, uNM = (book N, steps M, seeds), uK = (step size, live angle offset).

#define PI 3.14159265359
float SGN(float v) { return v > 0.0 ? 1.0 : (v < 0.0 ? -1.0 : 0.0); }
// book idiom: if (XX!=0) AN=ATN(YY/XX) else PI/2*SGN(YY); if (XX<0) AN+=PI*SGN(YY)
float ANG(float yy, float xx)
{
	float a = (xx != 0.0) ? atan(yy / xx) : PI / 2.0 * SGN(yy);
	if (xx < 0.0) a += PI * SGN(yy);
	return a;
}
// variant without quadrant fix: if (XP!=0) AN=ATN(YP/XP) else PI/2
float ANG0(float yp, float xp) { return (xp != 0.0) ? atan(yp / xp) : PI / 2.0; }

// deterministic random: pcg hash of (seed, index, k); the seed drifts smoothly when uRnd.y animates
uint pcg(uint v) { uint s = v * 747796405u + 2891336453u; uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u; return (w >> 22u) ^ w; }
float rnd0(uint seed, uint i, uint k) { return float(pcg(pcg(pcg(seed) ^ i) ^ (k * 0x9E3779B9u))) / 4294967295.0; }
float RND(uint i, uint k)
{
	float s = uRnd.x + uRnd.y;
	uint s0 = uint(floor(s));
	float f = smoothstep(0.0, 1.0, fract(s));
	return mix(rnd0(s0, i, k), rnd0(s0 + 1u, i, k), f);
}

float needleAngle(int d, float X, float Y)
{
	float XX = 2.0 * X - 1.0, YY = 2.0 * Y - 1.0;
	switch (d)
	{
	case 77: return sin(PI * XX / (abs(YY) + 0.1));
	case 78: return cos(PI * YY);
	case 79: return 2.0 * PI * XX * YY;
	case 80: YY = 4.0 * Y - 2.0; return sin(4.0 * PI * XX) * sin(2.0 * PI * YY);
	case 81: YY = 6.0 * Y - 3.0; return sin(5.0 * PI * XX) * sin(3.0 * PI * YY);
	case 82: { XX = 8.0 * X - 4.0; YY = 8.0 * Y - 4.0; float XP = sin(XX) * sin(YY), YP = cos(XX * YY); return (XP != 0.0) ? atan(YP, XP) : PI / 2.0; }
	case 83: return cos(6.0 * PI * (XX * XX + YY * YY));
	default: return cos(6.0 * PI * (XX * XX - YY * YY)); // 84
	}
}

float threadAngle(int d, float X, float Y)
{
	float XX = 2.0 * X - 1.0, YY = 2.0 * Y - 1.0;
	float AN = cos(6.0 * PI * (YY * YY + XX * XX));      // 85 (default)
	float XP, YP;
	switch (d)
	{
	case 86: AN = cos(4.0 * ANG(YY, XX)); break;
	case 87: AN = PI * cos(2.0 * PI * (abs(XX) + abs(YY))); break;
	case 88: AN = ANG(YY, XX) * 3.0 + XX * YY; break;
	case 89: XX = 8.0 * X - 4.0; YY = 8.0 * Y - 4.0; XP = sqrt(abs(XX)) * sin(YY * YY); YP = sin(2.0 * XX * YY); AN = ANG0(YP, XP); break;
	case 90: AN = ANG(YY, XX) + PI * 0.9 * sin(3.0 * PI * sqrt(XX * XX + YY * YY)); break;
	case 91: AN = ANG(YY, XX) + PI + sin(4.0 * PI * sqrt(2.0 * XX * XX + YY * YY)) * 8.0; break;
	case 92: AN = ANG(YY, XX) + 4.0 * PI / 3.0 + sin(6.0 * PI * sqrt(XX * XX + YY * YY)) / 4.0; break;
	case 93: XX = 2.0 * X - floor(2.0 * X); YY = 2.0 * Y - floor(2.0 * Y); XX = 2.0 * XX - 1.0; YY = 2.0 * YY - 1.0;
	         AN = ANG(YY, XX) + 4.0 * PI / 3.0 + sin(6.0 * PI * sqrt(XX * XX + YY * YY)) / 4.0; break;
	case 94: AN = ANG(YY, XX) + PI / 5.0; break;
	case 95: AN = ANG(YY, XX) + PI / 2.0 - 0.2; break;
	case 96: AN = ANG(YY, XX) + PI / 3.0 + sin(4.0 * PI * sqrt(XX * XX + YY * YY)) / 3.0; break;
	case 97: { XX = 10.0 * X - 5.0; YY = 10.0 * Y - 5.0; float DG = XX * XX + YY * YY; XP = (DG - 1.0) * (DG - 9.0); YP = DG - 4.0;
	         AN = (XX != 0.0) ? atan(YP / XP) : PI / 2.0; break; }
	case 98: case 99: case 101: {
		int P8 = 1; float x = X, y = Y;
		if (d == 99) { while (P8 < 8 && int(2.0 * y) == 0) { x = 2.0 * x - floor(2.0 * x); y = 2.0 * y - floor(2.0 * y); P8++; } }
		else { while (P8 < 5 && (int(2.0 * y) + int(2.0 * x) == 1)) { x = 2.0 * x - floor(2.0 * x); y = 2.0 * y - floor(2.0 * y); P8++; } }
		XX = 2.0 * x - 1.0; YY = 2.0 * y - 1.0;
		float a = ANG(YY, XX);
		if (d == 98) AN = 7.0 * a;
		else if (d == 99) AN = a + 4.0 * PI / 3.0 + sin(6.0 * PI * sqrt(XX * XX + YY * YY)) / 4.0;
		else AN = a + XX + YY;
		break; }
	case 100: AN = 2.0 * PI * sin(2.0 * PI * XX * YY); break;
	case 102: AN = ANG(YY, XX) + PI / 2.0 * sin(4.0 * PI * sqrt(3.0 * XX * XX + YY * YY)); break;

	// ---- regular threads 103-122 ----
	default: {
		if (d == 109) { XX = 2.0 * X - floor(2.0 * X); YY = 3.0 * Y - floor(3.0 * Y); XX = 2.0 * XX - 1.0; YY = 2.0 * YY - 1.0; }
		else if (d == 110 || d == 122) { XX = 3.0 * X - floor(3.0 * X); YY = 3.0 * Y - floor(3.0 * Y); XX = 2.0 * XX - 1.0; YY = 2.0 * YY - 1.0; }
		else if (d == 111) { XX = 2.0 * X - 0.5; YY = 2.0 * Y - 1.0; XP = abs(XX * XX - YY * YY) * 2.0; XP = XP - floor(XP); YP = sin(XX + YY); }
		else if (d == 112) { XX = X * Y - floor(X * Y); YY = X + Y - floor(X + Y); XX = 2.0 * XX - 1.0; YY = 2.0 * YY - 1.0; }
		else if (d == 113) { XX = X * X - floor(X * X); YY = Y * Y - floor(Y * Y); XX = 2.0 * XX - 1.0; YY = 2.0 * YY - 1.0; }
		else if (d == 114) { XX = 4.0 * X - 2.0; YY = 4.0 * Y - 2.0; XP = YY * (YY * YY - 1.0); YP = sin(XX + YY); }
		else if (d == 116) { XX = 12.0 * X - 6.0; YY = 12.0 * Y - 6.0; XP = sin(XX * XX + YY); YP = sin(XX * YY); }
		AN = ANG(YY, XX);
		float r2 = XX * XX + YY * YY;
		if (d == 103) AN = 5.0 * AN;
		else if (d == 104) AN = AN * 5.0 * r2;
		else if (d == 105) AN = PI * sin(2.0 * PI * XX) + PI * sin(2.0 * PI * YY) + r2 / 5.0;
		else if (d == 106 || d == 107) AN = AN * 6.0 * (abs(XX) + abs(YY));
		else if (d == 108) AN = PI / 2.0 * sin(6.0 * PI * XX) + PI / 2.0 * sin(6.0 * PI * YY);
		else if (d == 109) AN = AN + PI + sin(2.0 * PI * sqrt(r2)) / 2.0;
		else if (d == 110) AN = 7.0 * AN;
		else if (d == 111 || d == 114 || d == 116) AN = ANG(YP, XP);
		else if (d == 112) AN = AN + PI + sin(2.0 * PI * sqrt(XX * XX + 2.0 * YY * YY)) / 2.0;
		else if (d == 113) AN = 3.0 * AN;
		else if (d == 115) AN = 8.0 * AN;
		else if (d == 117) AN = abs(sin(2.0 * PI * XX) + sin(2.0 * PI * YY));
		else if (d == 118) AN = 5.0 * AN * AN * AN * AN * AN;   // JS pow() keeps the sign for odd powers, GLSL pow() does not
		else if (d == 119) AN = AN / (abs(XX) + 0.01);
		else if (d == 120) AN = AN + PI + sin(4.0 * PI * sqrt(3.0 * XX * XX + YY * YY)) * 1.3;
		else if (d == 121 || d == 122) AN = AN + PI + sin(2.0 * PI * sqrt(r2)) * 3.0;
		break; }
	}
	return AN;
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int steps = uNM.y;
	int s = int(id) / (steps + 1);
	int j = int(id) % (steps + 1);
	float K = uK.x;
	int alive = 1;
	vec2 P;

	if (uD <= 84)
	{
		float X = RND(uint(s), 0u), Y = RND(uint(s), 1u);
		float AN = needleAngle(uD, X, Y) + uK.y;
		vec2 q = (j == 0) ? vec2(X, Y) : vec2(X, Y) + K * vec2(cos(AN), sin(AN));
		P = (K + q) / (1.0 + 2.0 * K);
	}
	else
	{
		float X, Y;
		if (uD <= 102) { X = RND(uint(s), 0u); Y = RND(uint(s), 1u); }
		else { int N = uNM.x; X = float(s / (N + 1)) / float(N); Y = float(s % (N + 1)) / float(N); }
		for (int t = 0; t < j; t++)
		{
			float AN = threadAngle(uD, X, Y) + uK.y;
			X += K * cos(AN); Y += K * sin(AN);
			if (!(X > 0.0 && X < 1.0 && Y > 0.0 && Y < 1.0)) { alive = 0; break; }
		}
		P = vec2(X, Y);
		if (j == 0)
		{
			// a seed whose very first step leaves the square is a lone point (a hot dot on a laser): drop it
			float AN = threadAngle(uD, X, Y) + uK.y;
			vec2 q = vec2(X, Y) + K * vec2(cos(AN), sin(AN));
			if (!(q.x > 0.0 && q.x < 1.0 && q.y > 0.0 && q.y < 1.0)) alive = 0;
		}
	}

	oTDPoint_P[id] = vec3(2.0 * P - 1.0, 0.0);
	oTDPoint_LineBreak[id] = (j == 0) ? 1 : 0;
	oTDPoint_Alive[id] = alive;
}
