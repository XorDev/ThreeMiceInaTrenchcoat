/// @description mbuff_create_flat_normals(mBuff)
/// @param mBuff
function mbuff_create_flat_normals(argument0) {
	/*
		Generates flat normals for the given mbuff

		Script made by TheSnidr
		www.TheSnidr.com
	*/
	var mBuff, bytesPerVert, bytesPerTri, bufferSize, buff, modelNum, m, i, P0, P1, P2, P3, P4, P5, P6, P7, P8, x1, y1, z1, x2, y2, z2, Nx, Ny, Nz, l, j;
	mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}
	bytesPerVert = mBuffBytesPerVert;
	bytesPerTri = bytesPerVert * 3;

	modelNum = array_length(mBuff);
	for (m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		bufferSize = buffer_get_size(buff);

		for (i = 0; i < bufferSize; i += bytesPerTri)
		{
			//Read the three vertices of the triangle
			buffer_seek(buff, buffer_seek_start, i);
			P0 = buffer_read(buff, buffer_f32);
			P1 = buffer_read(buff, buffer_f32);
			P2 = buffer_read(buff, buffer_f32);
			buffer_seek(buff, buffer_seek_start, i + bytesPerVert);
			P3 = buffer_read(buff, buffer_f32);
			P4 = buffer_read(buff, buffer_f32);
			P5 = buffer_read(buff, buffer_f32);
			buffer_seek(buff, buffer_seek_start, i + 2 * bytesPerVert);
			P6 = buffer_read(buff, buffer_f32);
			P7 = buffer_read(buff, buffer_f32);
			P8 = buffer_read(buff, buffer_f32);

			//Generate flat normal
			x1 = P0 - P3;
			y1 = P1 - P4;
			z1 = P2 - P5;
			x2 = P0 - P6;
			y2 = P1 - P7;
			z2 = P2 - P8;
			Nx = y1 * z2 - y2 * z1;
			Ny = z1 * x2 - z2 * x1;
			Nz = x1 * y2 - x2 * y1;
			l = sqrt(sqr(Nx) + sqr(Ny) + sqr(Nz));
			if l <= 0{continue;}
			l = 1 / l;
			Nx *= l;
			Ny *= l;
			Nz *= l;
	
			j = i + 12;
			buffer_seek(buff, buffer_seek_start, j); //Assume that the vertex format stores positions first, and then normals
			buffer_write(buff, buffer_f32, Nx);
			buffer_write(buff, buffer_f32, Ny);
			buffer_write(buff, buffer_f32, Nz);
			buffer_seek(buff, buffer_seek_start, j + bytesPerVert);
			buffer_write(buff, buffer_f32, Nx);
			buffer_write(buff, buffer_f32, Ny);
			buffer_write(buff, buffer_f32, Nz);
			buffer_seek(buff, buffer_seek_start, j + 2 * bytesPerVert);
			buffer_write(buff, buffer_f32, Nx);
			buffer_write(buff, buffer_f32, Ny);
			buffer_write(buff, buffer_f32, Nz);
		}
	}


}
