///@desc Detect player
if (timer != 0)
{
	var s = sign(timer);
	timer -= s;
	if (timer == 0 && s == 1)
	{
		timer = -50;
		open = true;
		
		sound_randomize(snd_trapdoor,.2,.2,1);
		
		shape.move(levelColmesh, x + 16, y + 16, z + 512);
	}
	
	if (timer == 0 && s == -1)
	{
		open = false;
		shape.move(levelColmesh, x + 16, y + 16, z + 64 - 32);
	}
}

angle += (open * 89 - angle) * .1;