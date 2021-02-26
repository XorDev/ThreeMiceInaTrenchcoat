/*////////////////////////////////////////////////////////////////////////
	SMF animation fragment shader
	This is the standard shader that comes with the SMF system.
	This does some basic diffuse, specular and rim lighting.
*/////////////////////////////////////////////////////////////////////////
varying vec2 v_vTexcoord;
varying vec3 v_eyeVec;
varying vec3 v_vNormal;
varying float v_vRim;

void main()
{
    gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord);
	
	//Diffuse shade
	gl_FragColor.rgb *= .5 + .7 * max(dot(v_vNormal, normalize(vec3(1.))), 0.);
	
	//Specular highlights
	gl_FragColor.rgb += .1 * pow(max(dot(normalize(reflect(v_eyeVec, v_vNormal)), normalize(vec3(1.))), 0.), 4.);
	
	//Rim lighting
	gl_FragColor.rgb += .1 * vec3(pow(1. + v_vRim, 2.));
}