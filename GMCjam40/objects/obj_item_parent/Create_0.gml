///@desc

event_inherited();

bit = 0;
tex = -1;

//Pick up item
colFunc = function()
{
	obj_player.items |= bit;
	instance_destroy();
	levelColmesh.removeShape(shape);
	audio_play_sound(sndCoin, 0, false);
}

shape = levelColmesh.addTrigger(new colmesh_sphere(x, y, z, 8), colFunc);

function draw()
{
	matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	vertex_submit(model, pr_trianglelist, tex);
}