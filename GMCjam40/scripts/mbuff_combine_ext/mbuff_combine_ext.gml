/// @description mbuff_combine_ext(target, source, matrix)
/// @param target
/// @param source
/// @param matrix
function mbuff_combine_ext(argument0, argument1, argument2) {
	/*
		Lets you combine two model buffers into one. The source buffer will be transformed by the given matrix.
		Also transforms normals.
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var vx, vy, vz, nx, ny, nz, v, n;
	var trg = argument0;
	var src = argument1;
	var M = argument2;

	//Create normal matrix from world matrix
	var N = array_create(16, 0);
	array_copy(N, 0, M, 0, 16);
	N[12] = 0;
	N[13] = 0;
	N[14] = 0;

	//Find sizes of buffers and resize the target buffer to new size
	var bytesPerVert = mBuffBytesPerVert;
	var bytesPerTri = 3 * bytesPerVert;
	var srcSize = bytesPerTri * (buffer_get_size(src) div bytesPerTri);
	var trgSize = bytesPerTri * (buffer_get_size(trg) div bytesPerTri);
	buffer_resize(trg, srcSize + trgSize);
	buffer_seek(trg, buffer_seek_start, trgSize);

	//Loop through the vertices of the source buffer
	for (var i = 0; i < srcSize; i += bytesPerVert)
	{
		//Read vertex position and normal from source buffer
		buffer_seek(src, buffer_seek_start, i);
		vx = buffer_read(src, buffer_f32);
		vy = buffer_read(src, buffer_f32);
		vz = buffer_read(src, buffer_f32);
		nx = buffer_read(src, buffer_f32);
		ny = buffer_read(src, buffer_f32);
		nz = buffer_read(src, buffer_f32);
	
		//Transform vertex position and normal
		v = matrix_transform_vertex(M, vx, vy, vz);
		n = matrix_transform_vertex(N, nx, ny, nz);
	
		//Write vertex to target buffer
		buffer_copy(src, i, bytesPerVert, trg, buffer_tell(trg));
		buffer_write(trg, buffer_f32, v[0]);
		buffer_write(trg, buffer_f32, v[1]);
		buffer_write(trg, buffer_f32, v[2]);
		buffer_write(trg, buffer_f32, n[0]);
		buffer_write(trg, buffer_f32, n[1]);
		buffer_write(trg, buffer_f32, n[2]);
		buffer_seek(trg, buffer_seek_relative, bytesPerVert);
	}


}
