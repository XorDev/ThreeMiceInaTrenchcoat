/// @description smf__read_obj_face(faceList, str)
/// @param faceList
/// @param str
function _mbuff_read_obj_face(argument0, argument1) {
	var i, j;
	var faceList = argument0;
	var str = argument1;
	str = string_delete(str, 1, string_pos(" ", str))
	if (string_char_at(str, string_length(str)) == " ")
	{
		//Make sure the string doesn't end with an empty space
		str = string_copy(str, 0, string_length(str) - 1);
	}
	var triNum = string_count(" ", str);
	var vertString = array_create(triNum + 1);
	for (i = 0; i < triNum; i ++)
	{
		//Add vertices in a triangle fan
		vertString[i] = string_copy(str, 1, string_pos(" ", str));
		str = string_delete(str, 1, string_pos(" ", str));
	}
	vertString[i--] = str;
	while i--
	{
		for (j = 2; j >= 0; j --)
		{
			str = vertString[(i + j) * (j > 0)];
			var v = 1, n = 1, t = 1;
			//If the vertex contains a position, texture coordinate and normal
			if string_count("/", str) == 2 and string_count("//", str) == 0{
				v = real(string_copy(str, 1, string_pos("/", str) - 1));
				str = string_delete(str, 1, string_pos("/", str));
				t = real(string_copy(str, 1, string_pos("/", str) - 1));
				n = real(string_delete(str, 1, string_pos("/", str)));}
			//If the vertex contains a position and a texture coordinate
			else if string_count("/", str) == 1{
				v = real(string_copy(str, 1, string_pos("/", str) - 1));
				t = real(string_delete(str, 1, string_pos("/", str)));}
			//If the vertex only contains a position
			else if (string_count("/", str) == 0){
				v = real(str);}
			//If the vertex contains a position and normal
			else if string_count("//", str) == 1{
				str = string_replace(str, "//", "/");
				v = real(string_copy(str, 1, string_pos("/", str) - 1));
				n = real(string_delete(str, 1, string_pos("/", str)));}
			if v < 0{v = -v;}
			if n < 0{n = -n;}
			if t < 0{t = -t;}
			ds_list_add(faceList, [v-1, n-1, t-1]);
		}
	}


}
