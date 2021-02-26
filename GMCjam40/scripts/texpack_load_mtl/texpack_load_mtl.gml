/// @description texpack_load_mtl(fname, mtlNames)
/// @param fname
/// @param mtlNames
function texpack_load_mtl(argument0, argument1) {
	/*
		Loads a .mtl file and applies it to the given model.
		Note that the material references in the model index must match
		the materials in the mtl file.

		Thanks to Dragonite and his video on the MTL format:
		https://www.youtube.com/watch?v=hcJEDWjZU_I
	*/
	var fname = argument0;
	var mtlNames = argument1;

	var file = file_text_open_read(fname);
	if file < 0
	{
		show_debug_message("ERROR in script texpack_load_mtl: Failed to load mtl file " + string(fname));
		return false;
	}
	show_debug_message("Script texpack_load_mtl: Loading mtl file " + string(fname));

	var path = filename_path(fname);

	var currentMtl = "";
	var mtlMap = ds_map_create();
	var texMap = ds_map_create();
	var colMap = ds_map_create();

	var line, terms, index;
	while !file_text_eof(file)
	{
		line = string_replace_all(file_text_read_string(file),"	","");
		line = string_replace_all(line,"  "," ");
		file_text_readln(file);
		//Split each line around the space character
		index = 0;
		terms = array_create(string_count(line, " ") + 1, "");
		for (var i = 1; i <= string_length(line); i ++)
		{
			if string_char_at(line, i) == " " && ((terms[0] != "map_Ka" && terms[0] != "map_Kd" && index > 0) || (index == 0))
			{
				index ++;
				terms[index] = "";
			}
			else
			{
				terms[index] += string_char_at(line, i);
			}
		}
		switch terms[0]
		{
			case "newmtl":
				//New material
				currentMtl = terms[1];
				break;
			//case "Kd":
			case "Ka":
				//Colour
				var col = [0, 0, 0, 1];
				if !is_undefined(colMap[? currentMtl]){col = colMap[? currentMtl];}
				else{colMap[? currentMtl] = col;}
				col[@ 0] = real(terms[1]);
				col[@ 1] = real(terms[2]);
				col[@ 2] = real(terms[3]);
				break;
			case "d":
				//Alpha
				var col = [0, 0, 0, 1];
				if !is_undefined(colMap[? currentMtl]){col = colMap[? currentMtl];}
				else{colMap[? currentMtl] = col;}
				col[@ 3] = real(terms[1]);
				break;
			case "Ks":
				//Specularity
				/*var term = 1;
				if terms[1] == "spectral"{break;}
				if terms[1] == "xyz"{term ++;}
				specularity = clamp(real(terms[term]), 0, 1);*/
				break;
			case "Ns":
				//Specularity
				/*specularity = clamp(real(terms[1]), 1, 1000);*/
				break;
			case "Tr":
				//Transparency
				/*alpha = 1 - real(terms[1]);*/
				break;
			case "map_Ka":
			case "map_Kd":
				//Load texture
				var texPath = path + filename_name(terms[1]);
				var texName = filename_name(filename_change_ext(texPath, ""));
				mtlMap[? currentMtl] = texName;
				if is_undefined(texMap[? texName])
				{
					texMap[? texName] = texpack_load_sprite(texPath);
					if texMap[? texName] < 0
					{
						texPath = path + "textures\\" + filename_name(terms[1]);
						texMap[? texName] = texpack_load_sprite(texPath);
					}
				}
				break;
		}
	}
	file_text_close(file);

	//Assign the textures to the texture map
	var spr;
	var mtlNum = array_length(mtlNames);
	var texPack = array_create(mtlNum);
	for (var i = 0; i < mtlNum; i ++)
	{
		texName = mtlMap[? mtlNames[i]];
		if is_undefined(texName)
		{
			//If the texture does not exist, we can instead check if the material has a colour. If it does, create a new texture with only that colour.
			var col = colMap[? mtlNames[i]];
			if !is_undefined(col)
			{
				var s = surface_create(4, 4);
				surface_set_target(s);
				draw_clear_alpha(make_color_rgb(col[0] * 255, col[1] * 255, col[2] * 255), col[3]);
				surface_reset_target();
				texPack[i] = sprite_create_from_surface(s, 0, 0, 4, 4, 0, 0, 0, 0);
				surface_free(s);
				continue;
			}
			else
			{
				texPack[i] = -1;
				continue;
			}
		}
		spr = texMap[? texName];
		if is_undefined(spr)
		{
			//Texture does not exist
			texPack[i] = -1;
			continue;
		}
		texPack[i] = spr;
	}

	//Clean up
	ds_map_destroy(mtlMap);
	ds_map_destroy(texMap);
	ds_map_destroy(colMap);

	return texPack;


}
