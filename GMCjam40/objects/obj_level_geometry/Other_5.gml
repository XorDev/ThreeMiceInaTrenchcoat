/// @description
for (var i = 0; i < ds_list_size(modelList); i ++)
{
	vertex_delete_buffer(modelList[| i][0]);
}
ds_list_clear(modelList);
ds_map_clear(texMap);