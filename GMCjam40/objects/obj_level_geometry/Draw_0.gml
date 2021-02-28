/// @description
matrix_set(matrix_world, matrix_build_identity());
//Deferred pass
deferred_set(0);
gpu_set_cullmode(cull_noculling);
//Draw the level
for (var i = 0; i < ds_list_size(modelList); i ++)
{
	var ind = modelList[| i];
	vertex_submit(ind[0], pr_trianglelist, ind[1]);
}
deferred_reset();