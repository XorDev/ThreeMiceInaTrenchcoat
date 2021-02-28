/// @description
z = 0;
tex = sprite_get_texture(spr_brick, 0);
height = 192;

function addToLevel()
{
	//Add to level geometry
	obj_level_geometry.addModel(global.mbuffLadderEntrance, tex, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	
	//Add trigger object (that will take us to the next level, yayyyy)
	var colfunc = function()
	{
		if (vInput)
		{
			with obj_player
			{
				climb_ladder = other;
			}
		}
	}
	levelColmesh.addTrigger(new colmesh_cube(x + w / 2, y + h / 2, z + w / 2, w), colfunc);
}