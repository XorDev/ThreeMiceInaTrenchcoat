/// @description mbuff_load(fname)
/// @param fname
function mbuff_load(argument0) {
	/*
		Load an mBuff from file

		Script created by TheSnidr, 2019
		www.thesnidr.com
	*/
	var fname, loadBuff, mBuff;
	fname = argument0;
	loadBuff = buffer_load(fname);
	mBuff = mbuff_read_from_buffer(loadBuff);
	buffer_delete(loadBuff);
	return mBuff;


}
