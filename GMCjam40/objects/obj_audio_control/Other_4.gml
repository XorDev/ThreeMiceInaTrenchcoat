///@desc

if (room=rm_menu_lose)
{
	audio_sound_gain(snd_song_main,0,500);
	
	playSong(snd_song_lose,0);
	audio_sound_gain(snd_song_lose,1,500);
}
else
{
	_gain = 0.4-0.2*(room==rm_menu)
	audio_sound_gain(snd_song_main,_gain,1500);
}