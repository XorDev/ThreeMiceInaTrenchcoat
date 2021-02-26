/// @description mbuff_write_to_buffer(saveBuff, mbuff)
/// @param saveBuff
/// @param mbuff
function mbuff_write_to_buffer(argument0, argument1) {
	/*
		Saves the given model buffer to the given filename
	
		Script created by TheSnidr
		www.thesnidr.com
	*/
	var mBuff, modelNum, saveBuff, i, buffSize;
	var saveBuff = argument0;
	var mBuff = argument1;
	if !is_array(mBuff){mBuff = [mBuff];}

	modelNum = array_length(mBuff);

	buffer_write(saveBuff, buffer_string, "mBuff");
	buffer_write(saveBuff, buffer_u16, modelNum);
	buffer_write(saveBuff, buffer_bool, is_array(argument1));

	for (i = 0; i < modelNum; i ++)
	{
		buffSize = buffer_get_size(mBuff[i]);
		buffer_write(saveBuff, buffer_u32, buffSize);
		buffer_copy(mBuff[i], 0, buffSize, saveBuff, buffer_tell(saveBuff));
		buffer_seek(saveBuff, buffer_seek_relative, buffSize);
	}


}
