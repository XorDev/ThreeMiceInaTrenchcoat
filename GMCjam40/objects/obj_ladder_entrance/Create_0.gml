/// @description
event_inherited();

tex = sprite_get_texture(tex_ladder, 0);
height = 192;
z -= height;
dir = -1;

if (global.climbdir == 1)
{
	if (!instance_exists(obj_player))
	{
		instance_create_depth(x, y, 0, obj_player);
	}
	obj_player.climb_ladder = self;
	obj_player.climb_dir = - dir;
	
	var ID = global.mouseArray[0];
	ID.x = x + 16;
	ID.y = y + ID.radius;
	ID.z = z + 64;
	
	ID.prevX = ID.x;
	ID.prevY = ID.y;
	ID.prevZ = ID.z;
	
	//Reset the trail
	ID.trail = array_create(ID.trailSize);
}

function addToLevel()
{
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffLadder, tex, matrix_build(x + 16, y, z + 16, 0, 0, 0, 1, 1, 1));
	
	//Add trigger object (that will take us to the next level, yayyyy)
	var colfunc = function()
	{
		if (-global.vInput)
		{
			with obj_player
			{
				if (climb_ladder < 0)
				{
					climb_ladder = other;
					climb_dir = other.dir; //This ladder goes downwards
					global.climbdir = other.dir;
				}
			}
		}
	}
	levelColmesh.addTrigger(new colmesh_block(colmesh_matrix_build(x + 16, y, z + height / 2 + 16, 0, 0, 0, 8, 8, height + 16)), colfunc);
}