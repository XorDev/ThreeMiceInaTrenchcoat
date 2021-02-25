struct ATTRIBUTE
{
	float4 col : COLOR0;
	float3 pos : POSITION;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
};

struct VERTEX
{
	float4 pos : SV_POSITION;
	float4 col : COLOR0;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
	float  dep : TEXCOORD1;
};

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	float3 normal = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.nor,0));
	float l = 1.;//max(dot(normal,float3(1,2,2)/3.)*.5+.5,0.);
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
    OUT.col = float4(l,l,l,1);//IN.col;
	OUT.nor = normal;
    OUT.tex = IN.tex;
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.pos,1)).z;
    return OUT;
}