Texture2D	 tsha : register(t2);
SamplerState ssha : register(s2);

struct VERTEX
{
	float4 pos : SV_POSITION;
	float4 col : COLOR0;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
	float  dep : TEXCOORD1;
	float3 coo : TEXCOORD4;
};

struct PIXEL
{
	float4 col : COLOR0;
	float4 dep : COLOR1;
	float4 nor : COLOR2;
};

//MIN is the z-near clipping distance.
#define MIN 1.
//MIN is the z-far clipping distance.
#define MAX 65025.
#define RES float2(1024,1024)

float4 pack_depth(float z)
{
	//Calculate the depth values in between the given MIN/MAX range.
	float depth = clamp((z-MIN)/(MAX-MIN),0.,1.);
	
	//Encode the final color while taking advantage of the RGB channels.
	return frac(floor(depth*float4(1,255,65025,16581375)*255.)/255.);
}
float unpack_depth(float4 samp)
{
	float z = dot(samp,1./float4(1,255,65025,16581375));
	
	return z*(MAX-MIN)+MIN;
}
float2 hash2(float2 p)
{
	return frac(cos(mul(p,float2x2(94.55,-69.38,-89.27,78.69)))*825.79)-.5;
}

PIXEL main(VERTEX IN) : SV_TARGET
{
    float4 sample = gm_BaseTextureObject.Sample(gm_BaseTexture,IN.tex);
	float2 h = 0.;//hash2(IN.coo.xy);
	float2 u = IN.coo.xy/IN.coo.z*float2(.5,-.5)+.5+h/RES;
	float2 b = smoothstep(.5,.4,abs(u-.5));
	float4 shadeRGBA = tsha.Sample(ssha,u);
	float depth = unpack_depth(shadeRGBA)-IN.coo.z;
	float3 c = lerp(1.,float3(.1,.2,.3),step(depth,-.5)*b.x*b.y);
	sample.rgb *= c;
	//if (sample.a<0.5) discard;	
	
	PIXEL OUT;
	OUT.col = IN.col  * sample;
	OUT.dep = pack_depth(IN.dep);
	OUT.nor = float4(.5+.5*IN.nor,1);
    return OUT;
}