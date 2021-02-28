///@desc

if (room=rm_menu_lose)
{
	audio_sound_gain(snd_song1,0,500);
	
	playSong(snd_lose,0);
	audio_sound_gain(snd_lose,1,500);
}
else
{
	audio_sound_gain(snd_song1,1,1500);
}