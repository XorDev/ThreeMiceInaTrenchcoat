///@desc

event_inherited();

model = global.modCrown;
tex = sprite_get_texture(spr_crown,0);

bit = 8;

function draw()
{
	matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, 0, 0.4, 0.4, 0.4));
	vertex_submit(model, pr_trianglelist, tex);
}