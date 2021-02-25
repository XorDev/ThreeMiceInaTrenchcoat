/// @description
event_inherited();

global.demoText = "You can add the following primitives to a ColMesh:"
	+ "\nSphere, axis-aligned cube, block, capsule, cylinder, torus, with more to come!"
	+ "\nThe player also seems to be casting a ray from his nose, that stops whenever it hits something..."
	+ "\nRay casting is exact against all primitives except the torus and disk, which use an approximation";

/*
	levelColmesh is a global variable in these demos.
	Instead of deleting and creating it over and over, the levelColmesh is simply cleared
	whenever you switch rooms.
	oColmeshSystem controls the levelColmesh, and makes sure it's cleared.
*/

//Create collision mesh from level model
var regionSize = 120; //<-- You need to define the size of the subdivision regions. Play around with it and see what value fits your model best. This is a list that stores all the triangles in a region in space. A larger value makes colmesh generation faster, but slows down collision detection. A too low value increases memory usage and generation time.
levelColmesh.subdivide(regionSize); //You can subdivide your colmesh and still add more objects to it! Any objects added after subdividing will still be added in the same way as if you had added them before subdividing.

//Create base platform
block = levelColmesh.addShape(new colmesh_block(matrix_build(room_width / 2, room_height / 2, -50, 0, 0, 0, room_width / 2, room_height / 2, 50)));

//Player variables
z = 200;
radius = 15;
height = 40;
prevX = x;
prevY = y;
prevZ = z;
xup = 0;
yup = 0;
zup = 1;
ground = false;
charMat = matrix_build(x, y, z, 0, 0, 0, 1, 1, height);

//Enable 3D projection
view_enabled = true;
view_visible[0] = true;
view_set_camera(0, camera_create());
gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);
camera_set_proj_mat(view_camera[0], matrix_build_projection_perspective_fov(-80, -window_get_width() / window_get_height(), 1, 32000));
yaw = 90;
pitch = 45;