/// @description
//Shadow pass
light_set(1);
for (var i = 0; i < array_length(global.mouseArray); i ++)
{
	global.mouseArray[i].draw();
	
	if (global.trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}
light_reset();