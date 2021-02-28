/// @description
scaleSpd += (scaleTarget - scale) * .06;
scaleSpd *= .92;
scale += scaleSpd;
smoothAlpha += (1 - smoothAlpha) * .01;

xx = room_width / 2;
yy = room_height / 2;
gpu_set_texfilter(false);
draw_sprite_ext(spr_mouse, 0, xx, yy, scale, scale, -45, c_white, 1);

draw_set_font(fnt_menu_small);
draw_set_color(c_white);
draw_set_alpha(smoothAlpha);
draw_set_font(fnt_menu);
draw_set_halign(fa_middle);
draw_set_valign(fa_middle);
draw_text_pixelized(xx, yy - 200, "Three mice", 1 / 5);
draw_set_font(fnt_menu_small);
draw_text_pixelized(xx, yy + 240, "in a trenchcoat", 1 / 5);

gpu_set_texfilter(true);