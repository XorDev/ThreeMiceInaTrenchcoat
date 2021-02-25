/// @description
if global.disableDraw{exit;}

event_inherited();

gpu_set_cullmode(cull_noculling)
//Draw the level

deferred_surface();
surface_set_target(global.surf_sha);
gpu_set_blendenable(0);
draw_clear_alpha(0,0);
light_view = matrix_build_lookat(x+100+800,y,z+800,x+100,y,z,0,0,1);
light_proj = matrix_build_projection_perspective_fov(50,1,1,65025);
matrix_set(matrix_projection,light_proj);
matrix_set(matrix_view,light_view);
light_mat = matrix_multiply(light_view,light_proj);


shader_set(shd_shadow)
vertex_submit(modLevel, pr_trianglelist, sprite_get_texture(ImphenziaPalette01, 0));
shader_reset();
surface_reset_target();
gpu_set_blendenable(1);


deferred_set();
var _uni,_tex;
	_uni = shader_get_sampler_index(shd_deferred,"ssha");
	_tex = surface_get_texture(global.surf_sha);
texture_set_stage(_uni,_tex);
shader_set_uniform_matrix_array(shader_get_uniform(shd_deferred,"view"),light_mat);

//shader_set_lightdir(sh_colmesh_world);
vertex_submit(modLevel, pr_trianglelist,sprite_get_texture(ImphenziaPalette01, 0));
//matrix_set(matrix_world, matrix_build_identity());
colmesh_debug_draw_capsule(x, y, z, xup, yup, zup, radius, height, make_colour_rgb(110, 127, 200));

deferred_reset();



//Draw debug collision shapes
if global.drawDebug
{
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height), false);
}