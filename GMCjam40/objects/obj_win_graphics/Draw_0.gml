/// @description
scaleSpd += (scaleTarget - scale) * .06;
scaleSpd *= .92;
scale += scaleSpd;
smoothAlpha += (1 - smoothAlpha) * .05;

xx = room_width / 2-160;
yy = room_height / 2 + 90;
draw_sprite_ext(sprite_index, 0, xx, yy, scale, scale, -45, c_white, 1);

draw_set_color(c_white);
draw_set_alpha(smoothAlpha);
draw_set_font(fnt_menu);
draw_set_halign(fa_middle);
draw_set_valign(fa_middle);
draw_text_pixelized(xx, yy + 200, "You won!", 1 / 8);
