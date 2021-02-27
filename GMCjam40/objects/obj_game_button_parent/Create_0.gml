/// @description
tex = sprite_get_texture(tex_button, 0);
target = undefined;

//Cast a ray from high above to the ground so that the coin is placed onto the ground
var ray = levelColmesh.castRay(x, y, 1000, x, y, -100);
if (!is_array(ray))
{
	//The ray didn't hit anything, for some reason. Destroy this object
	instance_destroy();
	exit;
}
z = ray[2];

active = false;
colFunc = function()
{
	active = true;
	if (!is_undefined(target))
	{
		target.active = true;
	}
	//audio_play_sound(snd_buttonpress, 0, false);
}

shape = levelColmesh.addTrigger(new colmesh_cylinder(x, y, z, 0, 0, 1, 8, 5), colFunc);