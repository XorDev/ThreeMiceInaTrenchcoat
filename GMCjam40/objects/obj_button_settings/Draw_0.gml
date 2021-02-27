///@desc Draw overlay

draw_set_font(fnt_menu);
event_inherited();

var _alpha,_w,_h,_slide;
_alpha = power(min(slide*4,1),.5);
_w = room_width;
_h = room_height;
_slide = power(slide,8);

draw_set_font(fnt_menu);
draw_set_alpha(_alpha);
draw_set_halign(fa_center);
draw_text(_w/2,_h*.05,"Graphics Profile:");

draw_text(_w/2*(1-_slide),_h*.1,names[global.gsettings]);
draw_set_alpha(_alpha*_slide);
draw_text(_w/2*(2-_slide),_h*.1,names[(global.gsettings+2)%3]);
draw_set_alpha(1);