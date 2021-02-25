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
	float3 coo : TEXCOORD4;
};

uniform float4x4 view;

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	float3 wnormal = normalize(mul(gm_Matrices[MATRIX_WORLD], float4(IN.nor,0)).xyz);
	float3 normal = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.nor,0)).xyz;
	float l = max(dot(wnormal,-float3(1,-3,-5)/sqrt(35.)),0.);
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
    OUT.col = float4(IN.col.rgb*lerp(AMB,1.,l),1);
	OUT.nor = normal;
    OUT.tex = IN.tex;
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.pos,1)).z;
	OUT.coo = mul(view, float4(IN.pos,1)).xyz;
    return OUT;
}