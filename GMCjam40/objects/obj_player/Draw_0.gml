/// @description

//Draw mice
if (iframes > 0)
{
	if (iframes div 5) mod 2 == 0
	{
		exit;
	}
}
deferred_set(1);
for (var i = 0; i < global.mice; i ++)
{
	global.mouseArray[i].draw();
	
	if (trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}
deferred_reset();
matrix_set(matrix_world, matrix_build_identity());