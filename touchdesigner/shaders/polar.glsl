// NDGA polar curves, DESSIN 30-59 (Delahaye 1985, after v3ga p5.js port)
// One thread per output point. Points are laid out curve by curve:
//   id -> (q = curve index, i = point on curve). LineBreak=1 starts a new strip (the plotter "M").
// 30-49: one open curve of N points (TRACE2).  50-59: Q closed curves, N+1 points each (TRACE).
// uDepth scales the modulation terms (1 = book). uPhase is added inside the modulation
// sines only (S/C helpers), so the base winding stays intact and closed curves stay closed.
// Output space: x,y in [-1,1], y-up (book: NP/2*(1+X)).

#define PI 3.14159265359

float S(float x) { return sin(x + uPhase); }
float C(float x) { return cos(x + uPhase); }

void main()
{
	const uint id = TDIndex();
	if (id >= TDNumElements())
		return;

	int N = uNQC.x;
	int ppc = N + uNQC.z;
	int q = int(id) / ppc;
	int i = int(id) % ppc;
	float Q = float(q + 1);
	float T = float(i) / float(N);
	float k = uDepth;

	float A = 2.0 * PI * T;
	float R = T;

	switch (uD)
	{
	case 31: A = 20.0 * PI * T; R = exp(-10.0 * T); break;
	case 32: A = 10.0 * PI * T; R = exp(-10.0 * T); break;
	case 33: A = 10.0 * PI * T; R = T; break;
	case 34: A = 2.0 * PI * (1.0 + k * C(2.0 * PI * T)); R = 0.5 * (1.0 + k * S(2.0 * PI * T)); break;
	case 35: A = PI * k * S(2.0 * PI * T); R = T; break;
	case 36: A = PI * k * S(6.0 * PI * T); R = T; break;
	case 37: A = PI * k * S(12.0 * PI * T) * sin(PI * T); R = T; break;
	case 38: A = (3.0 * PI / 4.0) * k * S(30.0 * PI * T) * sin(PI * T); R = T; break;
	case 39: A = (3.0 * PI / 2.0) * k * S(50.0 * PI * T) * sin(PI * T); R = T * T; break;
	case 40: R = 0.5 * (1.0 + k * S(50.0 * PI * T) * sin(2.0 * PI * T)); break;
	case 41: R = 0.5 * (1.0 + k * S(50.0 * PI * T) * sin(4.0 * PI * T)); break;
	case 42: A = 6.0 * PI * T; R = (1.0 - T) * 0.5 * (1.5 + k * 0.5 * S(200.0 * PI * T) * sin(8.0 * PI * T)); break;
	case 43: R = 0.5 * (1.2 + k * 0.8 * S(200.0 * PI * T) * sin(6.0 * PI * T)); break;
	case 44: R = 0.5 * (0.8 + k * 1.2 * S(100.0 * PI * T) * sin(3.0 * PI * T)); break;
	case 45: R = 0.5 * (0.6 + k * 1.4 * S(100.0 * PI * T) * sin(8.0 * PI * T)); break;
	case 46: R = 0.5 * (1.2 + k * 0.8 * S(300.0 * PI * T) * sin(30.0 * PI * T) * sin(3.0 * PI * T)); break;
	case 47: R = 0.5 * (1.2 + k * 0.8 * S(300.0 * PI * T) * sin(16.0 * PI * T) * sin(4.0 * PI * T)); break;
	case 48: A = 2.0 * PI * T + k * sin(12.0 * PI * T) / 3.0; R = 0.5 * (1.0 + k * S(360.0 * PI * T) * sin(12.0 * PI * T)); break;
	case 49: A = 2.0 * PI * T + k * sin(16.0 * PI * T); R = 0.5 * (1.1 + k * 0.9 * S(360.0 * PI * T) * sin(8.0 * PI * T)); break;

	case 50: A = 2.0 * PI * (1.0 + (Q / 20.0) * k * C(4.0 * PI * T)); R = 0.5 * (1.0 + (Q / 20.0) * k * S(2.0 * PI * T)); break;
	case 51: A = PI * (1.0 + (Q / 10.0) * k * C(2.0 * PI * T)); R = 0.5 * (1.0 + (Q / 10.0) * k * S(2.0 * PI * T)); break;
	case 52: A = 2.0 * PI * (1.0 + (Q / 20.0) * k * C(4.0 * PI * T)); R = 0.5 * (1.0 + (Q / 20.0) * k * S(4.0 * PI * T)); break;
	case 53: A = 2.0 * PI * T + (PI / 6.0) * Q / 15.0; R = 0.5 * (1.4 + k * 0.6 * C(12.0 * PI * T) * cos(4.0 * PI * T)) * pow(0.9, Q); break;
	case 54: R = 0.5 * (1.1 + k * 0.9 * C(16.0 * PI * T) * cos(4.0 * PI * T)) * pow(0.8, Q); break;
	case 55: A = 2.0 * PI * T + (PI / 2.0) * Q / 15.0; R = 0.5 * (0.5 + k * 1.5 * C(16.0 * PI * T)) * pow(0.85, Q); break;
	case 56: R = 0.5 * (1.2 + k * 0.8 * C(50.0 * PI * T) * cos(8.0 * PI * T)) * pow(0.85, Q); break;
	case 57: A = 2.0 * PI * T + (PI / 6.0) * Q / 15.0; R = 0.5 * (1.3 + k * 0.7 * C(24.0 * PI * T) * cos(4.0 * PI * T)) * pow(0.9, Q); break;
	case 58: R = 0.5 * (1.6 + k * 0.4 * C(36.0 * PI * T) * cos(6.0 * PI * T)) * pow(0.95, Q); break;
	case 59: R = 0.5 * (1.2 + k * 0.8 * C(150.0 * PI * T) * cos(6.0 * PI * T)) * pow(0.75, Q); break;
	default: break; // 30: A = 2 PI T, R = T
	}

	oTDPoint_P[id] = vec3(R * cos(A), R * sin(A), 0.0);
	oTDPoint_LineBreak[id] = (i == 0) ? 1 : 0;
}
