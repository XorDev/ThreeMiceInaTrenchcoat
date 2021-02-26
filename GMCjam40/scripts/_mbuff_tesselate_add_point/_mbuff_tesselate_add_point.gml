/// @description _mbuff_tesselate_add_point(pointGrid, corner)
/// @param pointGrid
/// @param [uv]
/// @param startU
/// @param startV
function _mbuff_tesselate_add_point(argument0, argument1, argument2, argument3) {
	/*
		Adds a point to the active point grid. This is used for tesselating triangles to force UVs between 0 and 1.
	
		Script created by Sindre Hauge Larsen, 2019
		www.thesnidr.com
	*/
	var pointGrid = argument0;
	var vert = argument1;
	var startU = argument2;
	var startV = argument3;

	var xx = floor(vert[0]) - startU;
	var yy = floor(vert[1]) - startV;
	var dx = frac(vert[0]);
	var dy = frac(vert[1]);

	var array = pointGrid[# xx, yy];
	if !is_array(array)
	{
		array = [];
		pointGrid[# xx, yy] = array;
	}
	if _array_get_array_index(array, vert) < 0
	{
		array[@ array_length(array)] = vert;
	}

	if (dx == 0 && xx > 0)
	{
		array = pointGrid[# xx - 1, yy];
		if !is_array(array)
		{
			array = [];
			pointGrid[# xx - 1, yy] = array;
		}
		if _array_get_array_index(array, vert) < 0
		{
			array[@ array_length(array)] = vert;
		}
	}

	if (dy == 0 && yy > 0)
	{
		array = pointGrid[# xx, yy - 1];
		if !is_array(array)
		{
			array = [];
			pointGrid[# xx, yy - 1] = array;
		}
		if _array_get_array_index(array, vert) < 0
		{
			array[@ array_length(array)] = vert;
		}
	}

	if (dx == 0 && dy == 0 && xx > 0 && yy > 0)
	{
		array = pointGrid[# xx - 1, yy - 1];
		if !is_array(array)
		{
			array = [];
			pointGrid[# xx - 1, yy - 1] = array;
		}
		if _array_get_array_index(array, vert) < 0
		{
			array[@ array_length(array)] = vert;
		}
	}


}
