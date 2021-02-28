///@desc Animate and handle clicks.

var _hover = global.hover==id;

smooth = lerp(smooth,_hover,.2);
//Scale
image_xscale = 8 * (1+.2*smooth);
image_yscale = 8 * (1+.2*smooth);
image_angle = (-45 + cos(y + current_time / 1000) * 4);

if _hover && !instance_exists(global.button)
{
	window_set_cursor(cr_handpoint);
	
	if mouse_check_button_released(mb_left)
	{
		window_set_cursor(cr_default);
		global.button = object_index;
		global.black = (object_index != obj_button_settings);
	}
}