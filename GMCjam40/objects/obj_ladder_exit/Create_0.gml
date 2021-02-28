/// @description
event_inherited();

tex = sprite_get_texture(spr_brick, 0);
height = 192;
dir = 1;

if (global.climbdir = -1)
{
	if (!instance_exists(obj_player))
	{
		instance_create_depth(x, y, 0, obj_player);
	}
	obj_player.climb_ladder = self;
	obj_player.climb_dir = - dir;
	
	var ID = obj_player.mouseArray[0];
	ID.x = x + 16;
	ID.y = y + ID.radius;
	ID.z = z + 128;
	
	ID.prevX = ID.x;
	ID.prevY = ID.y;
	ID.prevZ = ID.z;
	
	with obj_player
	{
		for (var i = 1; i < mice; i ++)
		{
			with mouseArray[i]
			{
				x = ID.x;
				y = ID.y;
				z = ID.z;
			}
		}
	}
	
	global.climbdir = 0;
}

function addToLevel()
{
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffLadder, tex, matrix_build(x + 16, y + 2, z, 0, 0, 0, 1, 1, 1));
	
	//Add trigger object (that will take us to the next level, yayyyy)
	var colfunc = function()
	{
		if (global.vInput)
		{
			with obj_player
			{
				if (climb_ladder < 0)
				{
					climb_ladder = other;
					climb_dir = other.dir; //This ladder goes updwards
					global.climbdir = other.dir;
				}
			}
		}
	}
	levelColmesh.addTrigger(new colmesh_block(colmesh_matrix_build(x + 16, y + 8, z + height / 2 + 16, 0, 0, 0, 8, 8, height + 16)), colfunc);
}