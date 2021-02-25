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

//MIN is the MINimum clipping distance of the camera.
#define MIN 1.
//MAX is the MAXimum clipping distance of the camera.
#define MAX 65025.

float4 packDepth(float Z)
{
	//Calculate the depth values in between the given MIN/MAX range.
	float depth = clamp((Z-MIN)/(MAX-MIN),0.,1.);
	
	//Encode the final color while taking advantage of the RGB channels.
	return frac(floor(depth*float4(1.,255.,65025.,16581375.)*255.)/255.);
}

PIXEL main(VERTEX input) : SV_TARGET
{
    float4 sample = gm_BaseTextureObject.Sample(gm_BaseTexture,input.tex);
	//if (sample.a<0.5) discard;	
	
	PIXEL output;
	output.col = input.col * sample;
	output.dep = packDepth(input.dep);
	output.nor = float4(.5+.5*input.nor,1);
    return output;
}