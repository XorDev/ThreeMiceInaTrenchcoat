struct VERTEX
{
	float4 pos : SV_POSITION;
	float4 col : COLOR0;
	float3 nor : NORMAL;
	float2 tex : TEXCOORD0;
	float  dep : TEXCOORD1;
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

float4 pack_depth(float z)
{
	//Calculate the depth values in between the given MIN/MAX range.
	float depth = clamp((z-MIN)/(MAX-MIN),0.,1.);
	
	//Encode the final color while taking advantage of the RGB channels.
	return frac(floor(depth*float4(1,255,65025,16581375)*255.)/255.);
}

PIXEL main(VERTEX IN) : SV_TARGET
{
    float4 sample = gm_BaseTextureObject.Sample(gm_BaseTexture,IN.tex);
	//if (sample.a<0.5) discard;	
	
	PIXEL OUT;
	OUT.col = IN.col * sample;
	OUT.dep = pack_depth(IN.dep);
	OUT.nor = float4(.5+.5*IN.nor,1);
    return OUT;
}