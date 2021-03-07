/// @description
z = 0;
event_inherited();
height = 64;

//Create a floor object
floorInd = instance_create_layer(x, y, layer, obj_floor);
floorInd.floorSprite = spr_floor_spikes;