function sound_randomize(snd,gain,pitch,max)
{
	var _snd = audio_play_sound(snd,0,0);
	var _gain = 1-random(gain);
	
	_gain *= max;
	audio_sound_gain(_snd,_gain,0);
	audio_sound_pitch(_snd,1-random_range(-pitch,pitch));
}