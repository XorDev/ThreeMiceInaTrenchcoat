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

global.modOwl = loadObj("Owl.obj");
global.modPug = loadObj("Pug.obj");

global.texOwl = sprite_get_texture(spr_owl,0);
global.texPug = sprite_get_texture(spr_pug,0);


//Make sure the level colmesh exists
if !instance_exists(obj_colmesh)
{
	instance_create_depth(0, 0, 0, obj_colmesh);
}
room_goto_next();