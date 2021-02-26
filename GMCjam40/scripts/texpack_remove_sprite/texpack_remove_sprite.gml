/// @description texpack_remove_sprite(texPack, index)
/// @param texPack
/// @param index
function texpack_remove_sprite(argument0, argument1) {
	var texPack = argument0;
	var ind = argument1;

	var num = array_length(texPack);
	var newTexPack = array_create(num - 1);
	array_copy(newTexPack, 0, texPack, 0, ind);
	array_copy(newTexPack, ind, texPack, ind + 1, num - ind - 1);

	return newTexPack;


}
