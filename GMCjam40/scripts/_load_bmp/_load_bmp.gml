/// @description smf_load_bmp(file)
/// @param file
function _load_bmp(argument0) {
	/*
		Script made by Icuurd12b42, modified by TheSnidr to load bmp files as sprites
	*/
	var fname = argument0;
	if(!file_exists(fname))
	{
	    show_message("File does not exist\n"+string(fname)) 
	    return -1;
	}
	var buff; 
	buff = buffer_load(fname);

	if (buff<=0) 
	{
	    show_message("Error opening file\n"+string(fname)) 
	    return -1;
	}
 
 
	var magicNumber; magicNumber = chr(buffer_read(buff, buffer_u8)) + chr(buffer_read(buff, buffer_u8));
	if (magicNumber!="BM") 
	{ 
	    show_message("File is not a BMP\n"+string(fname)) 
	    buffer_delete(buff);
	    return -1;
	}

	//Read header
	var fileSize = buffer_read(buff, buffer_u32);
	var unused0 = buffer_read(buff, buffer_u32);
	var dataOffset = buffer_read(buff, buffer_u32);
	var headerBytes = buffer_read(buff, buffer_u32);
	var width = buffer_read(buff, buffer_u32);
	var height = buffer_read(buff, buffer_u32);
	var colorPlanes = buffer_read(buff, buffer_u16);
	var bitsPerPixel = buffer_read(buff, buffer_u16);
	var compression = buffer_read(buff, buffer_u32);
	var dataSize = buffer_read(buff, buffer_u32);
	var resolutionx = buffer_read(buff, buffer_u32);
	var resolutiony = buffer_read(buff, buffer_u32);
	var colorsInPalette = buffer_read(buff, buffer_u32);
	var importantColors = buffer_read(buff, buffer_u32);

	if(bitsPerPixel != 32 and bitsPerPixel != 24)
	{ 
	    show_message("File must be true color (24 or 32 bpp)\nFailed to load file: "+string(fname)+"\nThis file has "+string(bitsPerPixel) + " bpp") 
	    buffer_delete(buff);
	    return -1;
	} 

	if(compression != 0)
	{ 
	    show_message("Compressed BMP is not supported\n"+string(fname)) 
	    buffer_delete(buff);
	    return -1;
	}

	buffer_seek(buff, buffer_seek_start, dataOffset)
	var s = surface_create(width, height);
	var texBuff = buffer_create(width * height * 4, buffer_grow, 1);
	var b, g, r, a;
	if(bitsPerPixel == 32)
	{
		repeat width * height
		{
			b = buffer_read(buff, buffer_u8);
			g = buffer_read(buff, buffer_u8);
			r = buffer_read(buff, buffer_u8);
			a = buffer_read(buff, buffer_u8);
			buffer_write(texBuff, buffer_u8, r);
			buffer_write(texBuff, buffer_u8, g);
			buffer_write(texBuff, buffer_u8, b);
			buffer_write(texBuff, buffer_u8, a);
		}
	}
	else if(bitsPerPixel == 24)
	{
		repeat width * height
		{
			b = buffer_read(buff, buffer_u8);
			g = buffer_read(buff, buffer_u8);
			r = buffer_read(buff, buffer_u8);
			buffer_write(texBuff, buffer_u8, r);
			buffer_write(texBuff, buffer_u8, g);
			buffer_write(texBuff, buffer_u8, b);
			buffer_write(texBuff, buffer_u8, 255);
		}
	}
	buffer_set_surface(texBuff, s, 0);

	var spr = sprite_create_from_surface(s, 0, 0, width, height, 0, 0, 0, 0);
	surface_free(s);
	buffer_delete(buff);
	buffer_delete(texBuff);

	return spr;


}
