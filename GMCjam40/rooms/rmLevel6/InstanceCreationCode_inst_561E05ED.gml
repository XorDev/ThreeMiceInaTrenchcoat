colFunc = function()
{
	if (position < .2)
	{
		sound_randomize(snd_click0,.2,.2,1);
		with(obj_trapfloor)
		{
			timer = -8;
			open = true;
		}
	}
	activated = true;
	release = 1;
}