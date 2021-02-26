/// @description
//Player variables
x = 0;
y = 0;
z = 300;
radius = 15;
height = 0;
prevX = x;
prevY = y;
prevZ = z;
ground = false;

trenchcoat = false;
trenchcoatTimer = 0;

/// @func mouse(x, y, z)
function mouse(_x, _y, _z, _parent) constructor
{
	x = _x;
	y = _y;
	z = _z;
	prevX = x;
	prevY = y;
	prevZ = z;
	radius = 16;
	height = 0;
	ground = false;
	jumpLag = 4;
	jump = false;
	
	jumpx = x;
	jumpy = y; 
	jumpz = z;
	
	angle = 0;
	
	parent = _parent;
	jumpTimer = -1;
	mouseIndex = 0;
	
	instance = new smf_instance(global.modMouse);
	instance.play("Idle", .1, 1, true);
	instance.scale = .333;
	currInst = instance;
	
	if (is_struct(parent))
	{
		//This is a follower mouse
		mouseIndex = parent.mouseIndex + 1;
		radius = 10;
	}
	if (mouseIndex == 0)
	{
		trenchcoatInst = new smf_instance(global.modTrenchcoat);
		trenchcoatInst.play("Idle", .1, 1, true);
		trenchcoatInst.scale = .37;
	}
	
	
	static step = function(trenchcoat)
	{
		fric = 1 - .4;
		spdX = (x - prevX) * fric;
		spdY = (y - prevY) * fric;
		spdZ = (z - prevZ) * (1 - 0.01);
		prevX = x;
		prevY = y;
		prevZ = z;
		
		var dx = spdX;
		var dy = spdY;
		var d = sqrt(spdX * spdX + spdY * spdY);
		var dir = point_direction(0, 0, spdX, spdY);
		angle += angle_difference(dir, angle) * min(5, d) / 5.;

		jump = false;
		if (jumpTimer)
		{
			-- jumpTimer;
			if (!jumpTimer)
			{
				jump = true;
			}
		}
		
		if (is_struct(parent))
		{
			//This is a follower mouse
			var zDiff = abs(z - parent.z);
			if (jumpTimer <= 0 && ground && (zDiff > radius * 3 || parent.jump))
			{
				jumpTimer = jumpLag;
			}
			if (zDiff > radius * 8)
			{
				//Failsafe, teleport mouse to player
				z = parent.z;
				prevZ = z;
				spdZ = 0;
			}
			
			var dx = (parent.x - x);
			var dy = (parent.y - y);
			var d = dx * dx + dy * dy;
			var rr = radius + parent.radius;
			if (d == 0)
			{
				//The mouse shares coordinates with its parent. Push it out at any cost
				x = parent.x + radius
				y += 2 - random(4);
			}
			else
			{
				d = sqrt(d);
				d = (d - rr) / d;
				dx *= d;
				dy *= d;
				x += dx * .5;
				y += dy * .5;
			}
			z += spdZ - 1 + jump * ground * 10; //Apply gravity in z-direction
		}
		else
		{
			//This is the main mouse
			//Controls
			jump = global.jumpInput;
			var h = global.hInput;
			var v = global.vInput;
			if (h != 0 && v != 0)
			{	//If walking diagonally, divide the input vector by its own length
				var s = 1 / sqrt(2);
				h *= s;
				v *= s;
			}
			
			//Move
			acc = 2;
			x += spdX - acc * v;
			y += spdY - acc * h;
			z += spdZ - 1 + jump * ground * 12; //Apply gravity in z-direction
			
			//Put player in the middle of the map if he falls off
			if (z < -400)
			{
				x = 0;
				y = 0;
				z = 300;
				prevX = x;
				prevY = y;
				prevZ = z;
			}
		}
		//Cast a short-range ray from the previous position to the current position to avoid going through geometry
		if true//(sqr(x - prevX) + sqr(y - prevY) + sqr(z - height - prevZ) > radius * radius) //Only cast ray if there's a risk that we've gone through geometry
		{
			var d = 0;//height * (.5 + .5 * sign(z - prevZ));
			var dz = d;
			ray = levelColmesh.castRay(prevX, prevY, prevZ - height, x, y, z - height);
			if (is_array(ray))
			{
				x = ray[0] - (x - prevX) * .1;
				y = ray[1] - (y - prevY) * .1;
				z = ray[2] - (z - prevZ) * .1 + height;
			}
		}

		//Avoid ground
		ground = false;
		fast = false;			//Fast collisions should usually not be used for important objects like the player
		executeColfunc = true;	//We want to execute the collision function of the coins
		col = levelColmesh.displaceCapsule(x, y, z - height, 0, 0, 1, radius, height, 40, fast, executeColfunc);
		if (col[6]) //If we're touching ground
		{
			x = col[0];
			y = col[1];
			z = col[2] + height;
	
			//We're touching ground if the dot product between the returned vector 
			if (col[5] > 0.7)
			{
				ground = true;
			}
		}
		
		//Animate the player
		if (!ground)
		{
			var animSpd = currInst.getAnimSpeed("Jump");
			currInst.play("Jump", animSpd, .25, false);
		}
		else
		{
			if !(global.hInput == 0 && global.vInput == 0)
			{
				var animSpd = currInst.getAnimSpeed("Walk");
				currInst.play("Walk", animSpd * 1.2, .15, false);
			}
			else
			{
				var animSpd = currInst.getAnimSpeed("Idle");
				currInst.play("Idle", animSpd, .15, false);
			}
		}
		currInst.step(1);
	}
	
	static avoid = function(ind)
	{
		var dx = x - ind.x;
		var dy = y - ind.y;
		var dz = z - ind.z;
		var d = dx * dx + dy * dy + dz * dz;
		var rr = ind.radius + radius;
		if (d == 0)
		{
			x += rr;
			y += 2 - random(4);
		}
		else if (d < rr * rr)
		{
			d = rr / sqrt(d);
			dx *= d;
			dy *= d;
			dz *= d;
			x = ind.x + dx;
			y = ind.y + dy;
			z = ind.z + dz;
		}
	}
	
	static draw = function()
	{
		var s = currInst.scale * radius;
		matrix_set(matrix_world, matrix_build(x, y, z - radius - height, 0, 0, angle, s, s, s));
		shader_set(sh_smf_animate);
		currInst.draw();
		shader_reset();
		matrix_set(matrix_world, matrix_build_identity());
		//colmesh_debug_draw_capsule(x, y, z, dcos(angle), -dsin(angle), 0, radius * .5, radius * .5, make_colour_rgb(110, 127, 200));
	}
}

mice = 0;
mouseArray[mice ++] = new mouse(x, y, z, self);
mouseArray[mice ++] = new mouse(x + mice * radius * 2, y, z, mouseArray[mice - 1]);
mouseArray[mice ++] = new mouse(x + mice * radius * 2, y, z, mouseArray[mice - 1]);