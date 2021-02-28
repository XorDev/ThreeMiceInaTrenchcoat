// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function draw_text_pixelized(x, y, str, scale)
{
	static s = surface_create(32, 32);
	if !surface_exists(s)
	{
		s = surface_create(32, 32);
	}
	
	var halign = draw_get_halign();
	var valign = draw_get_valign();
	var alpha = draw_get_alpha();
	draw_set_halign(fa_middle);
	draw_set_valign(fa_middle);
	draw_set_color(c_white);
	draw_set_alpha(1);
	var w = string_width(str);
	var h = string_height(str);
	var size = scale * (sqrt(w * w + h * h));
	surface_resize(s, size, size);
	surface_set_target(s);
	draw_clear_alpha(c_white, 0);
	draw_text_transformed(size / 2, size / 2, str, scale, scale, -45);
	surface_reset_target();
	
	var xx = x - size / scale / 2 * 1.4142;
	var yy = y;
	if (halign == fa_right)
	{
		xx -= w / 2;
	}
	if (valign == fa_top)
	{
		yy -= h / 2
	}
	draw_surface_ext(s, xx, yy + 1 / scale, 1 / scale, 1 / scale, 45, c_black, .2 * alpha);
	draw_surface_ext(s, xx, yy, 1 / scale, 1 / scale, 45, draw_get_colour(), alpha);
	draw_set_alpha(alpha);
}