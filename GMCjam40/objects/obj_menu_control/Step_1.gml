///@desc Reset cursor

global.hover = instance_position(mouse_x,mouse_y,obj_button_parent);

window_set_cursor(instance_exists(global.hover)? cr_handpoint : cr_default);

var _w,_h,_s;
_w = view_wport[0];
_h = view_hport[0];
_s = sqr(global.fade);
layer_x(layer_id,-_w/2*_s);
layer_y(layer_id,-_h/2*_s);
layer_background_xscale(back_id,(1+_s)*_w/1920);
layer_background_yscale(back_id,(1+_s)*_h/1080);

var _layer,_back;
_layer = layer_get_id("Fade");
_back = layer_background_get_id(_layer);

if (global.fade>.99) && instance_exists(global.button)
{
	var _id = global.button;
	global.button = noone;
	with(_id) event_user(0);
	window_set_cursor(cr_default);
}
/*
layer_x(layer_id,(mouse_x-room_width)*.1);
layer_y(layer_id,(mouse_y-room_height)*.1);
*/