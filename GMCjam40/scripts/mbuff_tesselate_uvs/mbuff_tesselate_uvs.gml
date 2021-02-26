/// @description mbuff_tesselate_uvs(mBuff)
/// @param mBuff
function mbuff_tesselate_uvs(argument0) {
	/*
		Tesselates the UVs of the given mBuff so that all UVs are within the range 0-1.
		This is useful for texture page optimization, but will increase the number of vertices.
	
		Script created by Sindre Hauge Larsen anno 2019
		www.thesnidr.com
	*/

	var i, j, k, startU, startV, endU, endV, amount, vert0, vert1, vert2, corner, width, height, array, k, w, dU, dV, l, p, nextP, minAngle, angle, clockwise;
	var mBuff = argument0;
	if !is_array(mBuff){mBuff = [mBuff];}
	var modelNum = array_length(mBuff);
	if modelNum <= 0{return -1;}

	//Initialize arrays
	var pointGrid, bytesPerVert, corner, w, m, buff, buffSize, tempBuffer, c1, c2, c3, c, start, stop, u, v, val, num, middleX, middleY, pos, sortedArray, _w, M; 
	w = array_create(3);
	corner = [array_create(11), array_create(11), array_create(11)];

	//Lists needed for splitting up a triangle
	pointGrid = ds_grid_create(1, 1);

	bytesPerVert = mBuffBytesPerVert;
	for (m = 0; m < modelNum; m ++)
	{
		buff = mBuff[m];

		//Create new buffer that will replace the original modelBuffer
		buffSize = buffer_get_size(buff);
		tempBuffer = buffer_create(buffSize, buffer_grow, 1);
	
		//Copy metadata from original to new buffer
		buffer_seek(tempBuffer, buffer_seek_start, 0);
		buffer_seek(buff, buffer_seek_start, 0);
	
		//Loop through all triangles in the original buffer (skipping the metadata at the start of the buffer)
		for (i = 0; i < buffSize; i += bytesPerVert)
		{
			//Load the vertex position and UVs
			j = (i div bytesPerVert) mod 3;
			for (k = 0; k < 11; k ++)
			{
				array_set(corner[j], k, buffer_read(buff, buffer_f32));
			}
			if j != 2{continue;}
	
			//Find out how many times the texture repeats in the U and V directions
			c1 = corner[0];
			c2 = corner[1];
			c3 = corner[2];
			startU = floor(min(c1[6], c2[6], c3[6]));
			startV = floor(min(c1[7], c2[7], c3[7]));
			endU = ceil(max(c1[6], c2[6], c3[6]));
			endV = ceil(max(c1[7], c2[7], c3[7]));
			width = endU - startU;
			height = endV - startV;
		
			if ((width <= 1 && height <= 1) || (width > 100) || (height > 100))
			{
				//The triangle is either confined within the desired range of 0-1 already, or it is too large. In these cases, we can simply copy the triangle over.
				for (k = 0; k < 3; k ++)
				{
					c = corner[k];
					for (l = 0; l < 11; l ++)
					{
						val = c[l];
						if l == 6{val -= startU;}
						if l == 7{val -= startV;}
						buffer_write(tempBuffer, buffer_f32, val);
					}
				}
				continue;
			}	
		
			clockwise = sign((c2[7] - c1[7]) * (c3[6] - c1[6]) - (c2[6] - c1[6]) * (c3[7] - c1[7]));
			ds_grid_clear(pointGrid, -1);
			ds_grid_resize(pointGrid, width + 1, height + 1);
		
			//Add the corner points to the point grid
			_mbuff_tesselate_add_point(pointGrid, [c1[6], c1[7]], startU, startV);
			_mbuff_tesselate_add_point(pointGrid, [c2[6], c2[7]], startU, startV);
			_mbuff_tesselate_add_point(pointGrid, [c3[6], c3[7]], startU, startV);
		
			//Split the triangle edges along U and V and add to the point grid
			for (k = 0; k < 3; k ++)
			{
				vert0 = corner[k];
				vert1 = corner[(k+1) mod 3];
				dU = vert1[6] - vert0[6];
				dV = vert1[7] - vert0[7];
				if (dU != 0)
				{
					dU = 1 / dU;
					start = ceil(min(vert0[6], vert1[6]));
					stop = ceil(max(vert0[6], vert1[6]));
					for (u = start; u < stop; u ++)
					{
						amount = (u - vert0[6]) * dU;
						if (amount < 0 || amount > 1){continue;}
						v = lerp(vert0[7], vert1[7], amount);
						_mbuff_tesselate_add_point(pointGrid, [u, v], startU, startV);
					}
				}
				if (dV != 0)
				{
					dV = 1 / dV;
					start = ceil(min(vert0[7], vert1[7]));
					stop = ceil(max(vert0[7], vert1[7]));
					for (v = start; v < stop; v ++)
					{
						amount = (v - vert0[7]) * dV;
						if (amount < 0 || amount > 1){continue;}
						u = lerp(vert0[6], vert1[6], amount);
						_mbuff_tesselate_add_point(pointGrid, [u, v], startU, startV);
					}
				}
			}
		
			//And finally, add all grid points inside the triangle to the point grid
			for (u = startU + 1; u < endU; u ++)
			{
				for (v = startV + 1; v < endV; v ++)
				{
					if point_in_triangle(u, v, c1[6], c1[7], c2[6], c2[7], c3[6], c3[7])
					{
						_mbuff_tesselate_add_point(pointGrid, [u, v], startU, startV);
					}
				}
			}
		
			for (u = startU; u < endU; u ++)
			{
				for (v = startV; v < endV; v ++)
				{
					array = pointGrid[# u - startU, v - startV];
					if !is_array(array){continue;}
					num = array_length(array);
					if num <= 2{continue;}
				
					//Trim away points outside this region, and find the middle coordinates
					middleX = 0;
					middleY = 0;
					for (p = 0; p < num; p ++)
					{
						middleX += array_get(array[p], 0);
						middleY += array_get(array[p], 1);
					}
					middleX /= num;
					middleY /= num;
			
					//Sort the points in anti-clockwise order
					pos = 0;
					sortedArray = array_create(num);
					while pos < num
					{
						minAngle = 360;
						nextP = 0;
						for (p = 0; p < num - pos; p ++)
						{
							angle = clockwise * point_direction(middleX, middleY, array_get(array[p], 0), array_get(array[p], 1));
							if angle < minAngle
							{
								minAngle = angle;
								nextP = p;
							}
						}
						sortedArray[pos++] = array[nextP];
						array = _array_delete(array, nextP);
					}
			
					//Add the points to the vertex buffer in a trianglefan-like fashion
					w[0] = _mbuff_get_triangle_weights(c1[6], c1[7], c2[6], c2[7], c3[6], c3[7], array_get(sortedArray[0], 0), array_get(sortedArray[0], 1));
					w[2] = _mbuff_get_triangle_weights(c1[6], c1[7], c2[6], c2[7], c3[6], c3[7], array_get(sortedArray[1], 0), array_get(sortedArray[1], 1));
					for (p = 2; p < num; p ++)
					{
						w[1] = w[2];
						w[2] = _mbuff_get_triangle_weights(c1[6], c1[7], c2[6], c2[7], c3[6], c3[7], array_get(sortedArray[p], 0), array_get(sortedArray[p], 1));
					
						//Write vertices to buffer
						for (k = 0; k < 3; k ++)
						{
							_w = w[k];
							for (l = 0; l < 9; l ++)
							{
								val = c1[l] * _w[0] + c2[l] * _w[1] + c3[l] * _w[2];
								if l == 6{val -= u;}
								if l == 7{val -= v;}
								buffer_write(tempBuffer, buffer_f32, val);
							}
							//Bone indices and weights should not be blended
							M = max(_w[0], _w[1], _w[2]);
							buffer_write(tempBuffer, buffer_f32, (_w[0] == M) ? c1[9] : ((_w[1] == M) ? c2[9] : c3[9]));
							buffer_write(tempBuffer, buffer_f32, (_w[0] == M) ? c1[10] : ((_w[1] == M) ? c2[10] : c3[10]));
						}
					}
				}
			}
		}
		buffSize = buffer_tell(tempBuffer);
		buffer_resize(buff, buffSize);
		buffer_copy(tempBuffer, 0, buffSize, buff, 0);
		buffer_delete(tempBuffer);
	}

	ds_grid_destroy(pointGrid);


}
