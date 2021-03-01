/// @description
event_inherited();

floorModel = global.mbuffFloor;
wallModel = global.mbuffWallBridge;
floorTex = sprite_get_texture(spr_brick_top, 0);
wallTex = sprite_get_texture(spr_brick, 0);
tile = checkNeighbours();
width = 32;
height = 16;
deleteAfterUse = true;
z += 64 - 16;

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