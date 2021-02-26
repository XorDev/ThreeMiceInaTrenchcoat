/// @description mbuff_create_smooth_tangents(mBuff)
/// @param mBuff
function mbuff_create_smooth_tangents(argument0) {
	/*
		Generates smooth vertex tangents, encoded as colour.
		modelBuffer must be a regular buffer, not a vertex buffer.
		This script will simple update the given vertex buffer, and will as such not return anything.

		Assumes the vertex format contains 3D position, then normals, then texcoords, then colour (whereby the latter will be used as tangents)

		Script made by TheSnidr
		www.TheSnidr.com
	*/
	var mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}
	var bytesPerVert = mBuffBytesPerVert;
	var bytesPerTri = bytesPerVert * 3;
	var epsilon = math_get_epsilon();

	var modelNum = array_length(mBuff);
	var tangentMap = ds_map_create();
	var bitangentArray = array_create(modelNum);

	for (var m = 0; m < modelNum; m ++)
	{
		var buff = mBuff[m];
		var bufferSize = buffer_get_size(buff);
		var bitangent = array_create(bufferSize div bytesPerTri);
		bitangentArray[m] = bitangent;

		for (var i = 0; i < bufferSize; i += bytesPerTri)
		{
			//Read triangle data from the vertex buffer
			buffer_seek(buff, buffer_seek_start, i)
			var P0 = buffer_read(buff, buffer_f32);
			var P1 = buffer_read(buff, buffer_f32);
			var P2 = buffer_read(buff, buffer_f32);
			var N0 = buffer_read(buff, buffer_f32);
			var N1 = buffer_read(buff, buffer_f32);
			var N2 = buffer_read(buff, buffer_f32);
			var T0 = buffer_read(buff, buffer_f32);
			var T1 = buffer_read(buff, buffer_f32);
	
			buffer_seek(buff, buffer_seek_start, i + bytesPerVert)
			var P3 = buffer_read(buff, buffer_f32);
			var P4 = buffer_read(buff, buffer_f32);
			var P5 = buffer_read(buff, buffer_f32);
			var N3 = buffer_read(buff, buffer_f32);
			var N4 = buffer_read(buff, buffer_f32);
			var N5 = buffer_read(buff, buffer_f32);
			var T2 = buffer_read(buff, buffer_f32);
			var T3 = buffer_read(buff, buffer_f32);
	
			buffer_seek(buff, buffer_seek_start, i + 2 * bytesPerVert)
			var P6 = buffer_read(buff, buffer_f32);
			var P7 = buffer_read(buff, buffer_f32);
			var P8 = buffer_read(buff, buffer_f32);
			var N6 = buffer_read(buff, buffer_f32);
			var N7 = buffer_read(buff, buffer_f32);
			var N8 = buffer_read(buff, buffer_f32);
			var T4 = buffer_read(buff, buffer_f32);
			var T5 = buffer_read(buff, buffer_f32);
	
			var p1x = P3 - P0;
			var p1y = P4 - P1;
			var p1z = P5 - P2;
			var p2x = P6 - P0;
			var p2y = P7 - P1;
			var p2z = P8 - P2;
		
			var s1 = T2 - T0;
			var s2 = T4 - T0;
			var t1 = T3 - T1;
			var t2 = T5 - T1;
		
		    var r = 1.0 / max(epsilon, s1 * t2 - s2 * t1);
			var sdx = (t2 * p1x - t1 * p2x) * r;
			var sdy = (t2 * p1y - t1 * p2y) * r;
			var sdz = (t2 * p1z - t1 * p2z) * r;
			var tdx = (s1 * p2x - s2 * p1x) * r;
			var tdy = (s1 * p2y - s2 * p1y) * r;
			var tdz = (s1 * p2z - s2 * p1z) * r;
		
			bitangent[@ i div bytesPerTri] = [tdx, tdy, tdz];
	
			//Add the tangent to the ds_map
			var dp = N0 * sdx + N1 * sdy + N2 * sdz;
			var Tx = sdx - N0 * dp;
			var Ty = sdy - N1 * dp;
			var Tz = sdz - N2 * dp;
			var l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			if l != 0{
				Tx /= l;
				Ty /= l;
				Tz /= l;}
			var key = string(P0) + "," + string(P1) + "," + string(P2);
			var t = tangentMap[? key]
			if is_undefined(t)
			{
				tangentMap[? key] = [Tx, Ty, Tz];
			}
			else
			{
				t[@ 0] += Tx;
				t[@ 1] += Ty;
				t[@ 2] += Tz;
			}
	
	
			dp = N3 * sdx + N4 * sdy + N5 * sdz;
			Tx = sdx - N3 * dp;
			Ty = sdy - N4 * dp;
			Tz = sdz - N5 * dp;
			l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			if l != 0{
				Tx /= l;
				Ty /= l;
				Tz /= l;}
			key = string(P3) + "," + string(P4) + "," + string(P5);
			t = tangentMap[? key]
			if is_undefined(t)
			{
				tangentMap[? key] = [Tx, Ty, Tz];
			}
			else
			{
				t[@ 0] += Tx;
				t[@ 1] += Ty;
				t[@ 2] += Tz;
			}
	
	
			dp = N6 * sdx + N7 * sdy + N8 * sdz;
			Tx = sdx - N6 * dp;
			Ty = sdy - N7 * dp;
			Tz = sdz - N8 * dp;
			l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			if l != 0{
				Tx /= l;
				Ty /= l;
				Tz /= l;}
			key = string(P6) + "," + string(P7) + "," + string(P8);
			t = tangentMap[? key]
			if is_undefined(t)
			{
				tangentMap[? key] = [Tx, Ty, Tz];
			}
			else
			{
				t[@ 0] += Tx;
				t[@ 1] += Ty;
				t[@ 2] += Tz;
			}
		}
	}
	for (var m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];
		bufferSize = buffer_get_size(buff);
		bitangent = bitangentArray[m];
	
		//Write the tangent to the model
		for (i = 0; i < bufferSize; i += bytesPerVert)
		{
			buffer_seek(buff, buffer_seek_start, i)
			P0 = buffer_read(buff, buffer_f32);
			P1 = buffer_read(buff, buffer_f32);
			P2 = buffer_read(buff, buffer_f32);
			N0 = buffer_read(buff, buffer_f32);
			N1 = buffer_read(buff, buffer_f32);
			N2 = buffer_read(buff, buffer_f32);
			key = string(P0) + "," + string(P1) + "," + string(P2);
			t = tangentMap[? key];
			dp = t[0] * N0 + t[1] * N1 + t[2] * N2;
			Tx = t[0] - N0 * dp;
			Ty = t[1] - N1 * dp;
			Tz = t[2] - N2 * dp;
			l = sqrt(sqr(Tx) + sqr(Ty) + sqr(Tz));
			Tx /= l;
			Ty /= l;
			Tz /= l;
			//Calculate handedness
			var b = bitangent[i div bytesPerTri];
			var Th = sign(b[0] * (Ty * N8 - Tz * N7) + b[1] * (Tz * N6 - Tx * N8) + b[2] * (Tx * N7 - Ty * N6));
			buffer_seek(buff, buffer_seek_start, i + 8*4)
			buffer_write(buff, buffer_u8, (Tx + 1) * 127);
			buffer_write(buff, buffer_u8, (Ty + 1) * 127);
			buffer_write(buff, buffer_u8, (Tz + 1) * 127);
			buffer_write(buff, buffer_u8, (Th + 1) * 127);
		}
	}
	
	ds_map_destroy(tangentMap);


}
