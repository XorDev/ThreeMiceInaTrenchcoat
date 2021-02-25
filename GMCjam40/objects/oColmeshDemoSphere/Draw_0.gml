/// @description
if global.disableDraw{exit;}
shader_set(sh_colmesh_collider);
shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_radius"), shape.R);
shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_color"), .2, .7, .6);
matrix_set(matrix_world, matrix_build(shape.x, shape.y, shape.z, 0, 0, 0, 1, 1, 1));
vertex_submit(global.modSphere, pr_trianglelist, sprite_get_texture(texCollider, 0));
matrix_set(matrix_world, matrix_build_identity());
shader_reset();