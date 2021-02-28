///@desc Render deferred output

if (room!=rm_menu) && (room!=rm_menu_lose)
{
	deferred_draw();
}

if (global.fade>.99) global.black = 0;
global.fade = lerp(global.fade,global.black,.2);

draw_set_alpha(global.fade);
draw_set_color(0);
var _w,_h;
_w = window_get_width();
_h = window_get_height();
draw_rectangle(0,0,_w,_h,0);
draw_set_alpha(1);