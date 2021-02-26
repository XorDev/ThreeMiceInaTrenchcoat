/// @description

//Cast a ray from high above to the ground so that the coin is placed onto the ground
var ray = levelColmesh.castRay(x, y, 1000, x, y, -100);
if (!is_array(ray))
{
	//The ray didn't hit anything, for some reason. Destroy this coin.
	instance_destroy();
	exit;
}
radius = 10;
z = ray[2] + radius;
zstart = z;

//Create a collision function for the coin, telling it to destroy itself and remove its shape from the level ColMesh
colFunc = function()
{
	global.coins ++;					 //Increment the global variable "coins"
	instance_destroy();					 //This will destroy the current instance of oCoin
	levelColmesh.removeShape(shape);	 //"shape" is oCoin's shape variable. Remove it from the ColMesh
	audio_play_sound(sndCoin, 0, false); //Play coin pickup sound
}

//Create a spherical collision shape for the coin
//Give the coin the collision function we created. 
//The collision function will be executed if the player collides with the coin, using colmesh.displaceCapsule.
shape = levelColmesh.addTrigger(new colmesh_sphere(x, y, z, radius), colFunc);