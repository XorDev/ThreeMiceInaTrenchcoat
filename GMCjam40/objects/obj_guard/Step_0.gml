///@desc Sight + movement

var _ground = (z==0);
if !irandom(6)
{
	var _num = irandom(o_snidr_player.mice-1);
	target = o_snidr_player.mouseArray[_num];
	
	var _arc,_range;
	_arc = 80+60*awareness;
	_range = 256+128*awareness;
	sequence_create()
	
	var _dir,_dis;
	_dir = point_direction(x,y,target.x,target.y);
	_dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	
	if (abs(angle_difference(face,_dir))<_arc) &&	(_dis<_range) && !keyboard_check(vk_space)
	{
		//var _ray = levelColmesh.castRay(x,y,z,target.x,target.y,target.z,false);
		//if !is_array(_ray)
		{
			zspeed = 5*_ground;
			target_x = target.x;
			target_y = target.y;
			target_z = target.z;
			awareness = 1;
		}
	}
	else
	{
		target = -1;
		if (awareness <= random(.01))
		{
			target_x = xstart;
			target_y = ystart;
		}
	}
}

awareness *= .99;
smooth = lerp(smooth,random(1),.1);
z += zspeed;
sway += speed;

var _dis;
_dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
_move = clamp(_dis/32-1,0,2)*(.5+awareness*2);
hspeed = lerp(hspeed,+dcos(face)*_move,.02+.2*_ground);
vspeed = lerp(vspeed,-dsin(face)*_move,.02+.2*_ground);
zspeed = max(zspeed-.3,-z);

var _dir,_swing;
_dir = point_direction(x,y,target_x,target_y);
_swing = 10*cos(current_time/300+id);
_swing *= power((1-awareness)*awareness*4,6)-min(power(smooth,8)*14,1);
face += (.05+.15*awareness)*angle_difference(_dir,face)+_swing;