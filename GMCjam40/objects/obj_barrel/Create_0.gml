/// @description
event_inherited();

x += random_range(-4,4);
y += random_range(-4,4);

open = false;
zz = 0;
spr = spr_barrel2;

function addToLevel()
{
	//Add to colmesh
	levelColmesh.addShape(new colmesh_cylinder(x + 16, y + 16, z + 16, 0, 0, 1, 8, 16));
	
	obj_level_geometry.addModel(global.mbuffBarrel, spr, matrix_build(x + 16, y + 16, z, 0, 0, 0, 1, 1, 1));
	
	instance_destroy();
}