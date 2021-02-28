///@desc Mute (temporary)

//audio_set_master_gain(0,0);

function playSong(snd,loop)
{
	if !audio_is_playing(snd)
	{
		audio_play_sound(snd,0,loop);
	}	
}

playSong(snd_song1,0);
audio_sound_gain(snd_song1,0,0);
audio_sound_gain(snd_song1,1,500);