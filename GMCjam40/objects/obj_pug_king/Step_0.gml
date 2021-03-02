///@desc Animate
///@desc Sight + movement
var _px,_py,_pz;
_px = x;
_py = y;
_pz = z;

var _ground,_h,_r,_col;
_ground = 0;
_h = 20;
_r = 8;
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
		
		//Remove mice if possible
		if (global.mice>1)
		{
			global.mice--;
		}
		else
		{
			room_goto(rm_menu_lose);
		}
	}
}
#endregion


//Randomly check for mice
if !irandom(attention) && !bone
{
	//Pick and random mouse (preferring last mouse)
	var _n = global.mice-1;
	target_id = _n*!global.trenchcoat;
	target = global.mouseArray[target_id];

	//Get sight arc and range
	var _arc,_range;
	_arc = sight_arc_min+sight_arc_add*awareness;
	_range = sight_range_min+sight_range_add*awareness;

	//Direction and distance to mouse
	var _dir,_dis,_ver;
	_dir = point_direction(x,y,target.x,target.y);
	_dis = point_distance_3d(x,y,z,target.x,target.y,target.z);
	_ver = abs(z-target.z);

	var _sighting = 0;
	//If in sight range
	if (abs(angle_difference(face,_dir))<_arc) && (_dis<_range) && (_ver<60)
	{
		var _ray = levelColmesh.castRay(x,y,z+8,target.x,target.y,target.z);
		if (!is_array(_ray))
		{
			if !snd_attack_played sound_randomize(snd_attack,.2,.2,1);
			snd_attack_played = 1;
			setTarget(target.x,target.y,target.z);
			//Jump
			zspeed = speed_jump*_ground*!irandom(jumpy);
			//Maximize awareness
			awareness = 1;
			_sighting = 1;
			
			path_next = 0;
			sight+=attention;
		}
	}
	if !_sighting
	{
		//Otherwise report nothing
		target_id = -1;
		target = -1;
		//Lose interest and move back to the starting postion
		if (awareness <= random(1/focus))
		{
			snd_attack_played = 0;
			
			var _dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
			//Too far from target
			if (_dis>64)
			{
				snd_huh_played = 0;
				setTarget(xstart,ystart,z);
			}
		}
	}
}

//Gradually lose interest
awareness *= .99;
sight = max(sight-.2,0);
//Smooth random number
smooth = lerp(smooth,random(1),.1);

var _dis = point_distance_3d(x,y,z,target_x,target_y,target_z);
//Move speed based on distance and awareness.
var _move = (_dis>8)*(speed_min+awareness*speed_add);
//Update speeds
xspeed = lerp(xspeed,+dcos(face)*_move,fric_air+fric_ground*_ground);
yspeed = lerp(yspeed,-dsin(face)*_move,fric_air+fric_ground*_ground);
zspeed = zspeed-speed_fall;
if (_ground) zspeed = max(zspeed,0);


//Move position
x += xspeed;
y += yspeed;
z += _ground? max(zspeed,0) : zspeed;
sspeed = lerp(sspeed, point_distance_3d(x,y,z,_px,_py,_pz), .1);

if (z<-400)
{
	var _i = instance_create_depth(x,y,0,obj_item_crown);
	_i.z = obj_player.z;
	instance_destroy();
}

//Update facement direction
var _dir,_t;
_dir = point_direction(x,y,target_x,target_y);
//Cheap wall avoiding:
_t = max(_move-sspeed-1,0)*50;
face += (turn_min+turn_add*awareness)*angle_difference(_dir,face+_t);

var _speed = point_distance(0,0,xspeed,xspeed);
if (bone != 2)
{
	if (_speed > .1)
	{
		if (_speed>speed_min)
		{
			var animSpd = instance.getAnimSpeed("Run");
			if (animation != 2) instance.play("Run", animSpd, 1, false);
			animation = 2;
		}
		else
		{
			var animSpd = instance.getAnimSpeed("Walk");
			if (animation != 1) instance.play("Walk", animSpd, 1, false);
			animation = 1;
		}
		if !(steps++%20)
		{
			var _snd,_dis,_gain;
			_snd = choose(snd_step0,snd_step1,snd_step2,snd_step3,snd_step4,snd_step5,snd_step6);
			_dis = point_distance_3d(x,y,z,obj_player.x,obj_player.y,obj_player.z);
			_gain = clamp(1-_dis/512,0,.5);
			sound_randomize(_snd,.2,.2,_gain);
		}
	}
	else
	{
		var animSpd = instance.getAnimSpeed("Idle");
		if (animation != 0) instance.play("Idle", animSpd, 1, false);
		animation = 0;
	}
}

if instance_exists(obj_item_bone)
{
	if !snd_huh_played sound_randomize(snd_huh,.2,.2,1);
	snd_huh_played = 1;
	var _i,_d;
	_i = obj_item_bone;
	_d = point_distance_3d(x,y,z,_i.x,_i.y,_i.z);
	if (_d<512)
	{
		bone = 1;
		setTarget(_i.x,_i.y,_i.z);
		awareness = awareness*.9+.1;
	
		if (_d<16)
		{
			//pick up
			if (animation != 3)
			{
				var animSpd = instance.getAnimSpeed("Pickup")/3;
				instance.play("Pickup", animSpd, 1, false);
				animation = 3;
				alarm[0] = 60*2;
				
			}
			bone = 2;
		}
	}
	
	
}
else
{
	bone = 0;	
}
instance.step(1);

/*
if keyboard_check_pressed(vk_space)
{
	go = 1;
	var animSpd = instance.getAnimSpeed("Walk");
	instance.play("Walk", animSpd, 1, 1);
}
if go
{
	var _x,_y;
	_x = obj_trapfloor.x+16;
	_y = obj_trapfloor.y+16;
	var _dis,_dir;
	_dis = point_distance(x,y,_x,_y);
	_dir = point_direction(x,y,_x,_y);
	face += .1*angle_difference(_dir,face)*(_dis>20);
	
	if (_dis<20)
	{
		var animSpd = instance.getAnimSpeed("Pickup");
		if (speed>.9) instance.play("Pickup", animSpd/2, 2, 1);
	}
	
	speed = speed*.9+.2*(_dis>20);
	direction = face;
	
	
}

instance.step(1);*/