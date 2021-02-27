///@desc Tex filter

gpu_set_tex_filter(1);

alpha = 0;
fade = alpha;
global.button = noone;


layer_id = layer_get_id("Background");
back_id = layer_background_get_id(layer_id);

/*
layer_background_xscale(back_id,1.1);
layer_background_yscale(back_id,1.1);
*/