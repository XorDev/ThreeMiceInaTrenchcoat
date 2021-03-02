///@desc Spawn mice

if (global.mice<3)
{
	var _m = global.mouseArray[global.mice];
	_m.x = x+random_range(-20,20);
	_m.y = y+random_range(-20,20);
	_m.z = z+12;
	_m.lost = false;
	_m.angle = 360;
}