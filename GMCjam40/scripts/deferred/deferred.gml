function deferred_init()
{
	global.screen_width = window_get_width();
	global.screen_height = window_get_height();

	global.surf_dif = -1;
	global.surf_dep = -1;
	global.surf_nor = -1;
	global.surf_buf = -1;
}
function deferred_surface()
{
	if !surface_exists(global.surf_dif) global.surf_dif = surface_create(global.screen_width,global.screen_height);
	if !surface_exists(global.surf_dep) global.surf_dep = surface_create(global.screen_width,global.screen_height);
	if !surface_exists(global.surf_nor) global.surf_nor = surface_create(global.screen_width,global.screen_height);
	if !surface_exists(global.surf_buf) global.surf_buf = surface_create(global.screen_width,global.screen_height);
	
	surface_set_target(global.surf_dif);
	draw_clear_alpha($000000,0);
	surface_reset_target();
	
	surface_set_target(global.surf_dep);
	draw_clear_alpha($FFFFFF,1);
	surface_reset_target();
	
	surface_set_target(global.surf_nor);
	draw_clear_alpha($7F7F7F,1);
	surface_reset_target();
	
	surface_set_target(global.surf_buf);
	draw_clear(0);
	surface_reset_target();
	
}

function deferred_set()
{
	shader_set(shd_deferred);
	
	surface_set_target_ext(0,global.surf_dif);
	surface_set_target_ext(1,global.surf_dep);
	surface_set_target_ext(2,global.surf_nor);
	surface_set_target_ext(3,global.surf_buf);

	camera_apply(view_camera[0]);
	gpu_set_blendenable(0);
	var _uni,_tex;
	_uni = shader_get_sampler_index(shd_deferred,"ssha");
	_tex = surface_get_texture(global.surf_sha);
	texture_set_stage(_uni,_tex);
	_uni = shader_get_uniform(shd_deferred,"light_mat");
	shader_set_uniform_matrix_array(_uni,light_mat);

}

function deferred_reset()
{
	shader_reset();
	surface_reset_target();
	gpu_set_blendenable(1);
}

function deferred_draw()
{
	surface_set_target(global.surf_buf);
	gpu_set_blendmode_ext(bm_dest_color,bm_zero);
	shader_set(shd_ssao);
	var _uni,_tex;
	_uni = shader_get_sampler_index(shd_ssao,"snor");
	_tex = surface_get_texture(global.surf_nor);
	texture_set_stage(_uni,_tex);
	draw_surface_ext(global.surf_dep,0,global.screen_height,1,-1,0,-1,1);
	shader_reset();
	gpu_set_blendmode(bm_normal);
	surface_reset_target();
	
	shader_set(shd_soft);
	_uni = shader_get_sampler_index(shd_soft,"sdep");
	_tex = surface_get_texture(global.surf_dep);
	draw_surface_ext(global.surf_buf,0,0,1,1,0,-1,1);
	shader_reset();
	
	gpu_set_blendmode_ext(bm_dest_color,bm_zero);
	draw_surface_ext(global.surf_dif,0,0,1,1,0,-1,1);
	gpu_set_blendmode(bm_normal);
	
	
	//draw_surface_ext(global.surf_sha,global.screen_width*.25,0,1/4,1/4,0,-1,1);
	//draw_surface_ext(global.surf_dep,global.screen_width*.50,0,1/4,1/4,0,-1,1);
	//draw_surface_ext(global.surf_nor,global.screen_width*.75,0,1/4,1/4,0,-1,1);
	
	deferred_surface();
}