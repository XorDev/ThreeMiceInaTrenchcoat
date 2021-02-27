/// @description
with obj_static
{
	addToLevel();
}

var tex = ds_map_find_first(texMap);
while !is_undefined(tex)
{
	var mbuff = texMap[? tex];
	var vbuff = vertex_create_buffer_from_buffer(mbuff, global.ColMeshFormat);
	ds_list_add(modelList, [vbuff, tex]);
	buffer_delete(mbuff);
	
	tex = ds_map_find_next(texMap, tex);
}