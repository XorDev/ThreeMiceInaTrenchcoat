///@desc Reset cursor

global.hover = instance_position(mouse_x,mouse_y,obj_button_parent);

window_set_cursor(instance_exists(global.hover)? cr_handpoint : cr_default);

fade = lerp(fade,alpha,.2);

var _w,_h;
_w = window_get_width();
_h = window_get_height();
layer_x(layer_id,-_w/2*fade);
layer_y(layer_id,-_h/2*fade);
layer_background_xscale(back_id,(1+fade)*_w/1920);
layer_background_yscale(back_id,(1+fade)*_h/1080);

var _layer,_back;
_layer = layer_get_id("Fade");
_back = layer_background_get_id(_layer);

layer_background_alpha(_back,fade);

if (fade>.99) && instance_exists(global.button)
{
	alpha = 0;
	var _id = global.button;
	global.button = noone;
	with(_id) event_user(0);
}
/*
layer_x(layer_id,(mouse_x-room_width)*.1);
layer_y(layer_id,(mouse_y-room_height)*.1);
*/