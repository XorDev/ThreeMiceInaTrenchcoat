/// @description
if global.disableDraw{exit;}

//Draw mice
for (var i = 0; i < mice; i ++)
{
	mouseArray[i].draw();
	
	if (trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}