/// @description

event_inherited();

function addToLevel()
{
	spr = spr_brick;
	
	//Add to colmesh
	var w = 32;
	var h = 32;
	var wt = 2; //Wall thickness
	levelColmesh.addShape(new colmesh_cube(x + w / 2, y + wt / 2, z + h / 2, w, wt, h));
	levelColmesh.addShape(new colmesh_cube(x + w / 2, y + 32 - wt / 2, z + h / 2, w, wt, h));
	levelColmesh.addShape(new colmesh_cube(x + w / 2, y + w / 2, z + 32 + 16, 32, 32, 32));
	
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffMouseHoleHor, spr, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	
	//Destroy
	instance_destroy();
}