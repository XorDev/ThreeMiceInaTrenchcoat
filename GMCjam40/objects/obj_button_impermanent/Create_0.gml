/// @description
event_inherited();


//Variables that can be overwritten in the Instance Creation script must be initialized here
trap = 0;

tex = sprite_get_texture(tex_button, 0);
timer = 20; //20 ingame frames until the button goes from active to inactive

position = 0;
activated = false;
release = 1;