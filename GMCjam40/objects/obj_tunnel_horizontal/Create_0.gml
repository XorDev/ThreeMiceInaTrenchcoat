/// @description
tex = sprite_get_texture(spr_brick, 0);

z = 0;

active = false;
colFunc = function()
{
	if (active <= 0)
	{
		audio_play_sound(sndCoin, 0, false);
	}
	active = 1;
	if (!is_undefined(target))
	{
		target.active = true;
	}
}
M = matrix_build(x, y, z, 0, 0, 0, 1, 1, 1);

levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + 16, y + 4, z + 32, 0, 0, 0, 16, 4, 32)));
levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + 16, y + 60, z + 32, 0, 0, 0, 16, 4, 32)));
levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x + 16, y + 30, z + 54, 0, 0, 0, 16, 32, 10)));