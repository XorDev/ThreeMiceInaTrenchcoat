/// @description texpack_add_sprite(texPack, sprite_index)
/// @param texPack
/// @param sprite_index
function texpack_add_sprite(argument0, argument1) {
	var texPack = argument0;
	var spr = argument1;

	var num = array_length(texPack);
	texPack[@ num] = spr;

	return num;


}
