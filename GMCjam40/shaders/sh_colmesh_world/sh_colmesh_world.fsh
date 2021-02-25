//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec3 v_vColour;

void main()
{
    gl_FragColor = vec4(v_vColour * texture2D(gm_BaseTexture, v_vTexcoord ).rgb, 1.);
}
