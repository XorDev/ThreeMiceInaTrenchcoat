/// @description mbuff_combine_to_texpage(mBuff, texPack, padding, maxSize, forcePowerOfTwo)
/// @param mBuff
/// @param texPack
/// @param padding
/// @param maxSize
/// @param forcePowerOfTwo
function mbuff_combine_to_texpage(argument0, argument1, argument2, argument3, argument4) {
	var mBuff = argument0;
	var texPack = argument1;
	var padding = argument2;
	var maxSize = argument3;
	var forcePow2 = argument4;

	if (!is_array(mBuff)){mBuff = [mBuff];}
	var modelNum = array_length(mBuff);
	if (modelNum <= 0){return -1;}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Index batched models
	var texPagePriority = ds_priority_create();
	var texToPageMap = ds_map_create();

	//Rotate textures that are standing, tesselate model and add textures to priority based on their size
	var m, tex, w, h;
	var texPackSize = array_length(texPack);
	var modelsPerTex = texPackSize * ceil(modelNum / texPackSize);
	var s = surface_create(2, 2);
	surface_set_target(s);
	draw_clear(c_white);
	surface_reset_target();
	var noTex = sprite_create_from_surface(s, 0, 0, 2, 2, 0, 0, 0, 0);
	surface_free(s);
	for (t = 0; t < texPackSize; t ++)
	{
		tex = texPack[t];
		if (tex < 0)
		{
			texPack[t] = noTex;
			tex = texPack[t];
		}
		if is_undefined(ds_priority_find_priority(texPagePriority, tex))
		{
			w = sprite_get_width(tex);
			h = sprite_get_height(tex);
			if (h > w)
			{
				texPack[t] = _mbuff_rotate_sprite(tex);
				tex = texPack[t];
			}
			ds_priority_add(texPagePriority, tex, sprite_get_width(tex) + sprite_get_height(tex));
			for (m = t; m < modelNum; m += modelsPerTex)
			{
				if (h > w)
				{
					mbuff_rotate_uvs(mBuff[m]);
				}
				mbuff_tesselate_uvs(mBuff[m]);
			}
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Create texture pages
	var texNum = ds_priority_size(texPagePriority);
	if texNum <= 0{return -1;}

	var image_list, texPages, texPageW, texPageH, freeSpace, texInd;
	image_list = ds_list_create();
	texPages = 1;
	texInd = ds_priority_find_max(texPagePriority);
	texPageW[0] = sprite_get_width(texInd) + 2*padding;
	texPageH[0] = sprite_get_height(texInd) + 2*padding;
	if forcePow2
	{
		texPageW[0] = power(2, ceil(log2(texPageW[0])));
		texPageH[0] = power(2, ceil(log2(texPageH[0])));
	}
	if max(texPageW[0], texPageH[0]) > maxSize
	{
		show_debug_message("Error in script mbuff_combine_to_texpage: Textures do not fit on texture page size. The max size of the texture pages will not be correct.");
	}
	freeSpace[0] = ds_list_create();
	ds_list_add(freeSpace[0], 0, 0, texPageW[0], texPageH[0]);

	//Create necessary data structures
	while ds_priority_size(texPagePriority)
	{
		texInd = ds_priority_delete_max(texPagePriority);
		texW = sprite_get_width(texInd) + 2*padding;
		texH = sprite_get_height(texInd) + 2*padding;
		chosenRegion = -1;
		minH = 9999;
	
		//Loop through existing texture pages to see if the sprite can be fit in somewhere
		for (var i = 0; i < texPages; i ++)
		{
			var num = ds_list_size(freeSpace[i]);
			for (var n = 0; n < num; n += 4)
			{
				//If the sprite fits in the free space, great! We can end the search process here then
				spaceLeft = ds_list_find_value(freeSpace[i], n);
				spaceUpper = ds_list_find_value(freeSpace[i], n+1);
				spaceRight = ds_list_find_value(freeSpace[i], n+2);
				spaceLower = ds_list_find_value(freeSpace[i], n+3);
				spaceW = spaceRight - spaceLeft;
				spaceH = spaceLower - spaceUpper;
				if (spaceW >= texW && spaceH >= texH && spaceH < minH)
				{
					chosenRegion = n;
					minH = spaceH;
				}
			}
			if (chosenRegion >= 0){break;}
			
			//The sprite does not fit in any of the free areas. We need to expand!
			//First, search through and see if any free regions can be expanded just slightly to fit the sprite
			if texPageH[i] > texPageW[i]
			{
				for (var n = 0; n < num; n += 4)
				{
					spaceLeft = ds_list_find_value(freeSpace[i], n);
					spaceUpper = ds_list_find_value(freeSpace[i], n+1);
					spaceRight = ds_list_find_value(freeSpace[i], n+2);
					spaceLower = ds_list_find_value(freeSpace[i], n+3);
					spaceH = spaceLower - spaceUpper;
					if (spaceRight >= texPageW[i] and spaceH >= texH)
					{
						spaceRight = spaceLeft + texW;
						if forcePow2{spaceRight = power(2, ceil(log2(spaceRight)));}
						if spaceRight > maxSize{continue;}
						//Expand free areas
						for (var nn = 0; nn < ds_list_size(freeSpace[i]); nn += 4)
						{
							var __Right = ds_list_find_value(freeSpace[i], nn+2);
							if (__Right == texPageW[i])
							{
								ds_list_set(freeSpace[i], nn+2, spaceRight);
							}
						}
						//Create new free areas where sprites touch the old border
						for (var nn = 0; nn < ds_list_size(image_list); nn += 4)
						{
							if image_list[| nn+1] != i{continue;}
							var __tex = image_list[| nn];
							var __Right = image_list[| nn+2] + sprite_get_width(__tex) + padding;
							if (__Right <= texPageW[i] - 1){continue;}
							ds_list_add(freeSpace[i], __Right, image_list[| nn+3] - padding, spaceRight, image_list[| nn+3] + sprite_get_height(__tex) + padding);
						}
						//Resize texpage
						texPageW[i] = spaceRight;
						chosenRegion = n;
						break;
					}
				}
				if (chosenRegion >= 0){break;}
			
				//If no regions could be expanded, we'll have to expand in the entire width of the sprite
				newW = texPageW[i] + texW;
				if forcePow2{newW = power(2, ceil(log2(newW)));}
				if newW > maxSize{continue;}
			
				chosenRegion = ds_list_size(freeSpace[i]);
				ds_list_add(freeSpace[i], texPageW[i], 0, newW, texPageH[i]);
				texPageW[i] = newW;
				break;
			}
			else
			{
				for (var n = 0; n < num; n += 4)
				{
					spaceLeft = ds_list_find_value(freeSpace[i], n);
					spaceUpper = ds_list_find_value(freeSpace[i], n+1);
					spaceRight = ds_list_find_value(freeSpace[i], n+2);
					spaceLower = ds_list_find_value(freeSpace[i], n+3);
					spaceW = spaceRight - spaceLeft;
					if (spaceLower >= texPageH[i] and spaceW >= texW)
					{
						spaceLower = spaceUpper + texH;
						if forcePow2{spaceLower = power(2, ceil(log2(spaceLower)));}
						if (spaceLower > maxSize){continue;}
						//Expand free areas
						for (var nn = 0; nn < ds_list_size(freeSpace[i]); nn += 4)
						{
							var __Lower = ds_list_find_value(freeSpace[i], nn+3);
							if (__Lower == texPageH[i])
							{
								ds_list_set(freeSpace[i], nn+3, spaceLower);
							}
						}
						//Create new free areas where sprites touch the old border
						for (var nn = 0; nn < ds_list_size(image_list); nn += 4)
						{
							if image_list[| nn+1] != i{continue;}
							var __tex = image_list[| nn];
							var __Lower = image_list[| nn+3] + sprite_get_height(__tex) + padding;
							if (__Lower <= texPageH[i] - 1){continue;}
							ds_list_add(freeSpace[i], image_list[| nn+2] - padding, __Lower, image_list[| nn+2] + sprite_get_width(__tex) + padding, spaceLower);
						}
						//Resize texpage
						texPageH[i] = spaceLower;
						chosenRegion = n;
						break;
					}
				}
				if (chosenRegion >= 0){break;}
			
				//If no regions could be expanded, we'll have to expand in the entire width of the sprite
				newH = texPageH[i] + texH;
				if forcePow2{newH = power(2, ceil(log2(newH)));}
				if newH > maxSize{continue;}
			
				chosenRegion = ds_list_size(freeSpace[i]);
				ds_list_add(freeSpace[i], 0, texPageH[i], texPageW[i], newH);
				texPageH[i] = newH;
				break;
			}
		}
		//The sprite could not fit on any texpage, and we have to create a new texture page
		if (chosenRegion < 0)
		{
			i = texPages;
			texPages ++;
			texPageW[i] = sprite_get_width(tex) + 2*padding;
			texPageH[i] = sprite_get_height(tex) + 2*padding;
			if forcePow2
			{
				texPageW[i] = power(2, ceil(log2(texPageW[i])));
				texPageH[i] = power(2, ceil(log2(texPageH[i])));
			}
			if max(texPageW[i], texPageH[i]) > maxSize
			{
				show_debug_message("Error in script mbuff_combine_to_texpage: Textures do not fit on texture page size. The max size of the texture pages will not be correct.");
			}
			freeSpace[i] = ds_list_create();
			ds_list_add(freeSpace[i], 0, 0, texPageW[0], texPageH[0]);
			chosenRegion = 0;
		}
	
		//Add sprite to texture page
		spaceLeft = ds_list_find_value(freeSpace[i], chosenRegion);
		spaceUpper = ds_list_find_value(freeSpace[i], chosenRegion+1);
		spaceRight = ds_list_find_value(freeSpace[i], chosenRegion+2);
		spaceLower = ds_list_find_value(freeSpace[i], chosenRegion+3);
		texToPageMap[? texInd] = ds_list_size(image_list);
		ds_list_add(image_list, texInd, i, spaceLeft + padding, spaceUpper + padding);
		repeat 4{ds_list_delete(freeSpace[i], chosenRegion);}
		if texW < spaceRight - spaceLeft{ds_list_add(freeSpace[i], spaceLeft + texW, spaceUpper, spaceRight, spaceUpper + texH);}
		if texH < spaceLower - spaceUpper{ds_list_add(freeSpace[i], spaceLeft, spaceUpper + texH, spaceRight, spaceLower);}
	}


	//GPU settings
	matrix_set(matrix_view, matrix_build_identity());
	matrix_set(matrix_world, matrix_build_identity());
	gpu_set_zwriteenable(false);
	gpu_set_cullmode(cull_noculling);
	gpu_set_blendmode_ext(bm_one, bm_zero);
	gpu_set_texrepeat(false);
	draw_set_color(c_white);
	draw_set_alpha(1);

	//Create new texture pack
	var newTexPack = array_create(texPages);
	var newMbuff = array_create(texPages, -1);
	for (var i = 0; i < texPages; i ++)
	{
		var s = surface_create(texPageW[i], texPageH[i]);
		surface_set_target(s);
		draw_clear_alpha(c_white, 0);
		//Draw sprites to surface
		for (var t = 0; t < ds_list_size(image_list); t += 4)
		{
			if (image_list[| t+1] != i){continue;}
			tex = image_list[| t];
			texPadX = padding / sprite_get_width(tex);
			texPadY = padding / sprite_get_height(tex);
			w = sprite_get_width(tex);
			h = sprite_get_height(tex);
			draw_primitive_begin_texture(pr_trianglestrip, sprite_get_texture(tex, 0));
			uv = texture_get_uvs(sprite_get_texture(tex, 0));
			uv[2] = texture_get_width(sprite_get_texture(tex, 0));
			uv[3] = texture_get_height(sprite_get_texture(tex, 0));
			draw_vertex_texture(image_list[| t+2]-padding,   image_list[| t+3]-padding,   uv[0] - uv[2] * texPadX,		uv[1] - uv[3] * texPadY);
			draw_vertex_texture(image_list[| t+2]+padding+w, image_list[| t+3]-padding,   uv[0] + uv[2] * (1+texPadX),	uv[1] - uv[3] * texPadY);
			draw_vertex_texture(image_list[| t+2]-padding,   image_list[| t+3]+padding+h, uv[0] - uv[2] * texPadX,		uv[1] + uv[3] * (1+texPadY));
			draw_vertex_texture(image_list[| t+2]+padding+w, image_list[| t+3]+padding+h, uv[0] + uv[2] * (1+texPadX),	uv[1] + uv[3] * (1+texPadY));
			draw_primitive_end();
		}
		//Draw free areas as rectangles
		var num = ds_list_size(freeSpace[i]);
		draw_set_colour(c_black);
		for (var n = 0; n < num; n += 4)
		{
			spaceLeft = ds_list_find_value(freeSpace[i], n);
			spaceUpper = ds_list_find_value(freeSpace[i], n+1);
			spaceRight = ds_list_find_value(freeSpace[i], n+2);
			spaceLower = ds_list_find_value(freeSpace[i], n+3);
			draw_rectangle(spaceLeft, spaceUpper-1, spaceRight-1, spaceLower-1, true);
		}
		draw_set_colour(c_white);
		surface_reset_target();
		newTexPack[i] = sprite_create_from_surface(s, 0, 0, texPageW[i], texPageH[i], 0, 0, 0, 0);
		surface_free(s);
	}

	gpu_set_blendmode(bm_normal);
	
	//Now, to combine the models that use the same textures
	var bytesPerVert, buff, buffSize, newBuff, oldBuffSize;
	bytesPerVert = mBuffBytesPerVert;
	for (m = 0; m < modelNum; m ++)
	{
		//Modify the UVs to fit the tex page
		var texPage, texX, texY, texW, texH, u, v, j;
		t = texToPageMap[? texPack[m mod texPackSize]];
		texInd = image_list[| t];
		texPage = image_list[| t+1];
		texX = image_list[| t+2] / texPageW[texPage];
		texY = image_list[| t+3] / texPageH[texPage];
		texW = sprite_get_width(texInd) / texPageW[texPage];
		texH = sprite_get_height(texInd) / texPageH[texPage];
		buff = mBuff[m];
		buffSize = buffer_get_size(buff);
		for (j = 0; j < buffSize; j += bytesPerVert)
		{
			u = buffer_peek(buff, j + 6 * 4, buffer_f32);
			v = buffer_peek(buff, j + 7 * 4, buffer_f32);
			buffer_poke(buff, j + 6 * 4, buffer_f32, texX + texW * u);
			buffer_poke(buff, j + 7 * 4, buffer_f32, 1 - (texY + texH * v));
		}
		
		//Combine vertex buffers using the same texture and material
		newBuff = newMbuff[texPage];
		if (newBuff <= -1)
		{
			newBuff = buffer_create(buffSize, buffer_fixed, 1);
			buffer_copy(buff, 0, buffSize, newBuff, 0);
			newMbuff[texPage] = newBuff;
		}
		else
		{
			oldBuffSize = buffer_get_size(newBuff);
			buffer_resize(newBuff, oldBuffSize + buffSize);
			buffer_copy(buff, 0, buffSize, newBuff, oldBuffSize);
		}
	}

	return [newMbuff, newTexPack];


}
