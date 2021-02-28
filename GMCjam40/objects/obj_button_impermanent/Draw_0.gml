/// @description

//Draw
deferred_set(false);
matrix_set(matrix_world, matrix_build(x + 16, y + 16, z - position * 4, 0, 0, 0, 1, 1, 1));
vertex_submit(global.modButton, pr_trianglelist, tex);
matrix_set(matrix_world, matrix_build_identity());
deferred_reset();

position += (activated - position) * .2;

if (activated<position) && release
{
	release = 0;
	sound_randomize(snd_click2,.2,.2,.5);
}
activated = false;
