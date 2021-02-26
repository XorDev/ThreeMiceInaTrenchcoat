/// @description
if (instance_exists(o_snidr_player))
{
	targetX = o_snidr_player.x;
	targetY = o_snidr_player.y;
	targetZ = o_snidr_player.z;
}
var d = 150;
global.camX = targetX + d * dcos(yaw) * dcos(pitch);
global.camY = targetY + d * dsin(yaw) * dcos(pitch);
global.camZ = targetZ + d * dsin(pitch);
camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, targetX, targetY, targetZ, 0, 0, 1));