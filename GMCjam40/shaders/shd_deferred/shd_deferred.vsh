#define LIGHT float3(0,-.6,-.8)
#define AMB float3(.1,.2,.3)

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
	float4 coo : TEXCOORD2;
};

uniform float4x4 view;

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	float3 wnormal = normalize(mul(gm_Matrices[MATRIX_WORLD], float4(IN.nor,0)).xyz);
	float3 normal = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.nor,0)).xyz;
	float l = dot(wnormal,LIGHT);
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
    OUT.col = float4(IN.col.rgb,1);
	OUT.nor = normal;
    OUT.tex = IN.tex;
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.pos,1)).z;
	OUT.coo = float4(mul(view, float4(IN.pos,1)).xyz,l);
    return OUT;
}