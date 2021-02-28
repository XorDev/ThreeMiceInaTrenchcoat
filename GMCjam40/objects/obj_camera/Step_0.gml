/// @description

if (room!=rm_menu) &&  (room!=rm_menu_lose)
{
	if (instance_exists(obj_player))
	{
		targetX = obj_player.x;
		targetY = obj_player.y;
		targetZ = obj_player.z;
	}
	global.camX = targetX + 16;
	global.camY = targetY + 40;
	global.camZ = targetZ + 100;
	camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, targetX, targetY, targetZ, 0, 0, 1));
}