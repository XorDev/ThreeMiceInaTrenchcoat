/// @description mbuff_delete(mBuff)
/// @param mBuff
function mbuff_delete(argument0) {
	/*
		Deletes an mbuff
	
		Script created by TheSnidr, 2019
		www.thesnidr.com
	*/
	var mBuff = argument0;
	if is_array(mBuff)
	{
		var n = array_length(mBuff);
		for (var i = 0; i < n; i ++)
		{
			buffer_delete(mBuff[i]);
		}
	}
	else if mBuff >= 0
	{
		buffer_delete(mBuff);
	}
}
