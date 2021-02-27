/// @description
/*
//Draw
deferred_set(false);
matrix_set(matrix_world, M);
vertex_submit(global.modTunnelHor, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();