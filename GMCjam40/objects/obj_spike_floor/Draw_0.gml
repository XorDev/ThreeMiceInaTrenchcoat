/// @description
-- countdown;
if (countdown < 0)
{
	countdown = 60;
	active = !active;
}
position += (active - position) * .2;

trigger.move(levelColmesh, x + 16, y + 16, z + height + h * (position - 1));


//Draw
deferred_set(false);
matrix_set(matrix_world, matrix_build(x, y, z + height + h * (position - 1), 0, 0, 0, 1, 1, 1));
vertex_submit(global.modSpikes, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();