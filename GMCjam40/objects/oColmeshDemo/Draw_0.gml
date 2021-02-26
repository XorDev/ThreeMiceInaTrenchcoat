/// @description
if global.disableDraw{exit;}

event_inherited();

gpu_set_cullmode(cull_counterclockwise);

//Draw the level

deferred_surface();
light_set(lerp(x,global.camX,-2),lerp(y,global.camY,-2),lerp(z,global.camZ,-2),-.48,.36,-.8,1000);

vertex_submit(modLevel, pr_trianglelist,-1);
light_reset();

deferred_set();

vertex_submit(modLevel, pr_trianglelist,sprite_get_texture(spr_grid,0));
//matrix_set(matrix_world, matrix_build_identity());
//colmesh_debug_draw_capsule(x, y, z, xup, yup, zup, radius, height, make_colour_rgb(110, 127, 200));

deferred_reset();


//Draw debug collision shapes
if global.drawDebug
{
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height), false);
}