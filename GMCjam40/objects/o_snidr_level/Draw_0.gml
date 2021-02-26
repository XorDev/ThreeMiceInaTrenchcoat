/// @description
if global.disableDraw{exit;}

event_inherited();

//Shadow pass (move light forward)
var _cx,_cy,_cz;
_cx = lerp(o_snidr_player.x,global.camX,-2);
_cy = lerp(o_snidr_player.y,global.camY,-2);
_cz = lerp(o_snidr_player.z,global.camZ,-2);
light_set(_cx,_cy,_cz,-.48,-.36,-.8,1000,0);
gpu_set_cullmode(cull_counterclockwise);
//Draw the level
vertex_submit(modLevel, pr_trianglelist, -1);
light_reset();

//Deferred pass
deferred_set(0);
gpu_set_cullmode(cull_counterclockwise);
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