///@desc Sight + movement
var _ground,_h,_r,_col;
_ground = 0;
_h = 20;
_r = 18;
_col = levelColmesh.displaceCapsule(x, y, z+_r, 0, 0, 1, _r, _h, 40, true, false);
if _col[6]
{
	x = _col[0];
	y = _col[1];
	z = _col[2]-_r;
	_ground = (_col[5] > 0.7);
}


#region Capture mouse
if (target_id>-1)
{
	var _dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	if (_dis<24)
	{
		//Lunge at mouse
		xspeed += (target.x-x)/8;
		yspeed += (target.y-y)/8;
		//If targeting a mouse, capture it
		capture = 1;
		
		//Remove mice if possible
		if (obj_player.mice>1)
		{
			obj_player.mice--;
		}
		else
		{
			room_goto(rm_menu);
		}
	}
}
#endregion

//Return mouse to cage?
if capture
{
	var _i,_x,_y,_z;
	_i = instance_nearest(x,y,obj_cage);
	_x = _i.x; _y = _i.y; _z = _i.z;
	//Try to get to cage
	setTarget(_x,_y,_z);
	awareness = 1;
	
}
//Randomly check for mice
else if !irandom(attention)
{
	//Pick and random mouse (preferring last mouse)
	var _n = obj_player.mice-1;
	target_id = min(max(target_id,irandom(_n)),_n);
	target = obj_player.mouseArray[target_id];
	
	//Get sight arc and range
	var _arc,_range;
	_arc = sight_arc_min+sight_arc_add*awareness;
	_range = sight_range_min+sight_range_add*awareness;
	
	//Direction and distance to mouse
	var _dir,_dis,_ver;
	_dir = point_direction(x,y,target.x,target.y);
	_dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	_ver = abs(z-target.z);
	
	//If in sight range
	if (abs(angle_difference(face,_dir))<_arc) && (_dis<_range) && (_ver<60)
	{
		var _ray = levelColmesh.castRay(x,y,z+8,target.x,target.y,target.z);
		if (!is_array(_ray))
		{
			setTarget(target.x,target.y,target.z);
			//Jump
			zspeed = speed_jump*_ground*!irandom(jumpy);
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
			var _dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
			if (_dis>64)
			{
				setTarget(xstart,ystart,z)
			}
		}
	}
}

//Gradually lose interest
awareness *= .99;
//Smooth random number
smooth = lerp(smooth,random(1),.1);
//Add to sway position for wobble animation
sway += speed;

//Return mouse to cage
if capture
{
	var _i,_x,_y,_z;
	_i = instance_nearest(x,y,obj_cage);
	_x = _i.x; _y = _i.y; _z = _i.z;
	var _dis = point_distance_3d(x,y,z,_x,_y,_z);
	if (_dis<80)
	{
		//Return to post
		target.x = _x+random_range(-20,20);
		target.y = _y+random_range(-20,20);
		target.z = _z+8;
		target_id = -1;
		capture = 0;
		awareness = 0;
	}
}
var _dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
//Move speed based on distance and awareness.
var _move = clamp(_dis/64-1+awareness,0,1)*(speed_min+awareness*speed_add);
//Update speeds
xspeed = lerp(xspeed,+dcos(face)*_move,fric_air+fric_ground*_ground);
yspeed = lerp(yspeed,-dsin(face)*_move,fric_air+fric_ground*_ground);
zspeed = zspeed-speed_fall;
if (_ground) zspeed = max(zspeed,0);


//Move position
x += xspeed;
y += yspeed;
z += _ground? max(zspeed,0) : zspeed;
if (z<-400)
{
	//Give a mouse back
	if capture && (target_id>-1)  obj_player.mice++;
	instance_destroy();
}

//Update facement direction
var _dir;
_dir = point_direction(x,y,target_x,target_y);
face += (turn_min+turn_add*awareness)*angle_difference(_dir,face);

var _speed = point_distance(0,0,xspeed,xspeed);
if (_speed > .1)
{
	var animSpd = instance.getAnimSpeed("Run");
	if (animation != 1) instance.play("Run", animSpd, 1, false);
	animation = 1;
}
else
{
	var animSpd = instance.getAnimSpeed("Idle");
	if (animation != 0) instance.play("Idle", animSpd, 1, false);
	animation = 0;
}
instance.step(1);