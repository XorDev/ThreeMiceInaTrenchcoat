/// @description

if (room!=rm_menu) && (room!=rm_menu_lose)
{
	targetX = 4 * 32;
	targetY = 4 * 32;
	targetZ = 0;
	global.camX = targetX + 16;
	global.camY = targetY + 40;
	global.camZ = 100;
	camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, targetX, targetY, targetZ, 0, 0, 1));
}