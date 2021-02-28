/// @description

//Draw mice
deferred_set(1);
for (var i = 0; i < 3; i ++)
{
	mouseArray[i].draw();
	
	if (trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}
deferred_reset();
matrix_set(matrix_world, matrix_build_identity());