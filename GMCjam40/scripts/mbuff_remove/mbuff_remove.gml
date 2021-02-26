/// @description mbuff_remove(mBuff, index)
/// @param mBuff
/// @param index
function mbuff_remove(argument0, argument1) {
	/*
		Removes a buffer from the given mBuff array.
		Returns a new array that does not contain the removed index.
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var mBuff = argument0;
	var modelInd = argument1;
	if !is_array(mBuff){return -1;}
	var num = array_length(mBuff);

	var newMbuff = array_create(num-1);
	array_copy(newMbuff, 0, mBuff, 0, modelInd);

	buffer_delete(mBuff[modelInd]);
	for (var i = modelInd+1; i < num; i ++)
	{
		newMbuff[i-1] = mBuff[i];
	}

	return newMbuff;


}
