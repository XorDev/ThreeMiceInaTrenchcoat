/// @description
-- countdown;
if (countdown < 0)
{
	countdown = 60;
	active = !active;
	
	var _snd,_dis,_gain;
	_snd = active?snd_spike_up: snd_spike_down;
	_dis = point_distance_3d(x,y,z,obj_player.x,obj_player.y,obj_player.z);
	_gain = power(clamp(1-_dis/256,0,1),.25)*.2;
	sound_randomize(_snd,.2,.2,_gain);
}
position += (active - position) * .2;

trigger.move(levelColmesh, x + 16, y + 16, z + height + h * (position - 1));


//Draw
deferred_set(false);
matrix_set(matrix_world, matrix_build(x, y, z + height + h * (position - 1), 0, 0, 0, 1, 1, 1));
vertex_submit(global.modSpikes, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();