/// @description vbuff_create_from_mbuff(mBuff)
/// @param mBuff
function vbuff_create_from_mbuff(argument0) {
	/*
		Creates a frozen vbuff from the given mbuff

		Script created by TheSnidr
		www.thesnidr.com
	*/
	var triNum = 0;
	var mBuff, vBuff, modelNum, i;
	mBuff = argument0;
	if (is_array(mBuff) && array_length(mBuff) < 1)
	{
		show_debug_message("Error in script vbuff_create_from_mbuff: Mbuff does not contain any buffers");
		return -1;
	}

	if !is_array(mBuff)
	{
		vBuff = vertex_create_buffer_from_buffer(mBuff, global.mBuffFormat);
		vertex_freeze(vBuff);
	}
	else
	{
		modelNum = array_length(mBuff);
		vBuff = array_create(modelNum);
		for (i = 0; i < modelNum; i ++)
		{
			vBuff[i] = vertex_create_buffer_from_buffer(mBuff[i], global.mBuffFormat);
			vertex_freeze(vBuff[i]);
			triNum += buffer_get_size(mBuff[i]) / mBuffBytesPerVert / 3;
		}
	}
	return vBuff;


}
