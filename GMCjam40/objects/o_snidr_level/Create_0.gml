/// @description
event_inherited();

global.demoText = "This demo shows how you can create a ColMesh from an OBJ file!"
	+ "\nIt also shows how you can push the player out of the ColMesh,"
	+ "\nand how you can use the collision system to collect coins";
	
//Load the level model to a vertex buffer
var mbuffLevel = colmesh_load_obj_to_buffer("test_level2.obj");
modLevel = vertex_create_buffer_from_buffer(mbuffLevel, global.ColMeshFormat);


/*
	levelColmesh is a global variable in these demos.
	Instead of deleting and creating it over and over, the levelColmesh is simply cleared
	whenever you switch rooms.
	oColmeshSystem controls the levelColmesh, and makes sure it's cleared.
*/
//First check if a cached ColMesh exists
if (true)//!levelColmesh.load("SnidrCache.cm"))
{
	//If a cache does not exist, generate a colmesh from an OBJ file, subdivide it, and save a cache
	levelColmesh.addMesh(mbuffLevel); //Notice how I supply a path to an OBJ file. I could have instead used the mbuffLevel that I created earlier in this event
	levelColmesh.subdivide(50); //<-- You need to define the size of the subdivision regions. Play around with it and see what value fits your model best. This is a list that stores all the triangles in a region in space. A larger value makes colmesh generation faster, but slows down collision detection. A too low value increases memory usage and generation time.
	//levelColmesh.save("Demo1Cache.cm"); //Save a cache, so that loading it the next time will be quicker
}

instance_create_depth(0, 0, 0, o_snidr_loadmodels);
instance_create_depth(0, 0, 0, o_snidr_camera);
with(instance_find(obj_player_start, 0)) {
	instance_create_depth(x, y, 0, o_snidr_player);
}
buffer_delete(mbuffLevel);