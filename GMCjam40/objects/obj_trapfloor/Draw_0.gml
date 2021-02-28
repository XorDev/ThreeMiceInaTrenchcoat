///@desc draw

deferred_set(false);
matrix_set(matrix_world, matrix_build(x, y, z+64, 0, 0, 0, 1, 1, 1));
vertex_submit(global.modTrapFloor, pr_trianglelist, tex);
deferred_reset();