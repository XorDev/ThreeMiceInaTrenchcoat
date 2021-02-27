/// @description
function loadObj(path)
{
	var buff = colmesh_load_obj_to_buffer(path);
	var vbuff = vertex_create_buffer_from_buffer(buff, global.ColMeshFormat);
	buffer_delete(buff);
	return vbuff;
}

//Load animated models
global.modMouse = smf_model_load("Characters/Mouse.smf");
global.modTrenchcoat = smf_model_load("Characters/MouseInTrenchcoat.smf");

//Load scenery
global.mbuffTunnelHor = colmesh_load_obj_to_buffer("Scenery/tunnel_hori_32x64.obj");
global.mbuffWallCornerBottomLeft = colmesh_load_obj_to_buffer("Scenery/wall_corner_bottomleft_32x32.obj");

//Load environment models
global.modButton = loadObj("Game objects/Button.obj");
global.modOwl = loadObj("Characters/Owl.obj");
global.modPug = loadObj("Characters/Pug.obj");

//Make sure the level colmesh exists
if !instance_exists(obj_colmesh)
{
	instance_create_depth(0, 0, 0, obj_colmesh);
}

//Make sure the deferred controller exists
if !instance_exists(obj_deferred_control)
{
	instance_create_depth(0, 0, 0, obj_deferred_control);
}

//Make sure the camera controller exists
if !instance_exists(obj_camera)
{
	instance_create_depth(0, 0, 0, obj_camera);
}

//Make sure the level geometry controller exists
if !instance_exists(obj_level_geometry)
{
	instance_create_depth(0, 0, 0, obj_level_geometry);
}
room_goto_next();