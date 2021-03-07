/// @description

event_inherited();

function addToLevel()
{
	spr = spr_brick;
	
	//Add to colmesh
	var w = 32;
	var h = 64;
	var wt = 6; //Wall thickness
	var ct = 16; //Ceiling thickness
	levelColmesh.addShape(new colmesh_cube(x + w / 2, y + wt / 2, z + h / 2, w, wt, h));
	levelColmesh.addShape(new colmesh_cube(x + w / 2, y + 64 - wt / 2, z + h / 2, w, wt, h));
	levelColmesh.addShape(new colmesh_cube(x + w / 2, y + h / 2, z + h - ct / 2, w, w, ct));
	
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffTunnelHor, spr, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	//Destroy
	instance_destroy();
}