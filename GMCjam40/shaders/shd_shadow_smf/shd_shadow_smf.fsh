//MIN is the z-near clipping distance.
#define MIN 1.
//MIN is the z-far clipping distance.
#define MAX 65025.

struct VERTEX
{
	float4 pos : SV_POSITION;
	float  dep : TEXCOORD0;
};

struct PIXEL
{
	float4 col : COLOR0;
};

float4 pack_depth(float z)
{
	//Calculate the depth values in between the given MIN/MAX range.
	float depth = clamp((z-MIN)/(MAX-MIN),0.,1.);
	
	//Encode the final color while taking advantage of the RGB channels.
	return frac(floor(depth*float4(1,255,65025,16581375)*255.)/255.);
}

PIXEL main(VERTEX IN) : SV_TARGET
{	
	PIXEL OUT;
	OUT.col = pack_depth(IN.dep);
    return OUT;
}