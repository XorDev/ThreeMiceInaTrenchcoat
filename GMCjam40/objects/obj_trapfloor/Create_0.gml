/// @description
event_inherited();

open = false;
angle = 0;

tex = sprite_get_texture(spr_icon_trapfloor, 0);

shape = -1;

timer = -1;

colFunc = function()
{
	if (timer <= 0 && open = false)
	{
		timer = 10;
	}
}

trigger = levelColmesh.addTrigger(new colmesh_sphere(x + 16, y + 16, z + 64, 12), colFunc);
shape = levelColmesh.addShape(new colmesh_cube(x + 16, y + 16, z + 64 - 16, 32));