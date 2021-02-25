/// @description
if global.disableDraw{exit;}

event_inherited();

gpu_set_cullmode(cull_noculling);

//Draw the level

deferred_surface();
shadow_set(lerp(x,global.camX,-2),lerp(y,global.camY,-2),lerp(z,global.camZ,-2),1,-3,-5,5000);

vertex_submit(modLevel, pr_trianglelist, sprite_get_texture(ImphenziaPalette01, 0));
shadow_reset();

deferred_set();

//shader_set_lightdir(sh_colmesh_world);
vertex_submit(modLevel, pr_trianglelist,-1);//sprite_get_texture(ImphenziaPalette01, 0));
//matrix_set(matrix_world, matrix_build_identity());
colmesh_debug_draw_capsule(x, y, z, xup, yup, zup, radius, height, make_colour_rgb(110, 127, 200));

deferred_reset();



//Draw debug collision shapes
if global.drawDebug
{
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height), false);
}