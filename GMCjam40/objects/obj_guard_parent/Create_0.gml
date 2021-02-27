///@desc enemy init

#region enemy stats:
//Sight arc = min + add * awareness. High when chasing
sight_arc_min = 80;
sight_arc_add = 60;
//Sight range. Increases when chasing.
sight_range_min = 256;
sight_range_add = 128;

//Odds of seeing per step
attention = 6;
//How long he waits after sighting.
focus = 100;
//Idle looking arc.
look = 10;

//Jump speed and fall speed.
speed_jump = 5;
speed_fall = 0.3;
//Default speed + chase speed.
speed_min = 1;
speed_add = 2;

//Default turning speed + chase speed.
turn_min = 0.05;
turn_add = 0.15;

//Ground friction and air friction
fric_ground = 0.2;
fric_air = 0.02;
#endregion

//Enemy variables:
anim = false;
z = 0;
zspeed = 0;
face = 180;
target = -1;
awareness = 0;
smooth = 0;
sway = 0;

target_x = 0;
target_y = 0;
target_z = 0;