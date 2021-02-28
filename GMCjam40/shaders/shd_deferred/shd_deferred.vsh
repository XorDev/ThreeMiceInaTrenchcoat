#define SUN float3(-.48,-.36,-.8)

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
	float3 dep : TEXCOORD1;
	float3 coo : TEXCOORD2;
	float  lig : TEXCOORD3;
};

uniform float4x4 lig_mat;

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	float3 wpos = mul(gm_Matrices[MATRIX_WORLD], float4(IN.pos,1)).xyz;
	float3 wnor = normalize(mul(gm_Matrices[MATRIX_WORLD], float4(IN.nor,0)).xyz);
	float3 vnor = normalize(mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.nor,0)).xyz);
	float l = min(dot(wnor,SUN)+1.,1.);
	float f = clamp(IN.pos.z/128.+1.,0.,1.);
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
    OUT.col = float4(IN.col.rgb*f,1);
	OUT.nor = vnor;
    OUT.tex = IN.tex;
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.pos,1)).xyz;
	OUT.coo = mul(lig_mat, float4(wpos,1)).xyz;
	OUT.lig = l;
    return OUT;
}