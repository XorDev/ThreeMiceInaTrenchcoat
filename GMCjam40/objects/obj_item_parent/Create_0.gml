///@desc

event_inherited();

bit = 0;
tex = sprite_get_texture(spr_white,0);
model = global.modKey;

//Pick up item
colFunc = function()
{
	global.items |= bit;
	
	if (bit==8)
	{
		room_goto(rm_menu_win)	;
	}
	instance_destroy();
	levelColmesh.removeShape(shape);
	
	sound_randomize(snd_equip,.2,.2,1);
}

shape = levelColmesh.addTrigger(new colmesh_sphere(x, y, z, 8), colFunc);

function draw()
{
	matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	vertex_submit(model, pr_trianglelist, tex);
}