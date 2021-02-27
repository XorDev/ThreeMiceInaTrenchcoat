/// @description

//Draw
deferred_set(false);
matrix_set(matrix_world, matrix_build(x, y, z - active * 4, 0, 0, 0, 1, 1, 1));
vertex_submit(global.modButton, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();

active = false;