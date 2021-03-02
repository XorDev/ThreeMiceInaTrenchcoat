/// @description

event_inherited();

function addToLevel()
{
	tex = sprite_get_texture(spr_brick, 0);
	
	//Add to colmesh
	var w = 32;
	var h = 64;
	var wt = 6; //Wall thickness
	var ct = 16; //Ceiling thickness
	levelColmesh.addShape(new colmesh_block(matrix_build(x + w / 2, y + wt / 2, z + h / 2, 0, 0, 0, w / 2, wt / 2, h / 2)));
	levelColmesh.addShape(new colmesh_block(matrix_build(x + w / 2, y + 64 - wt / 2, z + h / 2, 0, 0, 0, w / 2, wt / 2, h / 2)));
	levelColmesh.addShape(new colmesh_block(matrix_build(x + w / 2, y + h / 2, z + h - ct / 2, 0, 0, 0, w / 2, w / 2, ct / 2)));
	
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffTunnelHor, tex, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	//Destroy
	instance_destroy();
}