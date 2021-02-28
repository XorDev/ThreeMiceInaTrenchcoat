/// @description
zz += (open * 32 - zz) * .1;

deferred_set(false);
matrix_set(matrix_world, matrix_build(x, y, z + zz, 0, 0, -90, 1, 1, 1));
vertex_submit(global.modCageDoor, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();