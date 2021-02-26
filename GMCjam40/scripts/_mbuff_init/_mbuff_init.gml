/// @description _mbuff_init()
function _mbuff_init() {
	/*
		Initializes snidrs model buffer system.
	
		The script is global in scope, and it is as such not necessary to call it from anywhere.

		Script made by TheSnidr
		www.TheSnidr.com
	*/
	gml_pragma("global", "_mbuff_init()");

#macro mBuffMetaDataID 265168121 //Arbitrary four-bit integer

	//Create standard format
	vertex_format_begin();
	vertex_format_add_position_3d();
	vertex_format_add_normal();
	vertex_format_add_texcoord();
	vertex_format_add_color();
	global.mBuffStdFormat = vertex_format_end();
	global.mBuffStdValues = 12;
#macro mBuffStdBytesPerVert 36

	//Create full format
	vertex_format_begin();
	vertex_format_add_position_3d();
	vertex_format_add_normal();
	vertex_format_add_texcoord();
	vertex_format_add_color();
	vertex_format_add_color();
	vertex_format_add_color();
	global.mBuffFormat = vertex_format_end();
	global.mBuffValues = 20;
#macro mBuffBytesPerVert 44

	//Create a map that keeps track of externally loaded sprites
	global.TexMapExternalSprite = ds_map_create();


}
