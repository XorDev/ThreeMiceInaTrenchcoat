/// @description
event_inherited();

function addToLevel()
{
	var _tex = sprite_get_texture(spr_cage, 0);
	
	//Add to colmesh
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y, z + 30, 0, 0, 0, 22, 22, 30)));
	
	obj_level_geometry.addModel(global.mbuffCage, _tex, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));	
}