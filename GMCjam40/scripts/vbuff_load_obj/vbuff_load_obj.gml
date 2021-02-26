/// @description vbuff_load_obj(fname)
/// @param fname
function vbuff_load_obj(argument0) {
	/*
		Loads an obj file and returns a vertex buffer or an array of vertex buffers
	
		Script created by TheSnidr, 2019
		www.thesnidr.com
	*/
	var fname = argument0;
	var mBuff = mbuff_load_obj(fname);
	var vBuff = vbuff_create_from_mbuff(mBuff);
	mbuff_delete(mBuff);
	return vBuff;


}
