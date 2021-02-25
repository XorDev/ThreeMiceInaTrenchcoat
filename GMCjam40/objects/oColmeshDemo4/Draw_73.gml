/// @description
if global.disableDraw{exit;}
//Draw player shadow
colmeshdemo_draw_circular_shadow(x, y, z, xup, yup, zup, radius, 200, .5);

//Draw player
colmesh_debug_draw_capsule(x, y, z, xup, yup, zup, radius, height, make_colour_rgb(110, 127, 200));

//Draw player's nose
colmesh_debug_draw_sphere(x + charMat[0] * radius, y + charMat[1] * radius, z + height, radius / 5, make_colour_rgb(110, 127, 200));