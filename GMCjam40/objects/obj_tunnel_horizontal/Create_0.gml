/// @description

z = 0;
M = matrix_build(x, y, z, 0, 0, 0, 1, 1, 1);
tex = sprite_get_texture(spr_brick, 0);
function addToLevel()
{


	//Add collision shapes
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + 16, y + 4, z + 32, 0, 0, 0, 16, 4, 32)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + 16, y + 60, z + 32, 0, 0, 0, 16, 4, 32)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + 16, y + 30, z + 54, 0, 0, 0, 16, 32, 10)));
	
	//Add mesh to level geometry
	obj_level_geometry.addModel(global.modTunnelHor, tex, M)
	
	//instance_destroy();
}