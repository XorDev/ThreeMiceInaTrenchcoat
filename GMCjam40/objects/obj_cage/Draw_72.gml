/// @description
light_set(false);
matrix_set(matrix_world, matrix_build(x, y, z + zz, 0, 0, -90, 1, 1, 1));
vertex_submit(global.modCageDoor, pr_trianglelist, sprite_get_texture(spr, 0));
matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, -90, 1, 1, 1));
vertex_submit(global.modCage, pr_trianglelist, sprite_get_texture(spr, 0));
matrix_set(matrix_world, matrix_build_identity());
light_reset();