/// @description
event_inherited();

tex = sprite_get_texture(tex_button, 0);
target = undefined;

timer = 20; //20 ingame frames until the button goes from active to inactive

active = false;
colFunc = function()
{
	if (active <= 0)
	{
		audio_play_sound(sndCoin, 0, false);
	}
	active = 1;
	if (!is_undefined(target))
	{
		target.active = true;
	}
}

shape = levelColmesh.addTrigger(new colmesh_cylinder(x + 16, y + 16, z, 0, 0, 1, 5, 5), colFunc);