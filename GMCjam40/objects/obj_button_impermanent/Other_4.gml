/// @description
event_inherited();


colFunc = function()
{
	if (position < .2)
	{
		sound_randomize(snd_click0,.2,.2,1);
	}
	activated = true;
	release = 1;
	if (trap==1) with(obj_big_trap)
	{
		open = true;
		timer = -10;
	}
	if (trap==2) with(obj_trapfloor)
	{
		open = true;
		timer = -10;
	}
}

//Modifying the level ColMesh must be done in Room Start, not in Create event!
shape = levelColmesh.addTrigger(new colmesh_cylinder(x + 16, y + 16, z, 0, 0, 1, 5, 5), colFunc);