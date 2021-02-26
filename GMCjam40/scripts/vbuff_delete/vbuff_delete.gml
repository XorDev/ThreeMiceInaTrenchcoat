/// @description vbuff_delete(vBuff)
/// @param vBuff
function vbuff_delete(argument0) {
	/*
		Deletes a vbuff
	
		Script created by TheSnidr, 2019
		www.thesnidr.com
	*/
	var vBuff = argument0;
	if (is_array(vBuff))
	{
		var n = array_length(vBuff);
		for (var i = 0; i < n; i ++)
		{
			vertex_delete_buffer(vBuff[i]);
		}
	}
	else if (vBuff >= 0)
	{
		vertex_delete_buffer(vBuff);
	}


}
