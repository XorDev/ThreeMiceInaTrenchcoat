///@desc Variables +tex filter

gpu_set_tex_filter(true);

global.black = 0;
global.fade = 1;
global.button = noone;
global.hover = noone;

layer_id = layer_get_id("Background");
back_id = layer_background_get_id(layer_id);

/*
layer_background_xscale(back_id,1.1);
layer_background_yscale(back_id,1.1);
*/