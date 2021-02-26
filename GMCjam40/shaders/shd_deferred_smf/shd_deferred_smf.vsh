#define SUN float3(-.48,-.36,-.8)
#define AMB_COL float3(.06,.12,.2)

struct ATTRIBUTE
{
	float4 col0 : COLOR0;
	float4 col1 : COLOR1;
	float4 col2 : COLOR2;
	float3 pos : POSITION;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
};

struct VERTEX
{
	float4 pos : SV_POSITION;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
	float  dep : TEXCOORD1;
	float3 coo : TEXCOORD2;
	float  lig : TEXCOORD3;
};

uniform float4x4 lig_mat;

static const int maxBones = 32;
uniform float4 u_boneDQ[2*maxBones];

float3 anim_rotate(float3 v, float4 b)
{
	return v + 2. * cross(b.xyz, cross(b.xyz, v) + b.w * v);
}
float3 anim_transform(float3 v, float4 b, float3 t)
{
	return anim_rotate(v,b) + t;
}

VERTEX main(ATTRIBUTE IN)
{
	int4 bone = int4(IN.col1 * 510.);
	float4 weight = IN.col2;
	
	float4 blendReal, blendDual;
	float3 blendTranslation;
	
	blendReal  =  u_boneDQ[bone[0]]   * weight[0] + u_boneDQ[bone[1]]   * weight[1] + u_boneDQ[bone[2]]   * weight[2] + u_boneDQ[bone[3]]   * weight[3];
	blendDual  =  u_boneDQ[bone[0]+1] * weight[0] + u_boneDQ[bone[1]+1] * weight[1] + u_boneDQ[bone[2]+1] * weight[2] + u_boneDQ[bone[3]+1] * weight[3];
	//Normalize resulting dual quaternion
	float blendNormReal = 1.0 / length(blendReal);
	blendReal *= blendNormReal;
	blendDual = (blendDual - blendReal * dot(blendReal, blendDual)) * blendNormReal;
	blendTranslation = 2. * (blendReal.w * blendDual.xyz - blendDual.w * blendReal.xyz + cross(blendReal.xyz, blendDual.xyz));
	
	float3 apos = anim_transform(IN.pos,blendReal,blendTranslation);
	float3 anor = anim_rotate(IN.nor,blendReal);
	
	float3 wpos = mul(gm_Matrices[MATRIX_WORLD], float4(apos,1)).xyz;
	float3 wnor = normalize(mul(gm_Matrices[MATRIX_WORLD], float4(anor,0)).xyz);
	float3 nor = normalize(mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(anor,0)).xyz);
	float l = min(dot(wnor,SUN)+1.,1.);
	
	VERTEX OUT;
    OUT.pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], float4(apos,1));
	OUT.nor = nor;
    OUT.tex = IN.tex;
	OUT.dep = mul(gm_Matrices[MATRIX_WORLD_VIEW], float4(apos,1)).z;
	OUT.coo = mul(lig_mat, float4(wpos,1)).xyz;
	OUT.lig = l;
    return OUT;
}