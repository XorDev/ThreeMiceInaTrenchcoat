/// @description
timer = 60; //20 ingame frames until the button goes from active to inactive

h = 16;
active = 0;
position = 0;
countdown = 60;
colFunc = function()
{
	if (is_struct(global.currentCollider))
	{
		global.currentCollider.damaged();
	}
}

trigger = levelColmesh.addTrigger(new colmesh_sphere(x + 16, y + 16, z + height - h, 8), colFunc);