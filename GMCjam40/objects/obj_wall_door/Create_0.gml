/// @description
event_inherited();

floorModel = global.mbuffFloor;
wallModel = global.mbuffWallDoor;
floorTex = sprite_get_texture(spr_wall_low, 0);
wallTex = sprite_get_texture(spr_brick, 0);
tile = checkNeighbours();
width = 64;
height = 128;
deleteAfterUse = true;

//The parent contains addToLevel(), which adds this tileable wall to the level

function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x+width-4, y, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y+width-4, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x+width-4, y+width-4, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	
	//Add to level geometry
	addTiledWalls(wallModel, wallTex, width, 0);
	
	obj_level_geometry.addModel(floorModel, floorTex, matrix_build(x, y, z + height, 0, 0, 0, 1, 1, 1));	
	
	//Destroy
	instance_destroy();
}