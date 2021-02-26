/// @description mbuff_rotate_uvs(mbuff)
/// @param mbuff
function mbuff_rotate_uvs(argument0) {
	/*
		Rotates UVs 90 degrees
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var m, buff, buffSize, i, u, v;
	var mBuff = argument0;

	if !is_array(mBuff){mBuff = [mBuff];}
	var modelNum = array_length(mBuff);
	var bytesPerVert = mBuffBytesPerVert;

	//Loop through the model buffers
	for (m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		buffSize = buffer_get_size(buff);

		//Loop through the vertices of the buffer
		for (i = 0; i < buffSize; i += bytesPerVert)
		{
			//Read UVs from buffer
			u = buffer_peek(buff, i + 6 * 4, buffer_f32);
			v = buffer_peek(buff, i + 7 * 4, buffer_f32);
		
			//Rotate 90 degrees and overwrite UVs
			buffer_poke(buff, i + 6 * 4, buffer_f32, v);
			buffer_poke(buff, i + 7 * 4, buffer_f32, u);
		}
	}


}
