///@desc Spawn mice

if (global.mice<3)
{
	var _d = point_distance(x,y,obj_player.x,obj_player.y);
	if irandom(1) && (global.mice==1)
	{
		var _m = global.mouseArray[1];
		_m.x = x+random_range(-20,20);
		_m.y = y+random_range(-20,20);
		_m.z = z+12;
		_m.lost = false;
		_m.angle = 360;
	}
	if (_d<=global.nearestCage)
	{
		global.nearestCage = _d;
		var _m = global.mouseArray[2];
		_m.x = x+random_range(-20,20);
		_m.y = y+random_range(-20,20);
		_m.z = z+12;
		_m.lost = false;
		_m.angle = 360;
		
	}
}