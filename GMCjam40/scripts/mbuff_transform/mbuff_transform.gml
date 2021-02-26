/// @description mbuff_transform(mbuff, matrix)
/// @param mbuff
/// @param matrix
function mbuff_transform(argument0, argument1) {
	/*
		Transforms a given model buffer by the given matrix.
		mbuff can also be an array of buffers, whereby each entry in the array will be transformed.
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var vx, vy, vz, nx, ny, nz, v, n, l;
	var mBuff = argument0;
	var M = argument1;

	//Create normal matrix from world matrix
	var epsilon = math_get_epsilon();
	var N = array_create(16, 0);
	array_copy(N, 0, M, 0, 11);

	if !is_array(mBuff){mBuff = [mBuff];}
	var modelNum = array_length(mBuff);
	var bytesPerVert = mBuffBytesPerVert;

	//Loop through the model buffers
	for (var m = 0; m < modelNum; m ++)
	{
		var buff = mBuff[m];
		var buffSize = buffer_get_size(buff);

		//Loop through the vertices of the buffer (skip metadata)
		for (var i = 0; i < buffSize; i += bytesPerVert)
		{
			//Read vertex position and normal from buffer
			buffer_seek(buff, buffer_seek_start, i);
			vx = buffer_read(buff, buffer_f32);
			vy = buffer_read(buff, buffer_f32);
			vz = buffer_read(buff, buffer_f32);
			nx = buffer_read(buff, buffer_f32);
			ny = buffer_read(buff, buffer_f32);
			nz = buffer_read(buff, buffer_f32);
	
			//Transform vertex position and normal
			v = matrix_transform_vertex(M, vx, vy, vz);
			n = matrix_transform_vertex(N, nx, ny, nz);
			l = 1 / max(epsilon, sqrt(sqr(n[0]) + sqr(n[1]) + sqr(n[2])));
	
			//Overwrite position and normal in the buffer
			buffer_seek(buff, buffer_seek_start, i);
			buffer_write(buff, buffer_f32, v[0]);
			buffer_write(buff, buffer_f32, v[1]);
			buffer_write(buff, buffer_f32, v[2]);
			buffer_write(buff, buffer_f32, n[0] * l);
			buffer_write(buff, buffer_f32, n[1] * l);
			buffer_write(buff, buffer_f32, n[2] * l);
		}
	}


}
