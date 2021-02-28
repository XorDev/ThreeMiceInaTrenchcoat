///@desc Animate and handle clicks.

var _hover = global.hover==id;

smooth = lerp(smooth,_hover,.2);
//Scale
image_xscale = 8 * (1+.2*smooth);
image_yscale = 8 * (1+.2*smooth);

if _hover && !instance_exists(global.button)
{
	window_set_cursor(cr_handpoint);
	
	if mouse_check_button_released(mb_left)
	{
		window_set_cursor(cr_default);
		if fade
		{
			global.button = object_index;
			obj_menu_control.alpha = 1;
		}
		else
		{
			event_user(0);
		}
	}
}