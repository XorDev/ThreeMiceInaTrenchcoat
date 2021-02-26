/// @description mbuff_get_vertices(mBuff)
/// @param mBuff
function mbuff_get_vertices(argument0) {
	/*
		Returns the bounding box of the model as an array of the following format:
			[minX, minY, minZ, maxX, maxY, maxZ]
		
		The first time you try to get the bounding box on a new or edited model may take a bit of time.
	*/
	var mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}

	var vertNum = 0;
	var bytesPerVert = mBuffBytesPerVert;
	var modelNum = array_length(mBuff)
	for (var m = 0; m < modelNum; m ++)
	{
		var buff = mBuff[m];
		var buffSize = buffer_get_size(buff);
		vertNum += buffSize div bytesPerVert;
	}

	return vertNum;


}
