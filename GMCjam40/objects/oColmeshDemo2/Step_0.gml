/// @description
//Verlet integration
fric = 1 - .4;
spdX = (x - prevX) * fric;
spdY = (y - prevY) * fric;
spdZ = (z - prevZ) * (1 - 0.01);

var D = levelColmesh.getDeltaMatrix();
if (is_array(D))
{
	colmesh_matrix_multiply_fast(D, charMat, charMat);
	x = charMat[12];
	y = charMat[13];
	z = charMat[14];
}

prevX = x;
prevY = y;
prevZ = z;


//Controls
var jump = keyboard_check_pressed(vk_space);
var h = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var v = keyboard_check(ord("W")) - keyboard_check(ord("S"));
if (h != 0 && v != 0)
{	//If walking diagonally, divide the input vector by its own length
	var s = 1 / sqrt(2);
	h *= s;
	v *= s;
}

//Move
acc = 2;
x += spdX + acc * h;
y += spdY - acc * v;
z += spdZ - 1 + jump * ground * 15; //Apply gravity in z-direction

//Avoid ground
ground = false;
col = levelColmesh.displaceCapsule(x, y, z, xup, yup, zup, radius, height, 46, false);
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

//Put player in the middle of the map if he falls off
if (z < -400)
{
	x = room_width / 2;
	y = room_height / 2;
	z = 200;
	prevX = x;
	prevY = y;
	prevZ = z;
}

//Update character matrix
charMat[12] = x;
charMat[13] = y;
charMat[14] = z;
charMat[0] += h * .2;
charMat[1] -= v * .2;
colmesh_matrix_orthogonalize(charMat);

var d = 150;
global.camX = x + d * dcos(yaw) * dcos(pitch);
global.camY = y + d * dsin(yaw) * dcos(pitch);
global.camZ = z + d * dsin(pitch);
camera_set_view_mat(view_camera[0], matrix_build_lookat(global.camX, global.camY, global.camZ, x, y, z, xup, yup, zup));