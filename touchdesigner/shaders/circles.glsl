// NDGA "Grilles de cercles", DESSIN 251-266: one circle per cell of an (N+1)^2 grid,
// radius proportional to a scalar field F(x,y) chosen by DESSIN.
// Book draws R+1 points where R is the radius in plotter pixels; here every circle gets a
// fixed Seg+1 points (closed strip) so every circle has uniform sampling.
// Uniforms: uD dessin, uGS = (N grid, Seg), uRR = cell radius factor, uField = (pan x, pan y, phase)
// The phase is added inside the fract() terms (Z - floor(Z)) and animates the field bands.

#define PI 3.14159265359

float fr(float z) { return fract(z + uField.z); }

float field(float X, float Y)
{
	float XX = 2.0 * X - 1.0 + uField.x, YY = 2.0 * Y - 1.0 + uField.y;
	float F = 0.0;
	switch (uD)
	{
	case 252: F = abs(XX * XX + YY * YY - 1.0); break;
	case 253: F = fr(3.0 * XX * YY / (1.0 + 3.0 * sqrt(XX * XX + YY * YY))); break;
	case 254: { float DI = XX * XX + YY * YY; if (DI != 0.0) XX = XX / DI; F = abs(fr(XX)); break; }
	case 255: { float xx = fract(3.0 * X), yy = fract(3.0 * Y); xx = 2.0 * xx - 1.0; yy = 2.0 * yy - 1.0; F = 0.5 * (xx * xx + yy * yy); break; }
	case 256: F = fr(3.0 * XX - 4.0 * YY * YY); break;
	case 257: {
		float xx = X, yy = Y, AA, BB; int LL = 0;
		do { LL++; AA = floor(2.0 * xx); BB = floor(2.0 * yy); xx = 2.0 * xx - AA; yy = 2.0 * yy - BB; }
		while (AA != BB && LL < 5);
		F = 1.0 - 2.0 * ((xx - 0.5) * (xx - 0.5) + (yy - 0.5) * (yy - 0.5)); F = F * F; break; }
	case 258: F = fr(10.0 * (XX * XX + 5.0 * YY * YY)) * fr(10.0 * (5.0 * XX * XX + YY * YY)); break;
	case 259: {
		float DI = XX * XX + YY * YY; if (DI != 0.0) { XX = 2.0 * XX / DI; YY = 2.0 * YY / DI; }
		XX = 2.0 * abs(fr(XX) - 0.5); YY = 2.0 * abs(fr(YY) - 0.5);
		F = floor(1.95 * sqrt(XX * YY)); break; }
	case 260: F = fr(5.0 * (XX * XX + 10.0 * YY * YY)) * fr(5.0 * (10.0 * XX * XX + YY * YY)); break;
	case 261: {
		float xx = abs(XX), yy = abs(YY); float DI = xx * xx + yy * yy;
		if (DI != 0.0) { xx = xx / DI; yy = yy / DI; }
		F = sqrt(fr(xx) * fr(yy)); break; }
	case 262: {
		float xx = 1.5 * XX, yy = 2.0 * YY; float DI = xx * xx + yy * yy;
		F = sqrt(fr(xx * DI) * fr(yy * DI)); break; }
	case 263: F = fr(4.0 * sqrt(XX * XX + YY * YY) * abs(3.0 * XX)); break;
	case 264: F = fr(50.0 * XX * YY); break;
	case 265: F = fr(10.0 * (XX * XX + 10.0 * YY * YY)) * fr(10.0 * (10.0 * XX * XX + YY * YY)); break;
	case 266: F = abs(fr(5.0 * (XX * XX - 10.0 * YY * YY)) * fr(5.0 * (10.0 * XX * XX - YY * YY))); break;
	default:  F = abs(XX) * abs(YY); break; // 251
	}
	return F;
}

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int N = uGS.x, S = uGS.y;
	int cell = int(id) / (S + 1);
	int l = int(id) % (S + 1);
	int I = cell / (N + 1), J = cell % (N + 1);
	float X = float(I) / float(N), Y = float(J) / float(N);
	float RR = uRR;

	float F = field(X, Y);
	vec2 c = vec2(RR + (1.0 - 2.0 * RR) * X, RR + (1.0 - 2.0 * RR) * Y);
	float r = RR * (1.0 - 2.0 * RR) * F + 1.0 / 480.0;   // book: int(RR(1-2RR) F NP) + 1 px
	float an = 2.0 * PI * float(l) / float(S);
	vec2 p = c + r * vec2(cos(an), sin(an));

	oTDPoint_P[id] = vec3(2.0 * p - 1.0, 0.0);
	oTDPoint_LineBreak[id] = (l == 0) ? 1 : 0;
}
