// NDGA hand-drawn glyphs: "Des centaines de visages" 21-29 and "Multitudes" 287-300.
// Input 1 (data_pop, from the `data` table) holds every stroke point of every glyph:
//   G = (x, y)   Gi = (set, part, variant, pen)   set 0 = face parts (x,y already in book [0,1] units),
//   set 1 = crowd glyphs (x,y in glyph units, book DATA/10).
// Thread = (instance, table row). A row is Alive only if it belongs to the glyph this instance draws;
// the rest is culled, so one fixed dispatch serves every DESSIN.
// Faces: part 0..3 = mouth / nose / eyes / outline, variant 1..5 = uSel (B, N, O, V); 29 = 5x5 grid of O x V.
// Crowds: position / angle / size T / jitter V per instance, formulas of DESSIN 287-300, randomness hashed.
// Live: uLive = (size x, jitter x, sway phase).

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

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int R = uIG.y;
	int inst = int(id) / R;
	int r = int(id) % R;
	vec2 g = TDInPoint_G(1, uint(r));
	ivec4 gi = TDInPoint_Gi(1, uint(r));
	int alive = 0;
	vec2 p = vec2(0.0);

	if (uD <= 29)
	{
		ivec4 sel = uSel;
		vec2 off = vec2(0.0); float sc = 1.0;
		if (uD == 29) { int O = inst / 5 + 1, V = inst % 5 + 1; sel.z = O; sel.w = V; sc = 0.2; off = vec2(float(V - 1), float(O - 1)) / 5.0; }
		alive = (gi.x == 0 && gi.z == sel[gi.y]) ? 1 : 0;
		vec2 c = vec2(0.5);
		p = 2.0 * ((g - c) * uLive.x + c) * sc + 2.0 * off - 1.0;   // book: NP*(E+10)/120, NP*F/120 (/5 + offset for 29)
	}
	else
	{
		alive = (gi.x == 1 && gi.y == uIG.z) ? 1 : 0;
		uint I = uint(inst);
		float fi = float(inst + 1);               // book loop I = 1..N
		float N = float(uIG.x);
		float T = 0.1, X = 0.0, Y = 0.0, A = 0.0, V = 0.0;
		switch (uD)
		{
		case 287: T = 0.3; X = (1.0 - T) * (2.0 * RND(I, 0u) - 1.0); Y = (1.0 - T) * (2.0 * RND(I, 1u) - 1.0); A = 2.0 * PI * RND(I, 2u); break;
		case 288: T = 0.1; X = (1.0 - T) * (2.0 * RND(I, 0u) - 1.0); Y = (1.0 - T) * (2.0 * RND(I, 1u) - 1.0); A = 2.0 * PI * RND(I, 2u); break;
		case 289: T = 0.05; X = (1.0 - T) * (2.0 * float((inst) % 20) / 20.0 - 1.0); Y = (1.0 - T) * (2.0 * float(inst / 20) / 20.0 - 1.0); A = 2.0 * PI * (X + Y) / 5.0; break;
		case 290: T = 0.055; X = (1.0 - T) * (2.0 * float(inst % 15) / 15.0 - 1.0) + 0.05 * RND(I, 0u); Y = (1.0 - T) * (2.0 * float(inst / 15) / 15.0 - 1.0) + 0.05 * RND(I, 1u); A = 2.0 * PI * (X * X + Y) / 2.0; break;
		case 291: T = 0.1 * RND(I, 0u); X = (1.0 - T) * (2.0 * RND(I, 1u) - 1.0); Y = (1.0 - T) * (2.0 * RND(I, 2u) - 1.0); A = 2.0 * PI * (X + Y) / 6.0; break;
		case 292: { float Rr = 1.0 - fi / 200.0, W = 7.0 * fi / 20.0; T = Rr / 15.0; X = Rr * cos(W); Y = Rr * sin(W); A = W; break; }
		case 293: { float Rr = 1.0 - fi / 200.0, W = 2.0 * PI * fi / 40.0 + 0.1; T = Rr / 10.0; X = Rr * cos(W); Y = Rr * sin(W); A = W; break; }
		case 294: { float W = 2.0 * PI * fi / 100.0 + 0.1; T = 0.1; X = 0.8 * cos(W); Y = 0.8 * sin(2.0 * W); A = W; break; }
		case 295: T = 0.1; X = (1.0 - 2.0 * T) * (2.0 * float(inst % 10) / 9.0 - 1.0); Y = (1.0 - T) * (2.0 * float(inst / 10) / 9.0 - 1.0); A = PI * (X * X + Y * Y); break;
		case 296: T = 0.05; X = (1.0 - 2.0 * T) * (2.0 * float(inst % 20) / 19.0 - 1.0); Y = (1.0 - T) * (2.0 * float(inst / 20) / 19.0 - 1.0); A = PI * (X * X + Y * Y); break;
		case 297: T = 0.1; X = (1.0 - 2.0 * T) * (2.0 * float(inst % 20) / 19.0 - 1.0); Y = -(1.0 - T) * (2.0 * float(inst / 20) / 19.0 - 1.0); A = 0.0; V = X * X + Y * Y; break;
		case 298: T = 0.15 * (1.0 + (2.0 * RND(I, 0u) - 1.0) / 3.0); X = (1.0 - 2.0 * T) * (2.0 * RND(I, 1u) - 1.0); Y = (1.0 - 2.0 * T) * (2.0 * RND(I, 2u) - 1.0);
		          T = T * (1.0 - (Y / 2.0 + 0.5)); A = PI / 20.0 * (2.0 * RND(I, 3u) - 1.0); V = 0.1; break;
		case 299: { T = 0.08 * (1.0 + (2.0 * RND(I, 0u) - 1.0) / 3.0); float W = 2.0 * PI * fi / N * 10.0, Rr = 1.0 - fi / N; X = Rr * cos(W); Y = Rr * sin(W);
		          A = PI / 50.0 * (2.0 * RND(I, 1u) - 1.0); V = 0.1; break; }
		default: T = 0.07 * (1.0 + (2.0 * RND(I, 0u) - 1.0) / 3.0); X = (1.0 - 2.0 * T) * (2.0 * float(inst % 20) / 19.0 - 1.0); Y = -(1.0 - 2.0 * T) * (2.0 * float(inst / 12) / 11.0 - 1.0);
		          A = PI / 20.0 * (2.0 * RND(I, 1u) - 1.0); V = 0.05; break;  // 300
		}
		if (uLive.z != 0.0) A += 0.3 * sin(uLive.z + 0.37 * float(inst));
		T *= uLive.x;
		V *= uLive.y;
		uint vk = uint(r) * 2u + 10u;
		float X1 = (g.x + V * (RND(I, vk) * 2.0 - 1.0)) * T;
		float Y1 = (g.y + V * (RND(I, vk + 1u) * 2.0 - 1.0)) * T;
		float CO = cos(A), SI = sin(A);
		p = vec2(X1 * CO - Y1 * SI + X, X1 * SI + Y1 * CO + Y);   // book: NP/2 (X2 + 1)
	}

	oTDPoint_P[id] = vec3(p, 0.0);
	oTDPoint_LineBreak[id] = gi.w;
	oTDPoint_Alive[id] = alive;
}
