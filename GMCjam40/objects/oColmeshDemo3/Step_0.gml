/// @description
//Verlet integration
fric = .9 - .1 * ground;
spdX = (x - prevX) * fric;
spdY = (y - prevY) * fric;
spdZ = (z - prevZ) * fric;
prevX = x;
prevY = y;
prevZ = z;

//Controls
jump = keyboard_check_pressed(vk_space);
var h = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var v = keyboard_check(ord("W")) - keyboard_check(ord("S"));
if (h != 0 && v != 0)
{	//If walking diagonally, divide the input vector by its own length
	var s = 1 / sqrt(2);
	h *= s;
	v *= s;
}

//Move
var g = .8 - jump * ground * 20; //Gravity
var acc = 1. + ground * .3; //Acceleration
v *= acc;
h *= acc;
spdX += camMat[0] * v + camMat[4] * h - xup * g;
spdY += camMat[1] * v + camMat[5] * h - yup * g;
spdZ += camMat[2] * v + camMat[6] * h - zup * g;

//Apply speed to position
x += spdX;
y += spdY;
z += spdZ;

//Avoid ground
ground = false;
col = levelColmesh.displaceCapsule(x, y, z, xup, yup, zup, radius, height, 40, false);
if (col[6]) //If we're touching ground
{
	x = col[0];
	y = col[1];
	z = col[2];
	
	//We're touching ground if the dot product between the returned vector 
	if (xup * col[3] + yup * col[4] + zup * col[5] > 0.7)
	{
		ground = true;
	}
}

//Update up-direction so that it always points away from (0, 0, 0)
var l = point_distance_3d(0, 0, 0, x, y, z);
xup = x / l;
yup = y / l;
zup = z / l;

//Update camera matrix' up direction, and orthogonalize it
camMat[8] += xup * .2;
camMat[9] += yup * .2;
camMat[10] += zup * .2;
colmesh_matrix_orthogonalize(camMat);

//Update the player's matrix, making it point in the direction the player is moving, and making the up direction point upwards
charMat[12] = x;
charMat[13] = y;
charMat[14] = z;
charMat[8] += xup * .2;
charMat[9] += yup * .2;
charMat[10] += zup * .2;
colmesh_matrix_orthogonalize(charMat);

//Use the camera matrix and pitch variable to figure out how to displace the camera
var c = dcos(pitch);
var s = dsin(pitch);
camDirX = - camMat[0] * c + camMat[8] * s;
camDirY = - camMat[1] * c + camMat[9] * s;
camDirZ = - camMat[2] * c + camMat[10] * s;
var dist = 150;
global.camX = x + camDirX * dist;
global.camY = y + camDirY * dist;
global.camZ = z + camDirZ * dist;

//Update camera
camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, x, y, z, camMat[8], camMat[9], camMat[10]));