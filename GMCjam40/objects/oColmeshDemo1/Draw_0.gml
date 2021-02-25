/// @description
if global.disableDraw{exit;}

event_inherited();

gpu_set_cullmode(cull_noculling)
//Draw the level

shader_set(shd_deferred);

obj_deferred_control.check_surface();
surface_set_target_ext(0,global.surf_dif);
surface_set_target_ext(1,global.surf_dep);
surface_set_target_ext(2,global.surf_nor);

camera_apply(view_camera[0]);

draw_clear_alpha(0,0);
gpu_set_blendenable(0);

//shader_set_lightdir(sh_colmesh_world);
vertex_submit(modLevel, pr_trianglelist, sprite_get_texture(ImphenziaPalette01, 0));
matrix_set(matrix_world, matrix_build_identity());
surface_reset_target();
gpu_set_blendenable(1);

//Draw debug collision shapes
if global.drawDebug
{
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height), false);
}