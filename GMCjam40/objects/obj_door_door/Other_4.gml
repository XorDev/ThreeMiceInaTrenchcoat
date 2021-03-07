/// @description Insert description here
// You can write your code in this editor
event_inherited();

open = false;
spr = spr_cage;

update_z_value();

function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y, z, 0, 0, 0, 22, 22, 30)));
	
	obj_level_geometry.addModel(global.mbuffDoor, spr, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));	
}