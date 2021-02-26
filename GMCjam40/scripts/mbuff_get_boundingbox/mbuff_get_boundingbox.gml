/// @description mbuff_get_boundingbox(mBuff)
/// @param mBuff
function mbuff_get_boundingbox(argument0) {
	/*
		Returns the bounding box of the model as an array of the following format:
			[minX, minY, minZ, maxX, maxY, maxZ]
		
		The first time you try to get the bounding box on a new or edited model may take a bit of time.
	*/
	var mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}

	var bytesPerVert = mBuffBytesPerVert;

	var h = 999999;
	var minX = h;
	var minY = h;
	var minZ = h;
	var maxX = -h;
	var maxY = -h;
	var maxZ = -h;
	var modelNum = array_length(mBuff)
	for (var m = 0; m < modelNum; m ++)
	{
		var buff = mBuff[m];
		var buffSize = buffer_get_size(buff);
		for (var i = 3 * bytesPerVert; i < buffSize; i += bytesPerVert)
		{
			buffer_seek(buff, buffer_seek_start, i);
			var v = buffer_read(buff, buffer_f32);
			minX = min(minX, v);
			maxX = max(maxX, v);
			var v = buffer_read(buff, buffer_f32);
			minY = min(minY, v);
			maxY = max(maxY, v);
			var v = buffer_read(buff, buffer_f32);
			minZ = min(minZ, v);
			maxZ = max(maxZ, v);
		}
	}

	return [minX, minY, minZ, maxX, maxY, maxZ];


}
