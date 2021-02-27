/// @description
z = 0;
event_inherited();

type = 0;
var xx = x + 16;
var yy = y + 16;
if (instance_position(xx + 32, yy, obj_wall_parent) != noone)
{
	type += 1;
}
if (instance_position(xx, yy - 32, obj_wall_parent) != noone)
{
	type += 2;
}
if (instance_position(xx - 32, yy, obj_wall_parent) != noone)
{
	type += 4;
}
if (instance_position(xx, yy + 32, obj_wall_parent) != noone)
{
	type += 8;
}

function addToLevel()
{
	tex = sprite_get_texture(spr_brick, 0);
	
	//Add to colmesh
	levelColmesh.addShape(new colmesh_cube(x + 16, y + 16, z + 16, 32));
	
	//Add to level geometry
	if (type mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x + 32, y, z, 0, 0, -90, 1, 1, 1));
	}
	if ((type div 2) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	}
	if ((type div 4) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x, y, z, 0, 0, -90, 1, 1, 1));
	}
	if ((type div 8) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x, y + 32, z, 0, 0, 0, 1, 1, 1));
	}
	
	//Destroy
	instance_destroy();
}