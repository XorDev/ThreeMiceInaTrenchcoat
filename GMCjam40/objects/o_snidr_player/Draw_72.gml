/// @description
if global.disableDraw{exit;}

//Shadow pass
var _cx,_cy,_cz;
_cx = lerp(o_snidr_player.x,global.camX,-2);
_cy = lerp(o_snidr_player.y,global.camY,-2);
_cz = lerp(o_snidr_player.z,global.camZ,-2);
light_set(_cx,_cy,_cz,-.48,-.36,-.8,1000,1);
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