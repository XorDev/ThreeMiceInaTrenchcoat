function shadow_init(res)
{
	global.shadow_res = res;
	global.surf_sha = -1;
}
function shadow_set(cx,cy,cz,dx,dy,dz,d)
{
	if !surface_exists(global.surf_sha) global.surf_sha = surface_create(global.shadow_res,  global.shadow_res);
	
	d /= point_distance_3d(0,0,0,dx,dy,dz);
	surface_set_target(global.surf_sha);
	gpu_set_blendenable(0);
	draw_clear_alpha(0,0);
	light_view = matrix_build_lookat(cx-dx*d,cy-dy*d,cz-dz*d,cx,cy,cz,0,0,1);
	light_proj = matrix_build_projection_perspective_fov(10,1,1,65025);
	matrix_set(matrix_projection,light_proj);
	matrix_set(matrix_view,light_view);
	light_mat = matrix_multiply(light_view,light_proj);

	shader_set(shd_shadow)
}

function shadow_reset()
{
	shader_reset();
	surface_reset_target();
	gpu_set_blendenable(1);
}