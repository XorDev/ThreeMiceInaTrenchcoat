/// @description
//Player variables
z = 0;
radius = 10;

trenchcoat = false;

globalvar trenchcoatTimer;
trenchcoatTimer = 0;

/// @func mouse(x, y, z)
function mouse(_x, _y, _z, _parent) constructor
{
	x = _x;
	y = _y;
	z = _z;
	targetX = x div 32;
	targetY = y div 32;
	prevCellX = targetX;
	prevCellY = targetY;
	
	radius = 10;
	height = 0;
	jumpLag = 4;
	
	angle = 0;
	
	parent = _parent;
	jumpTimer = -1;
	mouseIndex = 0;
	trailPos = 0;
	
	instance = new smf_instance(global.modMouse);
	instance.play("Idle", .1, 1, true);
	instance.scale = .28;
	currInst = instance;
	
	if (is_struct(parent))
	{
		//This is a follower mouse
		mouseIndex = parent.mouseIndex + 1;
		radius = 9;
	}
	if (mouseIndex == 0)
	{
		trenchcoatInst = new smf_instance(global.modTrenchcoat);
		trenchcoatInst.play("Idle", .1, 1, true);
		trenchcoatInst.scale = .32;
		trenchcoatHeight = radius * 2;
	}
	
	static step = function(trenchcoat)
	{
		var dx = (targetX * 32 - x);
		var dy = (targetY * 32 - y);
		var dist = point_distance(0, 0, dx, dy);
		if (dist > 0)
		{
			var dir = point_direction(0, 0, dx, dy);
			angle += angle_difference(dir, angle) * .1;
			var d = min(dist, 2) / dist;
			x += dx * d;
			y += dy * d;
			var animSpd = currInst.getAnimSpeed("Walk");
			currInst.play("Walk", animSpd, .15, false);
		}
		else
		{
			var animSpd = currInst.getAnimSpeed("Idle");
			currInst.play("Idle", animSpd, .15, false);
		}
		currInst.step(1);
		
		if (mouseIndex > 0)
		{
			//This is a follower mouse
			if (targetX != parent.prevCellX || targetY != parent.prevCellY)
			{
				targetX = parent.prevCellX;
				targetY = parent.prevCellY;
			}
		}
		else
		{
			//This is the main mouse
			//Controls
			jump = global.jumpInput;
			var h = global.hInput;
			var v = global.vInput;
			
			targetX += h;
			targetY += v;
		}
	}
	
	static draw = function()
	{
		var t = trenchcoatTimer;
		
		var s = currInst.scale * radius;
		if (t > 0 && mouseIndex == 0)
		{
			s *= min(1, 1.5 * t);
		}
		matrix_set(matrix_world, matrix_build(x, y, z - radius - height, 0, 0, angle, s, s, s));
		currInst.draw();
		
		if mouseIndex == 0 && t > 0
		{
			var s = trenchcoatInst.scale * radius;
			matrix_set(matrix_world, matrix_build(x, y, z - (radius + trenchcoatHeight) * max(0, (1 - 2 * t)), 0, 0, angle, s * min(2 - 2 * t, 1), s * min(2 - 2 * t, 1), s * max(.2, min(1 - 2 * t, 1))));
			trenchcoatInst.draw();
		}
	}
}

mice = 0;
mouseArray[mice ++] = new mouse(x, y, z, self);
mouseArray[mice ++] = new mouse(x + mice * radius * 2, y, z, mouseArray[mice - 1]);
mouseArray[mice ++] = new mouse(x + mice * radius * 2, y, z, mouseArray[mice - 1]);
global.masterMouse = mouseArray[0];