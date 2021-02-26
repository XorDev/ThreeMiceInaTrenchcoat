/// @description _array_delete(array, index)
/// @param array
/// @param index
function _array_delete(argument0, argument1) {
	/*
		Deletes an index from an array
	*/
	var array = argument0;
	var index = argument1;

	var num = array_length(array);
	var newArray = array_create(num - 1);
	array_copy(newArray, 0, array, 0, index);
	array_copy(newArray, index, array, index + 1, num - index);
	return newArray;


}
