/// @description _ds_list_get_array_index(list, array)
/// @param list
/// @param array
function _ds_list_get_array_index(argument0, argument1) {
	/*
		Reurns an index if the list already contains an array that is equal to the given array.
		Otherwise it returns -1
	
		Script created by Sindre Hauge Larsen, 2019
		www.thesnidr.com
	*/
	var list = argument0;
	var array = argument1;

	var num = ds_list_size(list);

	for (var i = 0; i < num; i ++)
	{
		if array_equals(array, list[| i])
		{
			return i;
		}
	}
	return -1;


}
