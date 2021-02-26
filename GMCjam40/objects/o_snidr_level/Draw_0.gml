/// @description
if global.disableDraw{exit;}

event_inherited();

//Deferred pass
deferred_set(0);
gpu_set_cullmode(cull_noculling);
//Draw the level
vertex_submit(modLevel, pr_trianglelist, sprite_get_texture(spr_brick, 0));
deferred_reset();
matrix_set(matrix_world, matrix_build_identity());

//Draw debug collision shapes
if global.drawDebug
{
	with o_snidr_player
	{
		levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height), false);
	}
}