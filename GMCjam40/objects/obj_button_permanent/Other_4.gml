/// @description
event_inherited();

tex = sprite_get_texture(tex_green_button, 0);
timer = 20; //20 ingame frames until the button goes from active to inactive

position = 0;
activated = false;
colFunc = function()
{
	if (!activated)
	{
		sound_randomize(snd_click1,.2,.2,1);
	}
	activated = true;
	
}

shape = levelColmesh.addTrigger(new colmesh_cylinder(x + 16, y + 16, z, 0, 0, 1, 5, 5), colFunc);