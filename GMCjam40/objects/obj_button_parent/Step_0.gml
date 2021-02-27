///@desc Animate and handle clicks.

var _hover = instance_position(mouse_x,mouse_y,self)==id;

//Scale
image_xscale = lerp(image_xscale,1+.2*_hover,.2);
image_yscale = lerp(image_yscale,1+.2*_hover,.2);

if _hover && instance_exists(global.button)
{
	window_set_cursor(cr_handpoint);
	
	if mouse_check_button_released(mb_left)
	{
		window_set_cursor(cr_default);
		global.button = id;
		obj_menu_control.alpha = 1;
	}
}