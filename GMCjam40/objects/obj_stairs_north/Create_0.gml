/// @description
event_inherited();

function addToLevel()
{
	spr = spr_brick;
	
	//Add to colmesh
	levelColmesh.addMesh(global.mbuffStairColmesh, matrix_build(x, y, z, 0, 0, 0, 1, image_yscale, 1));
	
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffStair, spr, matrix_build(x, y, z, 0, 0, 0, 1, image_yscale, 1));	
	
	//Destroy
	instance_destroy();
}