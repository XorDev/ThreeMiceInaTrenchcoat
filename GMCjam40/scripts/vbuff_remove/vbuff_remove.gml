/// @description vbuff_remove(vBuff, index)
/// @param vBuff
/// @param index
function vbuff_remove(argument0, argument1) {
	/*
		Removes a buffer from the given mBuff array.
		Returns a new array that does not contain the removed index.
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var vBuff = argument0;
	var modelInd = argument1;
	if !is_array(vBuff){return -1;}
	var num = array_length(vBuff);

	var newVbuff = array_create(num-1);
	array_copy(newVbuff, 0, vBuff, 0, modelInd);

	vertex_delete_buffer(vBuff[modelInd]);
	for (var i = modelInd+1; i < num; i ++)
	{
		newVbuff[i-1] = vBuff[i];
	}

	return newVbuff;


}
