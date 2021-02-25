//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;
attribute vec2 in_TextureCoord;              // (u,v)
attribute vec4 in_Colour;              // (u,v)

varying vec2 v_vTexcoord;

void main()
{
	//Find the projection space coordinate
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * vec4(mat3(gm_Matrices[MATRIX_WORLD_VIEW]) * in_Normal, 1.);
    
    v_vTexcoord = in_TextureCoord;
}
