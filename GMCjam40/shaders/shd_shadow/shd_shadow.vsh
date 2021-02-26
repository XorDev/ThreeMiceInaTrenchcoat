struct ATTRIBUTE
{
	float3 pos : POSITION;
};

struct VERTEX
{
	float4 pos : SV_POSITION;
	float  dep : TEXCOORD0;
};

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.pos,1)).z;
    return OUT;
}