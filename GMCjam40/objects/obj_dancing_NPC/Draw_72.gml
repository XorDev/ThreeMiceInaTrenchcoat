/// @description
light_set(1);
gpu_set_cullmode(cull_noculling);
matrix_set(matrix_world, M);
instance.draw();
matrix_set(matrix_world,matrix_build_identity());
light_reset();