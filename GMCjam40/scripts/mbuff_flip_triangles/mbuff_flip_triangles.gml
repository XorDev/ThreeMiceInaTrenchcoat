/// @description mbuff_flip_triangles(mBuff)
/// @param mBuff
function mbuff_flip_triangles(argument0) {
	/*
		Flips the triangles in the given mBuff

		Script made by TheSnidr
		www.TheSnidr.com
	*/
	var mBuff, bytesPerVert, bytesPerTri, bufferSize, buff, modelNum, tempBuff, m, i;
	mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}
	bytesPerVert = mBuffBytesPerVert;
	bytesPerTri = 3 * bytesPerVert;

	tempBuff = buffer_create(bytesPerTri, buffer_fixed, 1);
	modelNum = array_length(mBuff);
	for (m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		bufferSize = buffer_get_size(buff);
	
		for (i = 0; i < bufferSize; i += bytesPerTri)
		{
			//Read the three vertices of the triangle
			buffer_copy(buff, i, bytesPerVert, tempBuff, 0);
			buffer_copy(buff, i + bytesPerVert, bytesPerVert, tempBuff, bytesPerVert);
			buffer_copy(buff, i + 2 * bytesPerVert, bytesPerVert, tempBuff, 2 * bytesPerVert);

			//Write the three vertices back, but switch the order of the two last verts
			buffer_copy(tempBuff, 0, bytesPerVert, buff, i);
			buffer_copy(tempBuff, bytesPerVert, bytesPerVert, buff, i + 2 * bytesPerVert);
			buffer_copy(tempBuff, 2 * bytesPerVert, bytesPerVert, buff, i + bytesPerVert);
		}
	}
	buffer_delete(tempBuff);


}
