///@desc Reset cursor

var _i,_e;
_i = instance_position(mouse_x,mouse_y,obj_button_parent);
_e = instance_exists(_i);
if (global.hover != _i) && _e sound_randomize(snd_menu_hover,.2,.2,.3);
global.hover = _i;

window_set_cursor(_e? cr_handpoint : cr_default);

if (global.fade>.99) && instance_exists(global.button)
{
	var _id = global.button;
	global.button = noone;
	with(_id) event_user(0);
	window_set_cursor(cr_default);
}