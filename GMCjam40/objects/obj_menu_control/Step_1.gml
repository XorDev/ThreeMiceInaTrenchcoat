///@desc Reset cursor

global.hover = instance_position(mouse_x,mouse_y,obj_button_parent);

window_set_cursor(instance_exists(global.hover)? cr_handpoint : cr_default);

fade = lerp(fade,alpha,.2);

layer_x(layer_id,-room_width/2*fade);
layer_y(layer_id,-room_height/2*fade);
layer_background_xscale(back_id,1+fade);
layer_background_yscale(back_id,1+fade);

var _layer,_back;
_layer = layer_get_id("Fade");
_back = layer_background_get_id(_layer);

layer_background_alpha(_back,fade);

if (fade>.99) && instance_exists(global.button)
{
	with(global.button) event_perform(ev_user0,0);
	alpha = 0;
	global.button = noone;
}
/*
layer_x(layer_id,(mouse_x-room_width)*.1);
layer_y(layer_id,(mouse_y-room_height)*.1);
*/