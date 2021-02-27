///@desc enemy init

event_inherited();


#region Set different stats:
//Sight arc = min + add * awareness. High when chasing
sight_arc_min = 40;
sight_arc_add = 40;
//Sight range. Increases when chasing.
sight_range_min = 128;
sight_range_add = 128;

//Odds of seeing per step
attention = 10;
//How long he waits after sighting.
focus = 50;
//Idle looking arc.
look = 5;

//Jump speed and fall speed.
speed_jump = 3;
speed_fall = 0.4;
//Default speed + chase speed.
speed_min = 1;
speed_add = 2;

//Default turning speed + chase speed.
turn_min = 0.05;
turn_add = 0.15;

//Ground friction and air friction
fric_ground = 0.3;
fric_air = 0.03;
#endregion

function draw()
{
	var _sway = dcos(sway*5)*speed*3;
	matrix_set(matrix_world,matrix_build(x,y,z,_sway,0,face+90,4,4,4));
	vertex_submit(global.buf_pug,pr_trianglelist,global.tex_pug);
	matrix_set(matrix_world,matrix_build_identity());
}