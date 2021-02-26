///@desc Debug surfaces

deferred_surface();

var _cx,_cy,_cz;
_cx = lerp(o_snidr_player.x,global.camX,-2);
_cy = lerp(o_snidr_player.y,global.camY,-2);
_cz = lerp(o_snidr_player.z,global.camZ,-2);
light_follow(_cx,_cy,_cz);