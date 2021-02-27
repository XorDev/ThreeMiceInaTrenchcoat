/// @description
function loadObj(path)
{
	var buff = colmesh_load_obj_to_buffer(path);
	var vbuff = vertex_create_buffer_from_buffer(buff, global.ColMeshFormat);
	buffer_delete(buff);
	return vbuff;
}

//Load animated models
global.modMouse = smf_model_load("Mouse.smf");
global.modTrenchcoat = smf_model_load("MouseInTrenchcoat.smf");

//Load environment models
global.modButton = loadObj("Game objects/Button.obj");


room_goto_next();