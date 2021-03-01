/// @description

if (room==rm_menu) && (room!=rm_menu_lose) && (room!=rm_menu_win)
{
	gpu_set_zwriteenable(false);
}
else
{
	//Enable 3D projection
	view_enabled = true;
	view_visible[0] = true;
	view_set_camera(0, camera_create());
	gpu_set_ztestenable(true);
	gpu_set_zwriteenable(true);
	camera_set_proj_mat(view_camera[0], matrix_build_projection_perspective_fov(-90, -window_get_width() / window_get_height(), 1, 32000));
}