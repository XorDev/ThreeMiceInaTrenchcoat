/// @description

if (room!=rm_menu) &&  (room!=rm_menu_lose)
{
	var d = 1;
	if (instance_exists(obj_player))
	{
		targetX = obj_player.x;
		targetY = obj_player.y;
		targetZ = obj_player.z;
		if (global.mouseArray[0].dead)
		{
			d = 1. - .4 * sqr(max(0, 1. - 1.2 * global.mouseArray[0].deathcountdown / 100));
		}
	}
	global.camX = targetX + 16 * d;
	global.camY = targetY + 40 * d;
	global.camZ = targetZ + 100 * d;
	camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, targetX, targetY, targetZ, 0, 0, 1));
}