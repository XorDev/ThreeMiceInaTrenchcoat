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
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_set_alpha(1);
	var w = string_width(str);
	var h = string_height(str);
	var size = scale * (sqrt(w * w + h * h) + h);
	surface_resize(s, size, size);
	surface_set_target(s);
	draw_clear_alpha(c_white, 0);
	draw_text_transformed(h * scale, h * scale, str, scale, scale, -45);
	surface_reset_target();
	
	var xx = x;
	var yy = y;
	if (halign == fa_middle)
	{
		xx -= w / 2 + h * 1.4142;
	}
	if (valign == fa_middle)
	{
		yy -= h / 2;
	}
	draw_surface_ext(s, xx, yy, 1 / scale, 1 / scale, 45, c_white, 1);
}