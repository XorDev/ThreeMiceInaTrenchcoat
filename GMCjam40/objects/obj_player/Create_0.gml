/// @description
//Player variables
if instance_number(obj_player) > 1
{
	instance_destroy();
	exit;
}

if !audio_is_playing(snd_song1)
{
	audio_play_sound(snd_song1,0,1);
	audio_sound_gain(snd_song1,0,0);
}
audio_sound_gain(snd_song1,1,5000);

z = (200 - depth) / 100 * 64 + 10;
radius = 10;
climb_ladder = -1;
climb_dir = 1;

trenchcoat = false;
globalvar trenchcoatTimer;
trenchcoatTimer = 0;

iframes = 0;
function damaged()
{
	iframes = 20;
	//Damage calculations
}

/// @func mouse(x, y, z)
function mouse(_x, _y, _z, _parent) constructor
{
	x = _x;
	y = _y;
	z = _z;
	prevX = x;
	prevY = y;
	prevZ = z;
	radius = 10;
	height = 0;
	ground = false;
	jumpLag = 4;
	jump = false;
	ladder = false;
	
	jumpx = x;
	jumpy = y; 
	jumpz = z;
	
	angle = 0;
	
	parent = _parent;
	jumpTimer = -1;
	mouseIndex = 0;
	trailPos = 0;
	
	
	if (is_struct(parent))
	{
		//This is a follower mouse
		instance = new smf_instance(global.modMouseFollower);
		mouseIndex = parent.mouseIndex + 1;
		radius = 9;
	}
	if (mouseIndex == 0)
	{
		instance = new smf_instance(global.modMouse);
		trenchcoatInst = new smf_instance(global.modTrenchcoat);
		trenchcoatInst.play("Idle", .1, 1, true);
		trenchcoatInst.scale = .32;
		
		trailSize = 100;
		trail = array_create(trailSize);
		trenchcoatHeight = radius * 2;
	}
	instance.play("Idle", .1, 1, true);
	instance.scale = .28;
	currInst = instance;
	
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
		var spd = sqrt(spdX * spdX + spdY * spdY);
		var dir = point_direction(0, 0, spdX, spdY);
		angle += angle_difference(dir, angle) * min(5, spd) / 5.;

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
			var dist = point_distance_3d(parent.x, parent.y, parent.z, x, y, z);
			var t1 = global.masterMouse.trail[floor(trailPos) mod global.masterMouse.trailSize];
			var t2 = global.masterMouse.trail[(floor(trailPos + 1)) mod global.masterMouse.trailSize];
			if (is_array(t1) && is_array(t2))
			{
				jump = t1[3];
				ground = !jump;
				x = x*.8+.2*lerp(t1[0], t2[0], frac(trailPos));
				y = y*.8+.2*lerp(t1[1], t2[1], frac(trailPos));
				z = lerp(t1[2], t2[2], frac(trailPos));
				z += jump * (1 - sqr(frac(trailPos) * 2 - 1)) * radius * 3; //Jump in an arc
				if (jump)
				{
					trailPos = (trailPos + .1 + global.masterMouse.trailSize) mod global.masterMouse.trailSize;
				}
				else
				{
					if (parent.trailPos < trailPos){trailPos -= global.masterMouse.trailSize;}
					trailPos = (max(trailPos, trailPos + (parent.trailPos - 1.5 - trailPos) * .4) + global.masterMouse.trailSize) mod global.masterMouse.trailSize;
				}
			}
			else
			{
				trailPos = parent.trailPos;
				x = parent.x;
				y = parent.y;
				z = parent.z;
			}
			if (parent.ladder && !ladder)
			{
				if (!ladder)
				{
					var animSpd = currInst.getAnimSpeed("Climb");
					currInst.play("Climb", animSpd + random(0.02), .25, false);
				}
			}
			ladder = parent.ladder;
			if (ladder)
			{
				angle = 90;
			}
		}
		else
		{
			//This is the main mouse
			//Controls
			if (parent.climb_ladder < 0)
			{
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
				acc = (2 - trenchcoat) * .6;
				x += spdX + acc * h;
				y += spdY - acc * v;
				z += spdZ - .5 + jump * ground * 7; //Apply gravity in z-direction
			
				//Put player in the middle of the map if he falls off
				if (z < -400)
				{
					instance_destroy(obj_player);
					room_goto(rm_menu_lose);
					/*
					x = obj_player.xstart;
					y = obj_player.ystart;
					z = 300;
					prevX = x;
					prevY = y;
					prevZ = z;
					*/
				}
				//Cast a short-range ray from the previous position to the current position to avoid going through geometry
				if (sqr(x - prevX) + sqr(y - prevY) + sqr(z - height - prevZ) > radius * radius) //Only cast ray if there's a risk that we've gone through geometry
				{
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
			}
			else
			{
				if (!ladder)
				{
					var animSpd = currInst.getAnimSpeed("Climb");
					currInst.play("Climb", animSpd + random(0.02), .25, false);
				}
				ladder = true;
				var l = parent.climb_ladder;
				
				var endX = l.x + 16;
				var endY = l.y + radius - 2 * radius * (parent.climb_dir && -l.dir);
				var endZ = l.z + radius + l.height * .5 + l.height * .5 * (parent.climb_dir - l.dir) *.5;
				
				var targetX = endX;
				var targetZ = endZ;
				var dz = abs(targetZ - z);
				var targetY = l.y + radius - 2 * radius * (parent.climb_dir && -l.dir) * max(0, radius - dz);
				
				var dx = abs(targetX - x);
				var dy = abs(targetY - y);
				
				var spd = 1.5;
				if (point_distance_3d(x, y, z, endX, endY, endZ) <= spd)
				{
					if (parent.climb_ladder.dir == -1 && parent.climb_dir == -1)
					{
						//If this ladder goes down, and we just climbed down it, go to previous room
						room_goto_previous();
						global.climbed_down = true;
					}
					if (parent.climb_ladder.dir == 1 && parent.climb_dir == 1)
					{
						//If this ladder goes up, and we just climbed up it, go to next room
						room_goto_next();
						global.climbed_down = false;
					}
					parent.climb_ladder = -1;
					x = endX;
					y = endY;
					z = endZ;
					prevX = x;
					prevY = y;
					prevZ = z;
					ladder = false;
				}
				else
				{
					if (dx > 0){x += (targetX - x) * min(spd, dx) / dx;}
					if (dy > 0){y += (targetY - y) * min(spd, dy) / dy;}
					if (dz > 0){z += (targetZ - z) * min(spd, dz) / dz;}
					angle = 90;
				}
			}
			
			//Save trail
			if (ground || jump || ladder)
			{
				var p = floor(trailPos);
				trail[(p + 1) mod trailSize] = [x, y, z, jump];
				var t = trail[p];
				if (!is_array(t))
				{
					trail[p] = [x, y, z, false];
					trailPos = (trailPos + 1) mod trailSize;
				}
				else
				{
					var dist = point_distance_3d(t[0], t[1], t[2], x, y, z);
					if (t[3])
					{
						if (point_distance(t[0], t[1], x, y) >= radius)
						{
							trailPos = (p + 1) mod trailSize;
						}
					}
					else
					{
						repeat ceil(dist / radius)
						{
							d = radius / dist;
							t[0] += (x - t[0]) * d;
							t[1] += (y - t[1]) * d;
							t[2] += (z - t[2]) * d;
							trail[(++ p) mod trailSize] = [t[0], t[1], t[2], jump];
						}
						trailPos = max(trailPos, floor(trailPos) + dist / radius) mod trailSize;
						/*if (jump)
						{
							trailPos = (floor(trailPos) + 1) mod trailSize;
						}
						if (ground)
						{
							trailPos = max(trailPos, floor(trailPos) + min(dist / radius, 1)) mod trailSize;
						}*/
					}
				}
			}
			
		}
		
		//Animate the player
		if (!ladder)
		{
			if (!ground)
			{
				var animSpd = currInst.getAnimSpeed("Jump");
				currInst.play("Jump", animSpd, .25, false);
			}
			else
			{
				if (spd > .5)
				{
					var animSpd = currInst.getAnimSpeed("Walk");
					currInst.play("Walk", animSpd, .15, false);
				}
				else
				{
					var animSpd = currInst.getAnimSpeed("Idle");
					currInst.play("Idle", animSpd, .15, false);
				}
			}
		}
		currInst.step(1);
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

//4-bit item list;
items = 0;