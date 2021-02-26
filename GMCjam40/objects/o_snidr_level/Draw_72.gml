/// @desc shadow pass
if global.disableDraw{exit;}

//Shadow pass (move light forward)
light_set(0);
gpu_set_cullmode(cull_noculling);
//Draw the level
matrix_set(matrix_world,matrix_build_identity());
vertex_submit(modLevel, pr_trianglelist, -1);
light_reset();