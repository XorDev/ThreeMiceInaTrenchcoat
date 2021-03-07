/// @description
event_inherited();

trap = 0;
tex = sprite_get_texture(tex_button, 0);
timer = 20; //20 ingame frames until the button goes from active to inactive

position = 0;
activated = false;
release = 1;

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

shape = levelColmesh.addTrigger(new colmesh_cylinder(x + 16, y + 16, z, 0, 0, 1, 5, 5), colFunc);