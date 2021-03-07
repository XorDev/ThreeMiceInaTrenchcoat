/// @description
light_set(false);
matrix_set(matrix_world, M);
vertex_submit(global.modLadder, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
light_reset();