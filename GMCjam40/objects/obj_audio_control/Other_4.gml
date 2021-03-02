///@desc

switch(room)
{
	default:
	_gain = music_gain*(1-.5*(room==rm_menu));
	audio_sound_gain(snd_song_main,_gain,1500);
	audio_sound_gain(snd_song_lose,0,200);
	audio_sound_gain(snd_song_ball,0,200);
	break;
	
	case rm_menu_lose:
	audio_sound_gain(snd_song_main,0,200);
	audio_sound_gain(snd_song_ball,0,200);
	playSong(snd_song_lose,0);
	audio_sound_gain(snd_song_lose,music_gain,200);
	break;

	case rm_menu_win:
	audio_sound_gain(snd_song_main,0,200);
	audio_sound_gain(snd_song_ball,0,200);
	playSong(snd_song_win,0);
	audio_sound_gain(snd_song_win,music_gain,200);
	break;

	case rmLevel5:
	case rmLevel6:
	audio_sound_gain(snd_song_main,0,200);
	playSong(snd_song_ball,1);
	audio_sound_gain(snd_song_ball,music_gain,200);
	break;
}