/// @description

global.hInput = keyboard_check(ord("D")) - keyboard_check(ord("A"));
global.vInput = keyboard_check(ord("W")) - keyboard_check(ord("S"));
global.jumpInput = keyboard_check_pressed(vk_space);
global.trenchCoatInput = keyboard_check_pressed(ord("E"));

//Update followers
if (global.trenchCoatInput)
{
	trenchcoat = !trenchcoat;
	if (!trenchcoat)
	{
		mouseArray[0].height = 0;
		for (var i = 1; i < mice; i ++)
		{
			with mouseArray[i]
			{
				x = parent.x + 10;
				y = parent.y;
				z = parent.z - parent.radius - radius;
				prevX = x;
				prevY = y;
				prevZ = z;
			}
		}
	}
	if (trenchcoat)
	{
		trenchcoatTimer = 1;
		
		//Make follower mice jump towards their new position
		with mouseArray[0]
		{
			height = radius * 2 + other.mouseArray[1].radius * 4;
			jumpStartX = x;
			jumpStartY = y;
			jumpStartZ = z;
			jumpEndX = x;
			jumpEndY = y;
			jumpEndZ = z + height;
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
		trenchcoatTimer -= .01;
	}
}
else
{
	for (var i = 0; i < mice; i ++)
	{
		//Make mice avoid each other
		for (var j = i - 1; j >= 0; j --)
		{
			mouseArray[i].avoid(mouseArray[j]);
		}
		mouseArray[i].step();
		
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