/// @description
event_inherited();

open = false;
zz = 0;
tex = sprite_get_texture(spr_barrel2, 0);

function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_cylinder(x + 16, y + 16, z + 16, 0, 0, 1, 8, 16));
	
	obj_level_geometry.addModel(global.mbuffBarrel, tex, matrix_build(x + 16, y + 16, z, 0, 0, 0, 1, 1, 1));
	
	instance_destroy();
}

//The parent contains addToLevel(), which adds this tileable wall to the level
/*
function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + width / 2, y + width / 2, z + height / 2, 0, 0, 0, width / 2, width / 2, height / 2)));
	
	//Add to level geometry
	addTiledWalls(wallModel, tex, width, tile);
	
	obj_level_geometry.addModel(floorModel, tex, matrix_build(x, y, z + height, 0, 0, 0, 1, 1, 1));	
	
	//Destroy
	instance_destroy();
}