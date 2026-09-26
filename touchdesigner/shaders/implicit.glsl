// NDGA "Dessins implicites", DESSIN 247-250: random walks that stay inside the region F(x,y) < 0.
// Book: pick a seed (random, or a 120x120 grid for 250); if F<0 walk with jittered steps of size DE
// while F stays < 0 (250 also stops at the unit square), plotting every point that is still inside.
// The walk is inherently serial, so ONE thread walks ONE seed and writes all of its Steps+1 slots
// (numthreadsmode = numelems = seeds). Unused slots / seeds starting outside get Alive = 0 (culled).
// Walk length is unbounded in the book; here it is capped by Implicitmax.
// Uniforms: uD, uNS = (seeds, max steps, grid flag), uDE = step size.

#define PI 3.14159265359

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

float F(float X, float Y)
{
	if (uD == 247) { float Z = (2.0 * X - 1.0) * (2.0 * Y - 1.0) * 10.0; return Z - floor(Z) - 0.5; }
	float XX = 2.0 * X - 1.0, YY = 2.0 * Y - 1.0;
	if (uD == 250) YY = 2.0 * Y - 1.5;
	float D1 = (1.0 - XX) * (1.0 - XX) + YY * YY, D2 = (1.0 + XX) * (1.0 + XX) + YY * YY;
	if (uD == 248) return (D1 - floor(D1) - 0.5) * (D2 - floor(D2) - 0.5);
	if (uD == 249) { float Z = 2.0 * D1 * D2; return (Z - floor(Z) - 0.5) * XX * YY; }
	float Z1 = 10.0 * sqrt(XX * XX + YY * YY);
	return (Z1 - floor(Z1) - 0.5) * XX * YY * (XX + YY) * (XX - YY);
}

bool inside(float X, float Y, float f)
{
	if (uD == 250) return f < 0.0 && abs(X - 0.5) < 0.5 && abs(Y - 0.5) < 0.5;
	return f < 0.0;
}

void main()
{
	uint s = gl_GlobalInvocationID.x;
	if (s >= uint(uNS.x))
		return;

	int S = uNS.y;
	uint base = s * uint(S + 1);
	float X, Y;
	if (uNS.z == 1)
	{
		int I = int(float(s) * 14400.0 / float(uNS.x));
		X = float(I / 120) / 120.0; Y = float(I % 120) / 120.0;
	}
	else { X = RND(s, 0u); Y = RND(s, 1u); }

	bool alive = F(X, Y) < 0.0;
	int written = 0;
	for (int t = 0; t <= S; t++)
	{
		uint o = base + uint(t);
		oTDPoint_P[o] = vec3(2.0 * X - 1.0, 2.0 * Y - 1.0, 0.0);
		oTDPoint_LineBreak[o] = (t == 0) ? 1 : 0;
		oTDPoint_Alive[o] = alive ? 1 : 0;
		if (alive) written++;
		if (alive)
		{
			float nx = X + (2.0 * RND(s, 2u + 2u * uint(t)) - 1.0) * uDE;
			float ny = Y + (2.0 * RND(s, 3u + 2u * uint(t)) - 1.0) * uDE;
			X = nx; Y = ny;
			alive = inside(X, Y, F(X, Y));
		}
	}
	// a walk that never left its seed is a lone point (a hot dot on a laser): drop it
	if (written < 2) oTDPoint_Alive[base] = 0;
}
