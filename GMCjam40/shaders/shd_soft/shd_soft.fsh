//MIN is the z-near clipping distance.
#define MIN 1.
//MIN is the z-far clipping distance.
#define MAX 65025.
//Screen resolution
#define RATIO RES.x/RES.y
#define SAM RES.z
#define RAD 4.
#define D (.5625)

uniform float3 RES;

Texture2D	 tdep : register(t1);
SamplerState sdep : register(s1);

struct VERTEX
{
	float4 pos : SV_POSITION;
	float2 tex : TEXCOORD0;
};


struct PIXEL
{
	float4 col : COLOR0;
};


float unpack_depth(float4 samp)
{
	float z = dot(samp,1./float4(1,255,65025,16581375));
	
	return z*(MAX-MIN)+MIN;
}
float2 hash2(float2 p)
{
	return normalize(frac(cos(mul(p,float2x2(194.55,-269.38,-189.27,278.69)))*825.79)-.5);
}

PIXEL main(VERTEX IN) : SV_TARGET
{
	float4 soft = 0.;//gm_BaseTextureObject.Sample(gm_BaseTexture,IN.tex);
    float4 depthRGBA = tdep.Sample(sdep,IN.tex);
	
	float depth = unpack_depth(depthRGBA);
	
	float3 pos = float3(IN.tex-.5,1)*float3(RATIO/D,1./D,1)*depth;
	float o = 0.;
	
	float s = RAD/SAM;//*depth/RES.x/32.;
	float2 r = hash2(IN.tex)*s;
	float2x2 g = float2x2(.73736882209777832,-.67549037933349609,.67549037933349609,.73736882209777832);
	
	for(float i = 1.;i<=SAM;i++)
	{
		r = mul(r,g);
		float2 u = IN.tex + r*i/RES.xy;
		float2 b = step(abs(u-.5),.5);
		
		float d = unpack_depth(tdep.Sample(sdep,u));
		float3 p = float3(u-.5,1)*float3(RATIO/D,1./D,1)*d-pos;
		float l = length(p);
		
		soft += gm_BaseTextureObject.Sample(gm_BaseTexture,u)*rsqrt(l/i);
	}
	
	PIXEL OUT;
	OUT.col = pow(soft/soft.a,.7)*1.2;
    return OUT;
}