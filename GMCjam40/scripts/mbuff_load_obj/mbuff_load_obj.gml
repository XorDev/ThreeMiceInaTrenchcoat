/// @description mbuff_load_obj(fname)
/// @param fname
function mbuff_load_obj(argument0) {
	/*
		Loads an OBJ file and returns an array of buffers.
	
		Script created by TheSnidr, 2019
		www.thesnidr.com
	*/
	var fname = argument0;

	var model = mbuff_load_obj_ext(fname, false);

	return model[0];


}
