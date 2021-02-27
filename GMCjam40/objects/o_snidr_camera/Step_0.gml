/// @description
if (instance_exists(o_snidr_player))
{
	targetX = o_snidr_player.x;
	targetY = o_snidr_player.y;
	targetZ = o_snidr_player.z;
}
global.camX = targetX + 16;
global.camY = targetY + 50;
global.camZ = targetZ + 80;
camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, targetX, targetY, targetZ, 0, 0, 1));