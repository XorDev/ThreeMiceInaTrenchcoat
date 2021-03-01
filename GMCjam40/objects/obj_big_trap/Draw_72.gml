/// @desc shadow

light_set(false);
matrix_set(matrix_world, matrix_build(x, y, z+64, angle, 0, 0, 2, 2, 2));
vertex_submit(global.modTrapFloor, pr_trianglelist, tex);
light_reset();