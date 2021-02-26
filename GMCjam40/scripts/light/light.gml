function light_init(res)
{
	global.shadow_res = res;
	global.surf_sha = -1;
	global.lig_mat = matrix_build_identity();
	global.lig_pos = [0,0,0];
	global.lig_dir = [0,0,0];
}

function light_set_pos(x,y,z,dx,dy,dz,dist)
{
	global.lig_pos = [ x-dx*dist, y-dy*dist, z-dz*dist];
	global.lig_dir = [dx,dy,dz];
}
function light_follow(x,y,z)
{
	light_set_pos(x,y,z,-.48,-.36,-.80,1000);
}
function light_set(animated)
{
	var _shader = shd_shadow;
	if (argument_count && animated) _shader = shd_shadow_smf;
	if !surface_exists(global.surf_sha) global.surf_sha = surface_create(global.shadow_res,  global.shadow_res);
	
	surface_set_target(global.surf_sha);
	gpu_set_blendenable(0);
	var _x,_y,_z,_dx,_dy,_dz;
	 _x = global.lig_pos[0];  _y = global.lig_pos[1];  _z = global.lig_pos[2];
	_dx = global.lig_dir[0]; _dy = global.lig_dir[1]; _dz = global.lig_dir[2];
	var _lig_proj,_lig_view;
	_lig_proj = matrix_build_projection_perspective_fov(50,1,1,65025);
	_lig_view = matrix_build_lookat(_x,_y,_z,_dx,_dy,_dz,0,0,1);
	
	matrix_set(matrix_projection,_lig_proj);
	matrix_set(matrix_view,_lig_view);
	global.lig_mat = matrix_multiply(_lig_view,_lig_proj);

	shader_set(_shader);
}

function light_reset()
{
	shader_reset();
	surface_reset_target();
	gpu_set_blendenable(1);
}