function deferred_init()
{
	global.screen_width = window_get_width();
	global.screen_height = window_get_height();
	global.view_mat = matrix_get(matrix_view);

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
	
	if surface_exists(global.surf_sha)
	{
		surface_set_target(global.surf_sha);
		draw_clear(0);
		surface_reset_target();
	}
}

function deferred_set(animated)
{
	var _shader = shd_deferred;
	if (argument_count && animated) _shader = shd_deferred_smf;
	shader_set(_shader);

	surface_set_target_ext(0,global.surf_dif);
	surface_set_target_ext(1,global.surf_dep);
	surface_set_target_ext(2,global.surf_nor);
	surface_set_target_ext(3,global.surf_buf);

	camera_apply(view_camera[0]);
	global.view_mat = matrix_get(matrix_view);
	gpu_set_blendenable(0);
	var _uni,_tex;
	_uni = shader_get_uniform(shd_deferred,"SHA_RES");
	shader_set_uniform_f(_uni,global.shadow_res,global.shadow_res);
	_uni = shader_get_sampler_index(_shader,"ssha");
	_tex = surface_get_texture(global.surf_sha);
	texture_set_stage(_uni,_tex);
	_uni = shader_get_uniform(_shader,"lig_mat");
	shader_set_uniform_matrix_array(_uni,global.lig_mat);

}

function deferred_reset()
{
	shader_reset();
	surface_reset_target();
	gpu_set_blendenable(1);
}

function deferred_draw()
{
	//SSAO:
	surface_set_target(global.surf_buf);
	gpu_set_blendmode_ext(bm_dest_color,bm_zero);
	shader_set(shd_ssao);
	var _uni,_tex;
	_uni = shader_get_uniform(shd_ssao,"RES");
	shader_set_uniform_f(_uni,global.screen_width,global.screen_height);
	_uni = shader_get_sampler_index(shd_ssao,"snor");
	_tex = surface_get_texture(global.surf_nor);
	texture_set_stage(_uni,_tex);
	draw_surface_ext(global.surf_dep,0,global.screen_height,1,-1,0,-1,1);
	shader_reset();
	gpu_set_blendmode(bm_normal);
	surface_reset_target();
	
	//Soften shadows/occlusion.
	shader_set(shd_soft);
	_uni = shader_get_uniform(shd_soft,"RES");
	shader_set_uniform_f(_uni,global.screen_width,global.screen_height);
	_uni = shader_get_sampler_index(shd_soft,"sdep");
	_tex = surface_get_texture(global.surf_dep);
	texture_set_stage(_uni,_tex);
	draw_surface_ext(global.surf_buf,0,0,1,1,0,-1,1);
	shader_reset();
	
	//Draw point lights here.
	/*gpu_set_blendmode(bm_add);
	shader_set(shd_light);
	_uni = shader_get_uniform(shd_light,"RES");
	shader_set_uniform_f(_uni,global.screen_width,global.screen_height);
	_uni = shader_get_sampler_index(shd_light,"sdep");
	_tex = surface_get_texture(global.surf_dep);
	texture_set_stage(_uni,_tex);
	_uni = shader_get_sampler_index(shd_light,"snor");
	_tex = surface_get_texture(global.surf_nor);
	texture_set_stage(_uni,_tex);
	//TODO: Compute circle coordinates/radius
	//TODO: Multiple lights
	draw_set_color(c_gray);
	_uni = shader_get_uniform(shd_light,"lig_pos");
	var _pos = matrix_transform_vertex(global.view_mat,0,0,50);
	shader_set_uniform_f(_uni,_pos[0],_pos[1],_pos[2],300);
	draw_circle(global.screen_width*(_pos[0]/_pos[2]*.5+.5),global.screen_width*(_pos[1]/_pos[2]*-.5+.5/16*9),50*300/_pos[2],0);
	shader_reset();*/
	
	//Texture colors
	gpu_set_blendmode_ext(bm_dest_color,bm_zero);
	draw_surface_ext(global.surf_dif,0,0,1,1,0,-1,1);
	gpu_set_blendmode(bm_normal);
	
	
	
	
	//draw_surface_ext(global.surf_sha,global.screen_width*.25,0,1/4,1/4,0,-1,1);
	//draw_surface_ext(global.surf_dep,global.screen_width*.50,0,1/4,1/4,0,-1,1);
	//draw_surface_ext(global.surf_nor,global.screen_width*.75,0,1/4,1/4,0,-1,1);
	
	deferred_surface();
}