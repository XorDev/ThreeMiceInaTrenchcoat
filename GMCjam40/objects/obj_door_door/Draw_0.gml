/// @description Insert description here
// You can write your code in this editor
deferred_set(false);
matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
vertex_submit(global.modDoor, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();