/// @description
event_inherited();

wallModel = global.mbuffWallHor64;
floorModel = global.mbuffFloor;
width = 32;
height = 64;
floorSprite = spr_brick;
wallSprite = spr_brick;

function addToLevel()
{
	//Add to colmesh
	shape = levelColmesh.addShape(new colmesh_cube(x + width / 2, y + width / 2, z + height / 2, width, width, height));
	
	//Add to level geometry
	var tile = obj_level_geometry.checkNeighbours(x, y, height, layer);
	obj_level_geometry.addTiledWalls(x, y, z, wallModel, wallSprite, width, tile);
	obj_level_geometry.addModel(floorModel, floorSprite, matrix_build(x, y, z + height, 0, 0, 0, 1, 1, 1));
}