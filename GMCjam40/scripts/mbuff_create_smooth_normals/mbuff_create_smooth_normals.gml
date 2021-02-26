/// @description mbuff_create_smooth_normals(mbuff)
/// @param mbuff
function mbuff_create_smooth_normals(argument0) {
	/*
		Generates smooth normals
		mbuff must be a regular buffer, not a vertex buffer.
		This script will simple update the given vertex buffer, and will as such not return anything.

		Assumes that the vertex format contains a 3D position, and then normals

		Script made by TheSnidr
		www.TheSnidr.com
	*/
	var mBuff, buff, modelNum, bytesPerVert, bytesPerTri, bufferSize, i, P0, P1, P2, P3, P4, P5, P6, P7, P8, x1, y1, z1, x2, y2, z2, Nx, Ny, Nz, l, normalMap, key, N;
	mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}
	bytesPerVert = mBuffBytesPerVert;
	bytesPerTri = bytesPerVert * 3;

	modelNum = array_length(mBuff);
	normalMap = ds_map_create();
	for (var m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		bufferSize = buffer_get_size(buff);
		for (i = 0; i < bufferSize; i += 3 * bytesPerVert)
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
			Nx = y1 * z2 - z1 * y2;
			Ny = z1 * x2 - x1 * z2;
			Nz = x1 * y2 - y1 * x2;
			l = sqrt(sqr(Nx) + sqr(Ny) + sqr(Nz));
			if l <= 0{continue;}
			l = 1 / l;
			Nx *= l;
			Ny *= l;
			Nz *= l;
		
			//Add the normal to the normal of the vertices of the triangle
			key = string(P0) + "," + string(P1) + "," + string(P2);
			N = normalMap[? key];
			if is_undefined(N){normalMap[? key] = [Nx, Ny, Nz];}
			else
			{
				N[@ 0] += Nx;
				N[@ 1] += Ny;
				N[@ 2] += Nz;
			}
	
			key = string(P3) + "," + string(P4) + "," + string(P5);
			N = normalMap[? key];
			if is_undefined(N){normalMap[? key] = [Nx, Ny, Nz];}
			else
			{
				N[@ 0] += Nx;
				N[@ 1] += Ny;
				N[@ 2] += Nz;
			}
	
			key = string(P6) + "," + string(P7) + "," + string(P8);
			N = normalMap[? key];
			if is_undefined(N){normalMap[? key] = [Nx, Ny, Nz];}
			else
			{
				N[@ 0] += Nx;
				N[@ 1] += Ny;
				N[@ 2] += Nz;
			}
		}
	}

	for (var m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		bufferSize = buffer_get_size(buff);
	
		//Loop through all vertices, normalize their new normals, and write them to the buffer
		for (i = 0; i < bufferSize; i += bytesPerVert)
		{
			buffer_seek(buff, buffer_seek_start, i)
			P0 = buffer_read(buff, buffer_f32);
			P1 = buffer_read(buff, buffer_f32);
			P2 = buffer_read(buff, buffer_f32);
			key = string(P0) + "," + string(P1) + "," + string(P2);
			N = normalMap[? key];
			if is_undefined(N){continue;}
			l = sqr(N[0]) + sqr(N[1]) + sqr(N[2]);
			if l <= 0{continue;}
			l = 1 / sqrt(l);
			buffer_write(buff, buffer_f32, N[0] * l);
			buffer_write(buff, buffer_f32, N[1] * l);
			buffer_write(buff, buffer_f32, N[2] * l);
		}
	}
	ds_map_destroy(normalMap);


}
