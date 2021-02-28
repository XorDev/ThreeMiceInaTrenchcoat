/// @description
event_inherited();

wallModel = global.mbuffWallHor64;
bridgeWall = global.mbuffWallHor64;
floorModel = global.mbuffFloor;
width = 32;
height = 64;
floorTex = sprite_get_texture(spr_brick, 0);
wallTex = sprite_get_texture(spr_brick, 0);
deleteAfterUse = true;

function addToLevel()
{
	//Add to colmesh
	shape = levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + width / 2, y + width / 2, z + height / 2, 0, 0, 0, width / 2, width / 2, height / 2)));
	
	//Add to level geometry
	addTiledWalls(wallModel, wallTex, width, tile);
	
	obj_level_geometry.addModel(floorModel, floorTex, matrix_build(x, y, z + height, 0, 0, 0, 1, 1, 1));	
	
	//Destroy
	if (deleteAfterUse)
	{
		instance_destroy();
	}
}

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
			if ((object_index != obj_wall_bridge && list[| i].object_index == obj_wall_bridge)){wallModel = bridgeWall; continue;}
			if (list[| i].object_index == obj_trapfloor){wallModel = bridgeWall; continue;}
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
			if ((object_index != obj_wall_bridge && list[| i].object_index == obj_wall_bridge)){wallModel = bridgeWall; continue;}
			if (list[| i].object_index == obj_trapfloor){wallModel = bridgeWall; continue;}
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
			if ((object_index != obj_wall_bridge && list[| i].object_index == obj_wall_bridge)){wallModel = bridgeWall; continue;}
			if (list[| i].object_index == obj_trapfloor){wallModel = bridgeWall; continue;}
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
			if ((object_index != obj_wall_bridge && list[| i].object_index == obj_wall_bridge)){wallModel = bridgeWall; continue;}
			if (list[| i].object_index == obj_trapfloor){wallModel = bridgeWall; continue;}
			tile += 8;
			break;
		}
	}
	ds_list_destroy(list);
	
	return tile;
}

function addTiledWalls(mesh, tex, size, tile)
{
	if (tile mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, tex, matrix_build(x + size, y + size, z, 0, 0, 90, 1, 1, 1));
	}
	if ((tile div 2) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, tex, matrix_build(x + size, y, z, 0, 0, 180, 1, 1, 1));
	}
	if ((tile div 4) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, tex, matrix_build(x, y, z, 0, 0, -90, 1, 1, 1));
	}
	if ((tile div 8) mod 2) == 0 //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, tex, matrix_build(x, y + size, z, 0, 0, 0, 1, 1, 1));
	}
}