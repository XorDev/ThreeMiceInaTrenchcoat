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
global.modMouseFollower = smf_model_load("Characters/MouseFollower.smf");
global.modTrenchcoat = smf_model_load("Characters/MouseInTrenchcoat.smf");
global.modOwl = smf_model_load("Characters/Owl.smf");
global.modPugGuard = smf_model_load("Characters/PugGuard.smf");
global.modPugGuest = smf_model_load("Characters/PugGuest.smf");

//Load scenery (These must be loaded to buffers, not vertex buffers!)
global.mbuffTunnelHor = colmesh_load_obj_to_buffer("Scenery/tunnel_hori_32x64.obj");
global.mbuffWallCornerBottomLeft = colmesh_load_obj_to_buffer("Scenery/wall_corner_bottomleft_32x32.obj");
global.mbuffWallHor32 = colmesh_load_obj_to_buffer("Scenery/wall_hori_32x32.obj");
global.mbuffWallHor64 = colmesh_load_obj_to_buffer("Scenery/wall_hori_32x32x64.obj");
global.mbuffWallHorColumns64 = colmesh_load_obj_to_buffer("Scenery/wall_hori_columns_32x32x64.obj");
global.mbuffWallOuter = colmesh_load_obj_to_buffer("Scenery/OuterWall.obj");
global.mbuffWallBridge = colmesh_load_obj_to_buffer("Scenery/bridge_wall_32x32.obj");
global.mbuffWallDoor = colmesh_load_obj_to_buffer("Scenery/wall_door_32x64.obj");
global.mbuffFloor = colmesh_load_obj_to_buffer("Scenery/floor_32x32.obj");
global.mbuffStair = colmesh_load_obj_to_buffer("Scenery/stairs_vert_64x128x64.obj");
global.mbuffStairColmesh = colmesh_load_obj_to_buffer("Scenery/StairColmesh.obj");
global.mbuffMouseHoleHor = colmesh_load_obj_to_buffer("Scenery/mousehole_tunnel_hor_32x32.obj");
global.mbuffBarrel = colmesh_load_obj_to_buffer("Scenery/Barrel.obj");

//Load game objects (static ones must be loaded as buffers, not vertex buffers)
global.mbuffCage = colmesh_load_obj_to_buffer("Game objects/Cage.obj");
global.mbuffLadder = colmesh_load_obj_to_buffer("Game objects/Ladder.obj");
global.mbuffDoor = colmesh_load_obj_to_buffer("Game objects/Door.obj");

//Load environment models
global.modCageDoor = loadObj("Game objects/CageDoor.obj");
global.modSpikes = loadObj("Game objects/Spikes.obj");
global.modButton = loadObj("Game objects/Button.obj");
global.modTrapFloor = loadObj("Scenery/floor_32x32.obj");
global.modDoor = loadObj("Game objects/Door.obj");
global.modSpeechBubble = loadObj("Scenery/SpeechBubble.obj");

//Items
global.modKey = loadObj("Items/Key.obj");
global.modBone = loadObj("Items/Bone.obj");

//Various
global.climbdir = 0;
global.texPixelSize = 1 / 5;
global.mice = 0;
global.currentCollider = -1;

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

//Audio controller
if !instance_exists(obj_audio_control)
{
	instance_create_depth(0, 0, 0, obj_audio_control);
}
room_goto_next();