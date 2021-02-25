/// @description
if global.disableDraw{exit;}

matrix_set(matrix_world, M);
gpu_set_texfilter(true);
shader_set(sh_colmesh_world);
shader_set_lightdir(sh_colmesh_world);
subMesh.debugDraw(-1, sprite_get_texture(texCollider, 0));
shader_reset();
matrix_set(matrix_world, matrix_build_identity());