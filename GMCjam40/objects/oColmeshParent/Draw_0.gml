/// @description
//Draw skybox
shader_set(sh_colmesh_skybox);
gpu_set_zwriteenable(false);
gpu_set_texfilter(true);
gpu_set_cullmode(cull_noculling);
var scale = 10000;
var skyMat = matrix_build(0, 0, 0, 30 + current_time / 1000, 30 + current_time / 1200, current_time / 1500, scale, scale, scale);
matrix_set(matrix_world, skyMat);
vertex_submit(global.modSphere, pr_trianglelist, sprite_get_texture(texClouds, 0));
matrix_set(matrix_world, matrix_build_identity());
shader_reset();
gpu_set_zwriteenable(true);
gpu_set_cullmode(cull_counterclockwise);

//Transform and normalize the light direction
global.lightDir = matrix_transform_vertex(skyMat, 0, 0, -1);
global.lightDir[0] /= scale;
global.lightDir[1] /= scale;
global.lightDir[2] /= scale;