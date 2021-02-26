/// @description mbuff_load_zip_ext(fname, load_textures)
/// @param fname
/// @param load_textures
function mbuff_load_zip_ext(argument0, argument1) {
	/*
	Unpacks zip and indexes the contents.
	Attempts to load all compatible models, materials and textures contained in the zip.

	This script will load the following file types from the zip:
		.smf
		.obj
		.mtl
	Returns an array of the following format:
		[mBuff, TexPack]

	Script created by TheSnidr 2019
	www.TheSnidr.com
	*/
	var fname, loadTex, mBuff, texPack, folderName, unzipSuccessful, fileList, source, p, n, i, filepath;
	fname = argument0;
	loadTex = argument1;
	mBuff = [];
	texPack = [];

	//Unzip the package
	folderName = "Zip";
	directory_destroy(folderName);
	directory_create(folderName);
	unzipSuccessful = zip_unzip(fname, game_save_id + folderName + "\\");
	if unzipSuccessful <= 0
	{
		show_message("ERROR in script mbuff_load_zip_ext: Could not unzip file " + string(fname));
		return false;
	}

	//Index the contents of all folders in the zip and load everything
	var stack = ds_stack_create();
	fileList = ds_list_create();
	source = folderName;
	p = -1;
	while true
	{
		if ++p == 0
		{
			fname = file_find_first(source + "/*.*", fa_directory);
			while (fname != "")
			{
			    ds_list_add(fileList, fname);
			    fname = file_find_next();
			}
			file_find_close();
			show_debug_message("Script mbuff_load_zip_ext: Folder " + source + " contains " + string(ds_list_size(fileList)) + " files.");
		}
	
		n = ds_list_size(fileList);
		for (i = p; i < n; i++) 
		{
		    fname = fileList[| i];
		    filepath = source + @"\" + fname;
		    if (directory_exists(filepath)) 
			{
				ds_stack_push(stack, fileList, source, i);
				fileList = ds_list_create();
				source = filepath;
				p = -1;
				break;
		    }
			else
			{
				show_debug_message("Script mbuff_load_zip_ext: Attempting to load file " + fname);
				switch string_lower(filename_ext(fname))
				{
					case ".obj":
						var ind, obj;
						ind = array_length(mBuff);
						obj = mbuff_load_obj_ext(filepath, true);
						mBuff = mbuff_add(mBuff, obj[0]);
						if loadTex && array_length(obj[1]) > 0
						{
							array_copy(texPack, ind, obj[1], 0, array_length(obj[1]));
						}
						break;
					case ".smf":
						//smf_model_add_smf(modelIndex, filepath);
						break;
				}
			}
		}
		if i < n{continue;}
		ds_list_destroy(fileList);
		if ds_stack_empty(stack){break;}
	
		p = ds_stack_pop(stack);
		source = ds_stack_pop(stack);
		fileList = ds_stack_pop(stack);
	}
	directory_destroy(folderName);
	ds_stack_destroy(stack);

	return [mBuff, texPack];


}
