#define SUN float3(-.48,.36,-.8)
#define AMB_COL float3(.06,.12,.2)

#define LIG_NUM 4
#define LIG_COL float3(2,1,.3)

uniform float4 lig_pos[LIG_NUM];


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
	float3 coo : TEXCOORD2;
	float4 lig : TEXCOORD3;
};

uniform float4x4 lig_mat;

float3 lights(float3 p,float3 n)
{
	float3 col = 0.;
	for(int i = 0;i<LIG_NUM;i++)
	{
		float4 l = lig_pos[i];
		if (l.w<.1) break;
		float3 d = p-l.xyz;
		float t = length(d);
		col += LIG_COL*max(dot(d/t,n),0.)/(.5+t/l.w);
	}
	return col;
}

VERTEX main(ATTRIBUTE IN)
{
	VERTEX OUT;
	float3 wpos = mul(gm_Matrices[MATRIX_WORLD], float4(IN.pos,1)).xyz;
	float3 wnor = normalize(mul(gm_Matrices[MATRIX_WORLD], float4(IN.nor,0)).xyz);
	float3 nor = normalize(mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.nor,0)).xyz);
	float l = min(dot(wnor,SUN)+1.,1.);
	
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(IN.pos,1));
    OUT.col = float4(IN.col.rgb,1);
	OUT.nor = nor;
    OUT.tex = IN.tex;
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(IN.pos,1)).z;
	OUT.coo = mul(lig_mat, float4(IN.pos,1)).xyz;
	OUT.lig = float4(lights(wpos,wnor),l);
    return OUT;
}