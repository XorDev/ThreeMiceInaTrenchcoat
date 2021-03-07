///@desc Spawn mice
event_inherited();

global.nearestCage = 10000;

open = false;
zz = 0;
spr = spr_cage;

//Add collision shape
levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y, z + 30, 0, 0, 0, 22, 22, 30)));

if (global.mice<3)
{
	
	if irandom(1) && (global.mice==1)
	{
		var _m = global.mouseArray[1];
		_m.x = x+random_range(-20,20);
		_m.y = y+random_range(-20,20);
		_m.z = z+12;
		_m.lost = false;
		_m.angle = 360;
	}
	
	var _d = point_distance_3d(x, y, z, obj_player.x, obj_player.y, obj_player.z);
	if (_d <= global.nearestCage)
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