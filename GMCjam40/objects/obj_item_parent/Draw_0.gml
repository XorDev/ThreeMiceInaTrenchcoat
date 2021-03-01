///@desc

deferred_set(false);
draw();
deferred_reset();

if point_distance_3d(x,y,z,obj_player.x,obj_player.y,obj_player.z)<8
{
	colFunc();	
}