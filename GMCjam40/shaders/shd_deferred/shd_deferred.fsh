Texture2D	 tsha : register(t1);
SamplerState ssha : register(s1);

#define AMB float3(.1,.2,.3)

struct VERTEX
{
	float4 pos : SV_POSITION;
	float4 col : COLOR0;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
	float  dep : TEXCOORD1;
	float4 coo : TEXCOORD2;
};

struct PIXEL
{
	float4 col : COLOR0;
	float4 dep : COLOR1;
	float4 nor : COLOR2;
	float4 buf : COLOR3;
};

//MIN is the z-near clipping distance.
#define MIN 1.
//MIN is the z-far clipping distance.
#define MAX 65025.
#define RES float2(2048,2048)

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
float hard(float2 u,float d)
{
	float4 shadeRGBA = tsha.Sample(ssha,u);
	return step(.1,d-unpack_depth(shadeRGBA));
}
float soft(float2 u,float d)
{
	float3 o = float3(1./RES,0.);
	float2 f = floor(u*RES)/RES;
	float2 s = frac(u*RES);
	
	float h1 = hard(f+o.zz,d);
	float h2 = hard(f+o.xz,d);
	float h3 = hard(f+o.zy,d);
	float h4 = hard(f+o.xy,d);
	return lerp(lerp(h1,h2,s.x),lerp(h3,h4,s.x),s.y);
}
PIXEL main(VERTEX IN) : SV_TARGET
{
	float4 sample = gm_BaseTextureObject.Sample(gm_BaseTexture,IN.tex);
	float2 u = IN.coo.xy/IN.coo.z*float2(.5,-.5)+.5;
	float2 b = smoothstep(.5,.4,abs(u-.5));
	
	float3 c = lerp(1.,AMB,max(soft(u,IN.coo.z)*b.x*b.y,min(IN.coo.w+1.,1.)));
	//sample.rgb *= c;
	//if (sample.a<0.5) discard;	
	
	PIXEL OUT;
	OUT.col = IN.col*sample;
	OUT.dep = pack_depth(IN.dep);
	OUT.nor = float4(.5+.5*IN.nor,1);
	OUT.buf = float4(c,1);
    return OUT;
}