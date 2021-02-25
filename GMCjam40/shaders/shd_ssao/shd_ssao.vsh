struct ATTRIBUTE
{
	float3 pos : POSITION;
	float2 tex : TEXCOORD0;
};

struct VERTEX
{
	float4 pos : SV_POSITION;
	float2 tex : TEXCOORD0;
};

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
    OUT.tex = IN.tex;
    return OUT;
}