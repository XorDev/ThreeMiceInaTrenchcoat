/// @description mbuff_read_from_buffer(loadBuff)
/// @param loadBuff
function mbuff_read_from_buffer(argument0) {
	/*
		Reads an mbuff from buffer

		Script created by TheSnidr, 2019
		www.thesnidr.com
	*/
	var loadBuff = argument0;

	var header = buffer_read(loadBuff, buffer_string)
	if header != "mBuff"
	{
		show_debug_message("ERROR in script mbuff_read_from_buffer: Trying to load model that is not an mBuff");
		exit;
	}

	var modelNum = buffer_read(loadBuff, buffer_u16);
	var isArray = buffer_read(loadBuff, buffer_bool);
	var mBuff = array_create(modelNum);
	for (var i = 0; i < modelNum; i ++)
	{
		var buffSize = buffer_read(loadBuff, buffer_u32);
		mBuff[i] = buffer_create(buffSize, buffer_grow, 1);
		buffer_copy(loadBuff, buffer_tell(loadBuff), buffSize, mBuff[i], 0);
		buffer_seek(loadBuff, buffer_seek_relative, buffSize);
	}

	if (!isArray)
	{
		return mBuff[0];
	}

	return mBuff;


}
