/// @description
if (iframes > 0)
{
	iframes --;
}

global.hInput = keyboard_check(ord("D")) - keyboard_check(ord("A"));
global.vInput = keyboard_check(ord("W")) - keyboard_check(ord("S"));
global.jumpInput = keyboard_check_pressed(vk_space);
global.trenchCoatInput = keyboard_check_pressed(ord("E"));

//Update followers
if (global.trenchCoatInput && trenchcoatTimer <= 0) && (mice>2)
{
	trenchcoat = !trenchcoat;
	if (!trenchcoat)
	{
		mouseArray[0].height = 0;
		mouseArray[0].currInst = mouseArray[0].instance;
		for (var i = 1; i < mice; i ++)
		{
			with mouseArray[i]
			{
				trailPos = parent.trailPos;
			}
		}
	}
	if (trenchcoat)
	{
		trenchcoatTimer = 1;
		
		//Make follower mice jump towards their new position
		with mouseArray[0]
		{
			jumpStartX = x;
			jumpStartY = y;
			jumpStartZ = z;
			jumpEndX = x;
			jumpEndY = y;
			jumpEndZ = z + trenchcoatHeight;
			prevX = jumpEndX;
			prevY = jumpEndY;
			prevZ = jumpEndZ;
		}
		for (var i = 1; i < mice; i ++)
		{
			with mouseArray[i]
			{
				jumpStartX = x;
				jumpStartY = y;
				jumpStartZ = z;
				jumpEndX = parent.jumpEndX;
				jumpEndY = parent.jumpEndY;
				jumpEndZ = parent.jumpEndZ - parent.radius - radius;
			}
		}
	}
}
if (trenchcoatTimer > 0)
{
	for (var i = 0; i < mice; i ++)
	{
		var _mouse = mouseArray[i];
		_mouse.x = lerp(_mouse.jumpEndX, _mouse.jumpStartX, trenchcoatTimer);
		_mouse.y = lerp(_mouse.jumpEndY, _mouse.jumpStartY, trenchcoatTimer);
		_mouse.z = lerp(_mouse.jumpEndZ, _mouse.jumpStartZ, trenchcoatTimer);
		_mouse.z += (1 - sqr(trenchcoatTimer * 2 - 1)) * radius * 3; //Jump in an arc
	}
	trenchcoatTimer -= .03;
	if (trenchcoatTimer <= 0)
	{
		mouseArray[0].currInst = mouseArray[0].trenchcoatInst;
		mouseArray[0].height = mouseArray[0].trenchcoatHeight;
	}
}
else
{
	for (var i = 0; i < mice; i ++)
	{
		mouseArray[i].step(trenchcoat);
		
		if (trenchcoat)
		{
			break;
		}
	}
}

var mainMouse = mouseArray[0];
x = mainMouse.x;
y = mainMouse.y;
z = mainMouse.z;

if (items&1) && (distance_to_object(obj_cage)<16)
{
	for(var i = mice;i<array_length(mouseArray);i++)
	{
		var _m = mouseArray[i];
		if (point_distance_3d(x,y,z,_m.x,_m.y,_m.z)<80)
		{
			mice++;
		}
	}
}


var _o = obj_tunnel_entrance;
if instance_exists(_o) && (point_distance_3d(x,y,z,_o.x,_o.y,_o.z)<64)
{
	room_goto_previous();
}