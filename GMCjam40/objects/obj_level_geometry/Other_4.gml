/// @description
#macro inDevelopment 0
#macro exportLevels 1
#macro readyForRelease 2

var status = readyForRelease;

if (room == rm_menu){exit;}

if (status == inDevelopment || status == exportLevels)
{
	with obj_static_parent
	{
		addToLevel();
	}
	with obj_static_parent
	{
		instance_destroy();
	}
	if (status == exportLevels)
	{
		var saveBuff = buffer_create(1, buffer_grow, 1);
		buffer_write(saveBuff, buffer_u8, ds_map_size(texMap));
		var totalSize = 1;
	}

	var sprite = ds_map_find_first(texMap);
	while !is_undefined(sprite)
	{
		var mbuff = texMap[? sprite];
		
		if (status == exportLevels)
		{
			buffSize = buffer_get_size(mbuff);
			var str = sprite_get_name(sprite);
			buffer_write(saveBuff, buffer_string, str);
			buffer_write(saveBuff, buffer_u64, buffSize);
			totalSize = buffer_tell(saveBuff);
			buffer_copy(mbuff, 0, buffSize, saveBuff, totalSize);
			totalSize += buffSize;
			buffer_seek(saveBuff, buffer_seek_start, totalSize);
		}
		
		var vbuff = vertex_create_buffer_from_buffer(mbuff, global.ColMeshFormat);
		vertex_freeze(vbuff);
		ds_list_add(modelList, [vbuff, sprite_get_texture(sprite, 0)]);
		buffer_delete(mbuff);
	
		sprite = ds_map_find_next(texMap, sprite);
	}
	
	if (status == exportLevels)
	{
		levelColmesh.writeToBuffer(saveBuff);
		var size = buffer_tell(saveBuff);
		buffer_resize(saveBuff, size);
		var compressedBuffer = buffer_compress(saveBuff, 0, size);
		
		var path = get_save_filename("", room_get_name(room) + ".lvl");
		buffer_save(compressedBuffer, path);
		buffer_delete(saveBuff);
		buffer_delete(compressedBuffer);
	}
}

if (status == readyForRelease)
{
	with (obj_static_parent)
	{
		instance_destroy();
	}
	var mbuff = buffer_create(1, buffer_grow, 1);
	var path = "Levels/" + room_get_name(room) + ".lvl";
	var loadBuff = buffer_load(path);
	if (loadBuff < 0){exit;}
	var decompressedBuffer = buffer_decompress(loadBuff);
	buffer_delete(loadBuff);
	if (decompressedBuffer < 0){exit;}
	
	var num = buffer_read(decompressedBuffer, buffer_u8)
	for (var i = 0; i < num; i ++)
	{
		var str = buffer_read(decompressedBuffer, buffer_string);
		var sprite = asset_get_index(str);
		var size = buffer_read(decompressedBuffer, buffer_u64);
		buffer_copy(decompressedBuffer, buffer_tell(decompressedBuffer), size, mbuff, 0);
		buffer_resize(mbuff, size);
		buffer_seek(decompressedBuffer, buffer_seek_relative, size);
		
		var vbuff = vertex_create_buffer_from_buffer(mbuff, global.ColMeshFormat);
		vertex_freeze(vbuff);
		ds_list_add(modelList, [vbuff, sprite_get_texture(sprite, 0)]);
	}
	buffer_delete(mbuff);
	
	levelColmesh.readFromBuffer(decompressedBuffer);
	buffer_delete(decompressedBuffer);
}