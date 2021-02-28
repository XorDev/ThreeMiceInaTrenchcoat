/// @description
scaleSpd += (scaleTarget - scale) * .06;
scaleSpd *= .92;
scale += scaleSpd;

xx = room_width / 2;
yy = room_height / 2;
gpu_set_texfilter(false);
draw_sprite_ext(spr_skull, 0, xx, yy, scale, scale, -45, c_white, 1);
gpu_set_texfilter(true);

draw_set_color(c_white);
draw_set_halign(fa_middle);
draw_set_valign(fa_middle);
draw_text(xx, yy, "You lost");