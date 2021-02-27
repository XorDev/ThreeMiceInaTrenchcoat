/// @description
tex = sprite_get_texture(tex_button, 0);
target = undefined;

//Cast a ray from high above to the ground so that the coin is placed onto the ground
var ray = levelColmesh.castRay(x + 16, y + 16, 1000, x + 16, y + 16, -100);
if (!is_array(ray))
{
	//The ray didn't hit anything, for some reason. Destroy this object
	instance_destroy();
	exit;
}
z = ray[2];
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