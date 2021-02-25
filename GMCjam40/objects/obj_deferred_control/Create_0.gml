///@desc

global.screen_width = window_get_width();
global.screen_height = window_get_height();

global.surf_dif = -1;
global.surf_dep = -1;
global.surf_nor = -1;

function check_surface()
{
	if !surface_exists(global.surf_dif) global.surf_dif = surface_create(global.screen_width,global.screen_height);
	if !surface_exists(global.surf_dep) global.surf_dep = surface_create(global.screen_width,global.screen_height);
	if !surface_exists(global.surf_nor) global.surf_nor = surface_create(global.screen_width,global.screen_height);
}