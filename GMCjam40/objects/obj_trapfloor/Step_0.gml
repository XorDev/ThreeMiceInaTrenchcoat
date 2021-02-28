///@desc Detect player

velocity = lerp(velocity,active,.1);
angle = min(angle*.95,99)+8*velocity;

//Gradually deactivate
active *= .95;

if distance_to_object(obj_player)<4 || distance_to_object(obj_guard_parent)<8
{
	active = 1;	
}