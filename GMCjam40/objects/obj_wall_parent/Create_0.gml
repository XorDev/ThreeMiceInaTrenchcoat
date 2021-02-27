/// @description
z = depth / 100 * 32;
type = 0;

function checkNeighbours()
{
	tile = 0;
	
	var xx = x + 16;
	var yy = y + 16;
	var list = ds_list_create();
	
	//Check east
	instance_position_list(xx + 32, yy, obj_wall_parent, list, false)
	for (var i = ds_list_size(list) - 1; i >= 0; i --)
	{
		if (layer == list[| i].layer)
		{
			tile += 1;
			break;
		}
	}
	ds_list_clear(list);

	//Check north
	instance_position_list(xx, yy - 32, obj_wall_parent, list, false)
	for (var i = ds_list_size(list) - 1; i >= 0; i --)
	{
		if (layer == list[| i].layer)
		{
			tile += 2;
			break;
		}
	}
	ds_list_clear(list);

	//Check west
	instance_position_list(xx - 32, yy, obj_wall_parent, list, false)
	for (var i = ds_list_size(list) - 1; i >= 0; i --)
	{
		if (layer == list[| i].layer)
		{
			tile += 4;
			break;
		}
	}
	ds_list_clear(list);

	//Check south
	instance_position_list(xx, yy + 32, obj_wall_parent, list, false)
	for (var i = ds_list_size(list) - 1; i >= 0; i --)
	{
		if (layer == list[| i].layer)
		{
			tile += 8;
			break;
		}
	}
	ds_list_destroy(list);
	
	return tile;
}

function addTiledWalls(mesh, tex, size)
{
	if (tile mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x + size, y, z, 0, 0, -90, 1, 1, 1));
	}
	if ((tile div 2) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	}
	if ((tile div 4) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(global.mbuffWallWallHor, tex, matrix_build(x, y, z, 0, 0, -90, 1, 1, 1));
	}
	if ((tile div 8) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, tex, matrix_build(x, y + size, z, 0, 0, 0, 1, 1, 1));
	}
}