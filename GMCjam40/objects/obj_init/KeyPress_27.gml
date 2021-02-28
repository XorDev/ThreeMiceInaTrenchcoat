/// @description
if (room != rm_menu)
{
	with obj_player
	{
		instance_destroy();
	}
	room_goto(rm_menu);
}
else
{
	game_end();
}