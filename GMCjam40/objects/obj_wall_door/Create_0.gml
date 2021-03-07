/// @description
event_inherited();

floorModel = global.mbuffFloor;
wallModel = global.mbuffWallDoor;
floorSprite = spr_brick;
wallSprite = spr_brick;
width = 64;
height = 128;

//The parent contains addToLevel(), which adds this tileable wall to the level

function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x+width-4, y, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y+width-4, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x+width-4, y+width-4, z + height / 2, 0, 0, 0, 4, 4, height / 2)));
	
	//Add to level geometry
	obj_level_geometry.addTiledWalls(x, y, z, wallModel, wallSprite, width, 0);
	
	obj_level_geometry.addModel(floorModel, floorSprite, matrix_build(x, y, z + 64, 0, 0, 0, 2, 2, 2));	
	
	//Destroy
	instance_destroy();
}