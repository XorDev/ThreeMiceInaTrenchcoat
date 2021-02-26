/// @description _array_get_array_index(array, subarray)
/// @param array
/// @param subarray
function _array_get_array_index(argument0, argument1) {
	/*
		Reurns an index if the array already contains an array that is equal to the given array.
		Otherwise it returns -1
	
		Script created by Sindre Hauge Larsen, 2019
		www.thesnidr.com
	*/
	var source = argument0;
	var subarray = argument1;

	for (var i = array_length(source) - 1; i >= 0; i --)
	{
		if array_equals(subarray, source[i])
		{
			return i;
		}
	}
	return -1;


}
