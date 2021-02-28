///@desc Draw button + text

draw_set_font(fnt_menu_small);
gpu_set_texfilter(false);
draw_set_alpha(smooth);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
draw_text_pixelized(x-64*smooth,y-8,name, global.texPixelSize);
draw_self();