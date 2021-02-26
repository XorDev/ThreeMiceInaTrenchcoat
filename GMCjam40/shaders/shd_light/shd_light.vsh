uniform float2 RES;//w,h

struct ATTRIBUTE
{
	float3 pos : POSITION;
	float4 col : COLOR0;
};

struct VERTEX
{
	float4 pos : SV_POSITION;
	float4 col : COLOR0;
	float2 tex : TEXCOORD0;
	float  rat : TEXCOORD2;
};

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
	OUT.col = IN.col;
    OUT.tex = IN.pos.xy/RES;
	OUT.rat = RES.x/RES.y;
    return OUT;
}