/// @desc shadow

//Draw
light_set(false);
matrix_set(matrix_world, matrix_build(x, y, z + height + h * (position - 1), 0, 0, 0, 1, 1, 1));
vertex_submit(global.modSpikes, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
light_reset();