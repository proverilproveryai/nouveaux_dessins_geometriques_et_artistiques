// fitter/seglen: Ls = (length of the segment ending here, 1 at a strip start)
void main(){
	const uint id = TDIndex(); if (id >= TDNumElements()) return;
	bool start = (id == 0u) || (TDInPoint_LineBreak(0, id) == 1);
	float len = start ? 0.0 : length(TDInPoint_P(0, id).xy - TDInPoint_P(0, id - 1u).xy);
	oTDPoint_Ls[id] = vec2(len, start ? 1.0 : 0.0);
}
