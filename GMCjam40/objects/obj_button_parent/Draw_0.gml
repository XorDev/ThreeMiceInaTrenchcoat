///@desc Draw button + text

gpu_set_texfilter(false);
draw_set_alpha(smooth);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
draw_text(x-64*smooth,y-8,name);
draw_self();