/// @description
event_inherited();

//Check neighbours for tiles
tile = checkNeighbours();

function addToLevel()
{
	tex = sprite_get_texture(spr_brick, 0);
	
	//Add to colmesh
	levelColmesh.addShape(new colmesh_cube(x + 16, y + 16, z + 16, 16));
	
	//Add to level geometry
	addTiledWalls(global.mbuffWallWallHor, tex, 32, tile);
	obj_level_geometry.addModel(global.mbuffFloor, tex, matrix_build(x, y, z + 32, 0, 0, 0, 1, 1, 1));	
	
	//Destroy
	instance_destroy();
}