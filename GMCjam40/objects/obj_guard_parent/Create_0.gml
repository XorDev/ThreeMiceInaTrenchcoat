///@desc enemy init

event_inherited();

#region enemy stats:
//Sight arc = min + add * awareness. High when chasing
sight_arc_min = 140;
sight_arc_add = -40;
//Sight range. Increases when chasing.
sight_range_min = 192;
sight_range_add = 128;

//Odds of seeing per step
attention = 6;
//How long he waits after sighting.
focus = 100;

//Jump speed and fall speed.
speed_jump = 3;
speed_fall = 0.2;
//Default speed + chase speed.
speed_min = 1;
speed_add = 3;

//Default turning speed + chase speed.
turn_min = 0.08;
turn_add = 0.12;

//Ground friction and air friction
fric_ground = 0.2;
fric_air = 0.02;
jumpy = 1;

snd_attack = snd_owl_attack;
snd_attack_played = 0;
snd_huh = snd_owl_huh;
snd_huh_played = 0;
#endregion

path = -1;
path_next = 1;

//Enemy variables:
//No animation currently
anim = true;
//Z-position and speed
xspeed = 0;
yspeed = 0;
zspeed = 0;
sspeed = 0;
//Animation Idle = 0, Run = 1
animation = -1;
//Face direction
face = 180;
//Awareness = 1 when chasing or capturing mouse
awareness = 0;
//Smooth random variable for turning
smooth = 0;
//Sway animation variable
sway = 0;

//Target struct, array id and position
target = -1;
target_id = -1;
target_x = xstart;
target_y = ystart;
target_z = z;
//True when a mouse is captured.
capture = 0;

function setTarget(tx,ty,tz)
{
	target_x = tx;
	target_y = ty;
	target_z = tz;
}

function pathNearest()
{
	var _value,_size,_px,_py,_pi,_nx,_ny;
	_value = 1000000;
	_size = path_get_number(path);
	_px = 0;
	_py = 0;
	_pi = 0;
	for(var i = 0;i<_size;i++)	
	{
		var _x,_y,_d;
		_x = path_get_point_x(path,i);
		_y = path_get_point_y(path,i);
		_d = distance_to_point(_x,_y);
		
		if (_d<_value) // New nearest
		{
			_value = _d;
			_px = _x; _py = _y;
			_pi = i;
		}
	}
	_nx = path_get_point_x(path,(_pi+1)%_size);
	_ny = path_get_point_y(path,(_pi+1)%_size);
	return [_px,_py,_nx,_ny];
}
