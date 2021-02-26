/// @description mbuff_create_flat_tangents(modelBuffer)
/// @param modelBuffer
function mbuff_create_flat_tangents(argument0) {
	/*
		Generates flat tangents, encoded as colour.
		modelBuffer must be a regular buffer, not a vertex buffer.
		This script will simply update the given vertex buffer, and will as such not return anything.
	
		Assumes the vertex format contains 3D position, then normals, then texcoords, then colour (whereby the latter will be used as tangents)
	
		Script made by TheSnidr
		www.TheSnidr.com
	*/
	var mBuff, bytesPerVert, bufferSize, bytesPerTri, modelNum, m, buff, epsilon, i, P0, P1, P2, P3, P4, P5, P6, P7, P8, N0, N1, N2, N3, N4, N5, N6, N7, N8, T0, T1, T2, T3, T4, T5, l, p1x, p1y, p1z, p2x, p2y, p2z, s1, s2, t1, t2, r, sdx, sdy, sdz, tdx, tdy, tdz, dp, Tx, Ty, Tz, Th;
	mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}
	bytesPerVert = mBuffBytesPerVert;
	bytesPerTri = bytesPerVert * 3;
	epsilon = math_get_epsilon();

	modelNum = array_length(mBuff);

	for (m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		bufferSize = buffer_get_size(buff);

		for (i = 0; i < bufferSize; i += bytesPerTri)
		{
			//Read triangle data from the vertex buffer
			buffer_seek(buff, buffer_seek_start, i)
			P0 = buffer_read(buff, buffer_f32);
			P1 = buffer_read(buff, buffer_f32);
			P2 = buffer_read(buff, buffer_f32);
			N0 = buffer_read(buff, buffer_f32);
			N1 = buffer_read(buff, buffer_f32);
			N2 = buffer_read(buff, buffer_f32);
			T0 = buffer_read(buff, buffer_f32);
			T1 = buffer_read(buff, buffer_f32);
	
			buffer_seek(buff, buffer_seek_start, i + bytesPerVert)
			P3 = buffer_read(buff, buffer_f32);
			P4 = buffer_read(buff, buffer_f32);
			P5 = buffer_read(buff, buffer_f32);
			N3 = buffer_read(buff, buffer_f32);
			N4 = buffer_read(buff, buffer_f32);
			N5 = buffer_read(buff, buffer_f32);
			T2 = buffer_read(buff, buffer_f32);
			T3 = buffer_read(buff, buffer_f32);
	
			buffer_seek(buff, buffer_seek_start, i + 2 * bytesPerVert)
			P6 = buffer_read(buff, buffer_f32);
			P7 = buffer_read(buff, buffer_f32);
			P8 = buffer_read(buff, buffer_f32);
			N6 = buffer_read(buff, buffer_f32);
			N7 = buffer_read(buff, buffer_f32);
			N8 = buffer_read(buff, buffer_f32);
			T4 = buffer_read(buff, buffer_f32);
			T5 = buffer_read(buff, buffer_f32);
	
			p1x = P3 - P0;
			p1y = P4 - P1;
			p1z = P5 - P2;
			p2x = P6 - P0;
			p2y = P7 - P1;
			p2z = P8 - P2;
		
			s1 = T2 - T0;
			s2 = T4 - T0;
			t1 = T3 - T1;
			t2 = T5 - T1;
		
			var r, sdx, sdy, sdz, tdx, tdy, tdz, dp, Tx, Ty, Tz, Th;
		    r = 1.0 / max(epsilon, s1 * t2 - s2 * t1);
			sdx = (t2 * p1x - t1 * p2x) * r;
			sdy = (t2 * p1y - t1 * p2y) * r;
			sdz = (t2 * p1z - t1 * p2z) * r;
			tdx = (s1 * p2x - s2 * p1x) * r;
			tdy = (s1 * p2y - s2 * p1y) * r;
			tdz = (s1 * p2z - s2 * p1z) * r;

			//Orthogonalize tangent to normal and normalize
			dp = N0 * sdx + N1 * sdy + N2 * sdz;
			Tx = sdx - N0 * dp;
			Ty = sdy - N1 * dp;
			Tz = sdz - N2 * dp;
			l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			if l != 0{
				Tx /= l;
				Ty /= l;
				Tz /= l;}
			//Calculate handedness
			Th = sign(tdx * (Ty * N2 - Tz * N1) + tdy * (Tz * N0 - Tx * N2) + tdz * (Tx * N1 - Ty * N0));
			buffer_seek(buff, buffer_seek_start, i + 8 * 4);
			buffer_write(buff, buffer_u8, (Tx + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Ty + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Tz + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Th + 1.0) * 127);
	
			//Orthogonalize tangent to normal and normalize
			dp = N3 * sdx + N4 * sdy + N5 * sdz;
			Tx = sdx - N3 * dp;
			Ty = sdy - N4 * dp;
			Tz = sdz - N5 * dp;
			l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			if l != 0{
				Tx /= l;
				Ty /= l;
				Tz /= l;}
			//Calculate handedness
			Th = sign(tdx * (Ty * N5 - Tz * N4) + tdy * (Tz * N3 - Tx * N5) + tdz * (Tx * N4 - Ty * N3));
			buffer_seek(buff, buffer_seek_start, i + bytesPerVert + 8 * 4);
			buffer_write(buff, buffer_u8, (Tx + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Ty + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Tz + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Th + 1.0) * 127);
	
			//Orthogonalize tangent to normal and normalize
			dp = N6 * sdx + N7 * sdy + N8 * sdz;
			Tx = sdx - N6 * dp;
			Ty = sdy - N7 * dp;
			Tz = sdz - N8 * dp;
			l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			if l != 0{
				Tx /= l;
				Ty /= l;
				Tz /= l;}
			//Calculate handedness
			Th = sign(tdx * (Ty * N8 - Tz * N7) + tdy * (Tz * N6 - Tx * N8) + tdz * (Tx * N7 - Ty * N6));
			buffer_seek(buff, buffer_seek_start, i + 2 * bytesPerVert + 8 * 4);
			buffer_write(buff, buffer_u8, (Tx + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Ty + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Tz + 1.0) * 127);
			buffer_write(buff, buffer_u8, (Th + 1.0) * 127);
		}
	}


}
