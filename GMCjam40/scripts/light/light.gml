function light_init(res)
{
	global.shadow_res = res;
	global.surf_sha = -1;
	global.lig_mat = matrix_build_identity();
}
function light_set(cx,cy,cz,dx,dy,dz,d)
{
	if !surface_exists(global.surf_sha) global.surf_sha = surface_create(global.shadow_res,  global.shadow_res);
	
	surface_set_target(global.surf_sha);
	gpu_set_blendenable(0);
	draw_clear_alpha(0,0);
	var _lig_proj,_lig_view;
	_lig_proj = matrix_build_projection_perspective_fov(50,1,1,65025);
	 d /= point_distance_3d(0,0,0,dx,dy,dz);
	_lig_view = matrix_build_lookat(cx-dx*d,cy-dy*d,cz-dz*d,cx,cy,cz,-1,0,0);
	
	matrix_set(matrix_projection,_lig_proj);
	matrix_set(matrix_view,_lig_view);
	global.lig_mat = matrix_multiply(_lig_view,_lig_proj);

	shader_set(shd_shadow);
}

function light_reset()
{
	shader_reset();
	surface_reset_target();
	gpu_set_blendenable(1);
}