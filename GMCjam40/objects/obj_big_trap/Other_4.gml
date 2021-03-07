/// @description
event_inherited();

open = false;
angle = 0;

tex = sprite_get_texture(spr_ground_trap, 0);

shape = -1;

timer = -1;

colFunc = function()
{
	if (timer <= 0 && open = false)
	{
		timer = 10;
	}
}

trigger = levelColmesh.addTrigger(new colmesh_sphere(x + 16, y + 16, z + 64, 24), colFunc);
shape = levelColmesh.addShape(new colmesh_cube(x + 16, y + 16, z + 64 - 32, 64, 64, 64));