/*////////////////////////////////////////////////////////////////////////
	SMF static vertex shader
	This is the standard shader that comes with the SMF system.
	This does some basic diffuse, specular and rim lighting.
*/////////////////////////////////////////////////////////////////////////
attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                    // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec4 in_Colour2;                   // (r,g,b,a)
attribute vec4 in_Colour3;                   // (r,g,b,a)

varying vec2 v_vTexcoord;
varying vec3 v_eyeVec;
varying vec3 v_vNormal;
varying float v_vRim;

void main()
{
	vec4 objectSpacePos = vec4(in_Position, 1.0);
	vec4 animNormal = vec4(in_Normal, 0.);
	
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * objectSpacePos;
	vec3 tangent = 2. * in_Colour.rgb - 1.; //This is not used for anything in this particular shader
	vec3 camPos = - (gm_Matrices[MATRIX_VIEW][3] * gm_Matrices[MATRIX_VIEW]).xyz;
    vec3 vertPos = (gm_Matrices[MATRIX_WORLD] * objectSpacePos).xyz;
	v_eyeVec = vertPos - camPos;
	v_vNormal = normalize((gm_Matrices[MATRIX_WORLD] * animNormal).xyz);
	v_vRim = normalize((gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * animNormal).xyz).z;
    v_vTexcoord = in_TextureCoord;
}
