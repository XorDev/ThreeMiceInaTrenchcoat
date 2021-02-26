//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec3 v_vShade;

void main()
{
    gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord);
	gl_FragColor.rgb *= v_vShade;
}
