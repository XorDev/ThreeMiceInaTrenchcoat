/// @description
modelList = ds_list_create();
texMap = ds_map_create();

function addModel(mesh, spr, matrix)
{
	var mbuff = texMap[? spr];
	if (is_undefined(mbuff))
	{
		mbuff = buffer_create(1, buffer_fixed, 1);
		texMap[? spr] = mbuff;
	}
	model_combine_ext(mbuff, mesh, matrix);
}

function model_combine_ext(trg, src, M) 
{
	//Create normal matrix from world matrix
	var N = array_create(16, 0);
	array_copy(N, 0, M, 0, 16);
	N[12] = 0;
	N[13] = 0;
	N[14] = 0;

	//Find sizes of buffers and resize the target buffer to new size
	var bytesPerVert = 3 * 4 + 3 * 4 + 2 * 4 + 4;
	var bytesPerTri = 3 * bytesPerVert;
	var srcSize = bytesPerTri * (buffer_get_size(src) div bytesPerTri);
	var trgSize = bytesPerTri * (buffer_get_size(trg) div bytesPerTri);
	buffer_resize(trg, srcSize + trgSize);
    buffer_copy(src, 0, srcSize, trg, trgSize);

	//Loop through the vertices of the source buffer
	for (var i = 0; i < srcSize; i += bytesPerVert)
	{
		//Read vertex position and normal from source buffer
		buffer_seek(src, buffer_seek_start, i);
		var vx = buffer_read(src, buffer_f32);
		var vy = buffer_read(src, buffer_f32);
		var vz = buffer_read(src, buffer_f32);
		var nx = buffer_read(src, buffer_f32);
		var ny = buffer_read(src, buffer_f32);
		var nz = buffer_read(src, buffer_f32);
	
		//Transform vertex position and normal
		var v = matrix_transform_vertex(M, vx, vy, vz);
		var n = matrix_transform_vertex(N, nx, ny, nz);
		var l = point_distance_3d(0, 0, 0, n[0], n[1], n[2]);
		if (l != 0)
		{
			l = 1 / l;
		}
	
		//Write vertex to target buffer
        buffer_seek(trg, buffer_seek_start, trgSize + i);
        buffer_write(trg, buffer_f32, v[0]);
        buffer_write(trg, buffer_f32, v[1]);
        buffer_write(trg, buffer_f32, v[2]);
        buffer_write(trg, buffer_f32, n[0] * l);
        buffer_write(trg, buffer_f32, n[1] * l);
        buffer_write(trg, buffer_f32, n[2] * l);
	}
}

function instance_position_layer(xx, yy, obj, layer)
{
	static list = ds_list_create();
	ds_list_clear(list);
	instance_position_list(xx, yy, obj, list, false);
	var num = ds_list_size(list);
	for (var i = num - 1; i >= 0; i --)
	{
		var ind = list[| i];
		if (layer == ind.layer)
		{
			return ind;
		}
	}
	return noone;
}

function checkNeighbours(xx, yy, height, layer)
{
	var tile = 0;
	xx += 16;
	yy += 16;
	
	//Check east
	var ind = instance_position_layer(xx + 32, yy, obj_wall_parent, layer);
	if (ind == noone)
	{
		tile |= 1;
	}
	else if (ind.height != height)
	{
		tile |= 16 | 1;
	}

	//Check north
	var ind = instance_position_layer(xx, yy - 32, obj_wall_parent, layer);
	if (ind == noone)
	{
		tile |= 2;
	}
	else if (ind.height != height)
	{
		tile |= 16 | 2;
	}

	//Check west
	var ind = instance_position_layer(xx - 32, yy, obj_wall_parent, layer);
	if (ind == noone)
	{
		tile |= 4;
	}
	else if (ind.height != height)
	{
		tile |= 16 | 4;
	}

	//Check south
	var ind = instance_position_layer(xx, yy + 32, obj_wall_parent, layer);
	if (ind == noone)
	{
		tile |= 8;
	}
	else if (ind.height != height)
	{
		tile |= 16 | 8;
	}
	
	return tile;
}

function addTiledWalls(x, y, z, mesh, spr, size, tile)
{
	if ((tile & 16) && (mesh == global.mbuffWallHorColumns64))
	{
		mesh = global.mbuffWallHor64;
	}
	
	if (tile & 1) //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, spr, matrix_build(x + size, y + size, z, 0, 0, 90, 1, 1, 1));
	}
	if (tile & 2) //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, spr, matrix_build(x + size, y, z, 0, 0, 180, 1, 1, 1));
	}
	if (tile & 4) //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, spr, matrix_build(x, y, z, 0, 0, -90, 1, 1, 1));
	}
	if (tile & 8) //If there is no wall beside this one, add a wall
	{
		obj_level_geometry.addModel(mesh, spr, matrix_build(x, y + size, z, 0, 0, 0, 1, 1, 1));
	}
}