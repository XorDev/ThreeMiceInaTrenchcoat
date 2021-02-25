/// @description
if global.disableDraw{exit;}
shader_set(sh_colmesh_collider);
shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_color"), .8, .4, .5);
shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_radius"), shape.r);
matrix_set(matrix_world, colmesh_matrix_build_from_vector(shape.x, shape.y, shape.z, shape.xup, shape.yup, shape.zup, shape.R, shape.R, shape.R));
vertex_submit(global.modTorus, pr_trianglelist, sprite_get_texture(texCollider, 0));
matrix_set(matrix_world, matrix_build_identity());
shader_reset();