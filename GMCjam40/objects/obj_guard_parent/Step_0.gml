///@desc Sight + movement

var _ground;
_ground = (z==0);

#region Capture mouse
if (target_id>-1)
{
	var _dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	if (_dis<16)
	{
		//Lunge at mouse
		hspeed += (target.x-x)/4;
		vspeed += (target.y-y)/4;
		//If targeting a mouse, capture it
		target_id = -1;
		capture = 1;
		//Just to prevent errors.
		if (o_snidr_player.mice>1) o_snidr_player.mice--;
	}
}
#endregion

//Return mouse to cage?
if capture
{
	//Insert location of cage
	target_x = 0;
	target_y = 0;
	target_z = 0;
	awareness = 1;
}
//Randomly check for mice
else if !irandom(attention)
{
	//Pick and random mouse (preferring last mouse)
	target_id = max(target_id,irandom(o_snidr_player.mice-1));
	target = o_snidr_player.mouseArray[target_id];
	
	//Get sight arc and range
	var _arc,_range;
	_arc = sight_arc_min+sight_arc_add*awareness;
	_range = sight_range_min+sight_range_add*awareness;
	
	//Direction and distance to mouse
	var _dir,_dis;
	_dir = point_direction(x,y,target.x,target.y);
	_dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	
	//If in sight range
	if (abs(angle_difference(face,_dir))<_arc) &&	(_dis<_range)
	{
		//Maybe Snidr can figure out a better way to do this...
		
		//var _ray = levelColmesh.castRay(x,y,z,target.x,target.y,target.z,false);
		//if !is_array(_ray) 
		{
			//Jump
			zspeed = speed_jump*_ground;
			//Set target
			target_x = target.x;
			target_y = target.y;
			target_z = target.z;
			//Maximize awareness
			awareness = 1;
		}
	}
	else
	{
		//Otherwise report nothing
		target_id = -1;
		target = -1;
		//Lose interest and move back to the starting postion
		if (awareness <= random(1/focus))
		{
			target_x = xstart;
			target_y = ystart;
		}
	}
}

//Gradually lose interest
awareness *= .99;
//Smooth random number
smooth = lerp(smooth,random(1),.1);
//Add to sway position for wobble animation
sway += speed;

var _dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
//End capture if close enough
if capture && (_dis<32)
{	
	capture = 0;
	awareness = 0;
}
//Move speed based on distance and awareness.
var _move = clamp(_dis/64-1+2*awareness,0,1)*(speed_min+awareness*speed_add);
//Update speeds
hspeed = lerp(hspeed,+dcos(face)*_move,fric_air+fric_ground*_ground);
vspeed = lerp(vspeed,-dsin(face)*_move,fric_air+fric_ground*_ground);
zspeed = max(zspeed-speed_fall,-z);
//Move zspeed.
z += zspeed;

//Update facement direction
var _dir,_swing;
_dir = point_direction(x,y,target_x,target_y);
//Random swinging for extra visibility.
_swing = look*cos(current_time/300+id);
_swing *= power((1-awareness)*awareness*4,6)-min(power(smooth,8)*14,1);
face += (turn_min+turn_add*awareness)*angle_difference(_dir,face+_swing);