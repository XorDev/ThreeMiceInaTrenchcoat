///@desc Sight + movement

var _ground = (z==0);
if !irandom(attention)
{
	var _num = irandom(o_snidr_player.mice-1);
	target = o_snidr_player.mouseArray[_num];
	
	var _arc,_range;
	_arc = sight_arc_min+sight_arc_add*awareness;
	_range = sight_range_min+sight_range_add*awareness;
	sequence_create()
	
	var _dir,_dis;
	_dir = point_direction(x,y,target.x,target.y);
	_dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	
	if (abs(angle_difference(face,_dir))<_arc) &&	(_dis<_range) && !keyboard_check(vk_space)
	{
		//var _ray = levelColmesh.castRay(x,y,z,target.x,target.y,target.z,false);
		//if !is_array(_ray)
		{
			speed *= 1+_ground;
			zspeed = speed_jump*_ground;
			target_x = target.x;
			target_y = target.y;
			target_z = target.z;
			awareness = 1;
		}
	}
	else
	{
		target = -1;
		if (awareness <= random(1/focus))
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
_move = clamp(_dis/64-0.5,0,1)*(speed_min+awareness*speed_add);
hspeed = lerp(hspeed,+dcos(face)*_move,fric_air+fric_ground*_ground);
vspeed = lerp(vspeed,-dsin(face)*_move,fric_air+fric_ground*_ground);
zspeed = max(zspeed-speed_fall,-z);

var _dir,_swing;
_dir = point_direction(x,y,target_x,target_y);
_swing = look*cos(current_time/300+id);
_swing *= power((1-awareness)*awareness*4,6)-min(power(smooth,8)*14,1);
face += (turn_min+turn_add*awareness)*angle_difference(_dir,face)+_swing;