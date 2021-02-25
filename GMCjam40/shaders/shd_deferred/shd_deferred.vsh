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

VERTEX main(ATTRIBUTE input)
{
	VERTEX output;
	
    output.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(input.pos,1));
    output.col = float4(1,1,1,1);//input.col;
	output.nor = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(input.nor,0));
    output.tex = input.tex;
	output.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(input.pos,1)).z;
    return output;
}