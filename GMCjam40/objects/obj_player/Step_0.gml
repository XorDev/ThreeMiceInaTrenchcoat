/// @description
if (global.iframes > 0)
{
	global.iframes --;
}

global.hInput = (keyboard_check(ord("D")) || keyboard_check(vk_right)) - (keyboard_check(ord("A")) || keyboard_check(vk_left));
global.vInput = (keyboard_check(ord("W")) || keyboard_check(vk_up)) - (keyboard_check(ord("S")) || keyboard_check(vk_down));
global.jumpInput = keyboard_check_pressed(vk_space);
global.trenchCoatInput = keyboard_check_pressed(ord("E"));

//Update followers
if (global.trenchCoatInput && trenchcoatTimer <= 0) && (global.mice>2) && (global.items & 4)
{
	sound_randomize(snd_equip,.2,.2,1);
	global.trenchcoat = !global.trenchcoat;
	if (!global.trenchcoat)
	{
		global.mouseArray[0].height = 0;
		global.mouseArray[0].currInst = global.mouseArray[0].instance;
		for (var i = 1; i < global.mice; i ++)
		{
			with global.mouseArray[i]
			{
				trailPos = parent.trailPos;
			}
		}
	}
	if (global.trenchcoat)
	{
		trenchcoatTimer = 1;
		
		//Make follower mice jump towards their new position
		with global.mouseArray[0]
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
		for (var i = 1; i < global.mice; i ++)
		{
			with global.mouseArray[i]
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
	for (var i = 0; i < global.mice; i ++)
	{
		var _mouse = global.mouseArray[i];
		_mouse.x = lerp(_mouse.jumpEndX, _mouse.jumpStartX, trenchcoatTimer);
		_mouse.y = lerp(_mouse.jumpEndY, _mouse.jumpStartY, trenchcoatTimer);
		_mouse.z = lerp(_mouse.jumpEndZ, _mouse.jumpStartZ, trenchcoatTimer);
		_mouse.z += (1 - sqr(trenchcoatTimer * 2 - 1)) * radius * 3; //Jump in an arc
	}
	trenchcoatTimer -= .03;
	if (trenchcoatTimer <= 0)
	{
		global.mouseArray[0].currInst = global.mouseArray[0].trenchcoatInst;
		global.mouseArray[0].height = global.mouseArray[0].trenchcoatHeight;
	}
}
else
{
	for (var i = 0; i < global.mice; i ++)
	{
		global.mouseArray[i].step(global.trenchcoat);
		
		if (global.trenchcoat)
		{
			break;
		}
	}
}

var mainMouse = global.mouseArray[0];
x = mainMouse.x;
y = mainMouse.y;
z = mainMouse.z;

if (global.items&1) && (distance_to_object(obj_cage)<16)
{
	for(var i = global.mice; i < array_length(global.mouseArray); i++)
	{
		var _m = global.mouseArray[i];
		if (point_distance_3d(x,y,z,_m.x,_m.y,_m.z)<80)
		{
			global.message = "Mouse rescued!";
			global.messageFade = 1;
			
			global.mice++;
			sound_randomize(snd_mouse_yipee,.2,.2,1);
		}
	}
}
if keyboard_check_pressed(ord("B")) && (global.items&2)
{
	var _m = global.mouseArray[0];
	var _d = _m.angle;
	var _i = instance_create_depth(x+lengthdir_x(16,_d),y+lengthdir_y(16,_d),0,obj_item_bone);
	global.items &= ~2;
	
	_i.direction = _m.angle;
	_i.speed = 6;
	_i.friction = 1;
	_i.z = floor(z/64)*64;
}

if keyboard_check_pressed(ord("X"))
{
	lvlMessage ^= 1;
}
