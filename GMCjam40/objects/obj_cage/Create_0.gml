/// @description

event_inherited();

global.nearestCage = 10000;

open = false;
zz = 0;
tex = sprite_get_texture(spr_cage, 0);

function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y, z + 30, 0, 0, 0, 22, 22, 30)));
	
	obj_level_geometry.addModel(global.mbuffCage, tex, matrix_build(x, y, z, 0, 0, -90, 1, 1, 1));	
}