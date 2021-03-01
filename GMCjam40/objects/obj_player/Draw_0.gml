/// @description

//Draw mice
if (global.iframes > 0)
{
	if (global.iframes div 5) mod 2 == 0
	{
		exit;
	}
}
deferred_set(1);
for (var i = 0; i < array_length(global.mouseArray); i ++)
{
	global.mouseArray[i].draw();
	
	if (global.trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}
deferred_reset();

/*
deferred_set(0);

if (action)
{
	gpu_set_texfilter(false);
	matrix_set(matrix_world, matrix_build(x, y, z, -30, 0, 10, 1, 1, 1));
	vertex_submit(global.modSpeechBubble, pr_trianglelist, sprite_get_texture(spr_bubble, 0));
}

deferred_reset();
*/
matrix_set(matrix_world, matrix_build_identity());