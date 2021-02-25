/// @description
if global.disableDraw{exit;}

//Draw player shadow
colmeshdemo_draw_circular_shadow(x, y, z, charMat[8], charMat[9], charMat[10], radius, 200, .5);

//Draw player
colmesh_debug_draw_capsule(x, y, z, charMat[8], charMat[9], charMat[10], radius, height, make_colour_rgb(110, 127, 200));