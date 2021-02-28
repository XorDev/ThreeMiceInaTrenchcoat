function sound_randomize(snd, gain, pitch)
{
	var _snd = audio_play_sound(snd,0,0);
	audio_sound_gain(_snd,1-random(gain),0);
	audio_sound_pitch(_snd,1-random_range(-pitch,pitch));
}