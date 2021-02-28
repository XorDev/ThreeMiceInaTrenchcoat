/// @description
z = 0;
event_inherited();

tile = checkNeighbours();
floorTex = sprite_get_texture(spr_floor_spikes, 0);
deleteAfterUse = false;

tex = sprite_get_texture(spr_white, 0);

timer = 60; //20 ingame frames until the button goes from active to inactive

h = 16;
active = 0;
position = 0;
countdown = 60;
colFunc = function()
{
	obj_player.damaged();
}

shape = levelColmesh.addTrigger(new colmesh_sphere(x + 16, y + 16, z + height - h, 6), colFunc);