///@desc Variables +tex filter

gpu_set_tex_filter(true);

alpha = 0;
fade = 1;
global.button = noone;
global.hover = noone;

layer_id = layer_get_id("Background");
back_id = layer_background_get_id(layer_id);

if (room==rm_menu)
{
	if !audio_is_playing(snd_main)
	{
		audio_play_sound(snd_main,0,1);
	}
}
else if (room==rm_menu_lose)
{
	audio_play_sound(snd_lose,0,0);
	audio_sound_gain(snd_lose,1,0);
}

/*
layer_background_xscale(back_id,1.1);
layer_background_yscale(back_id,1.1);
*/