/// @description

//Shadow pass
light_set(1);
gpu_set_cullmode(cull_noculling);
for (var i = 0; i < mice; i ++)
{
	mouseArray[i].draw();
	
	if (trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}
light_reset();