///@desc movement
if !irandom(6)
{
	var _num = irandom(o_snidr_player.mice-1);
	target = o_snidr_player.mouseArray[_num];
	
	var _arc,_range;
	_arc = 60+30*awareness;
	_range = 128+128*awareness;
	
	var _dir,_dis;
	_dir = point_direction(x,y,target.x,target.y);
	_dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	
	if (abs(angle_difference(face,_dir))<60) &&	(_dis<256)
	{
		//var _ray = levelColmesh.castRay(x,y,z,target.x,target.y,target.z,false);
		//if !is_array(_ray)
		{
			zspeed = 5*(z==0);
			target_x = target.x;
			target_y = target.y;
			target_z = target.z;
			awareness = 1;
		}
	}
	else
	{
		target = -1;
	}
}

awareness *= .99;
z += zspeed;

var _dis;
_dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
_move = max((_dis>32)*awareness,(target>0))*5;
hspeed = lerp(hspeed,+dcos(face)*_move,.1);
vspeed = lerp(vspeed,-dsin(face)*_move,.1);
zspeed = max(zspeed-.3,-z);

var _dir;
_dir = point_direction(x,y,target_x,target_y);
face += .2*angle_difference(_dir,face);