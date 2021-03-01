/// @description
scaleSpd += (scaleTarget - scale) * .06;
scaleSpd *= .92;
scale += scaleSpd;
smoothAlpha += (1 - smoothAlpha) * .05;

xx = room_width / 2;
yy = room_height / 2 + 90;
gpu_set_texfilter(false);
draw_sprite_ext(spr_skull, 0, xx, yy, scale, scale, -45, c_white, 1);

draw_set_color(c_white);
draw_set_alpha(smoothAlpha);
draw_set_font(fnt_menu);
draw_set_halign(fa_middle);
draw_set_valign(fa_middle);
draw_text_pixelized(xx, yy + 200, "You lost!", 1 / 8);

gpu_set_texfilter(true);