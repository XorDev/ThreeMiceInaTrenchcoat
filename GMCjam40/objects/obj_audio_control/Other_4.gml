///@desc

if (room=rm_menu_lose)
{
	audio_sound_gain(snd_song_main,0,500);
	
	playSong(snd_song_lose,0);
	audio_sound_gain(snd_song_lose,music_gain,500);
}
else
{
	_gain = music_gain*(1-.5*(room==rm_menu));
	audio_sound_gain(snd_song_main,_gain,1500);
}