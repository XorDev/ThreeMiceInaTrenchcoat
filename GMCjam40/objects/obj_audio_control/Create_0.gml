///@desc Sound system

//audio_set_master_gain(0,0);

music_gain = 0;//0.4;

function playSong(snd,loop)
{
	if !audio_is_playing(snd)
	{
		audio_play_sound(snd,0,loop);
	}	
}
playSong(snd_song_main,1)
audio_sound_gain(snd_song_main,0,0);