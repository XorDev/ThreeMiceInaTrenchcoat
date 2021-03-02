///@desc Show message

window_set_cursor(cr_none);
var _level = 0;
switch(room)
{
	case rmLevel1:
	_level = 1;
	break;
	
	case rmLevel2:
	_level = 2;
	break;
	
	case rmLevel3:
	_level = 3;
	break;
	
	case rmLevel4:
	_level = 4;
	break;
	
	case rmLevel5:
	_level = 5;
	break;
	
	case rmLevel6:
	_level = 6;
	break;
}

if (_level>global.level)
{
	lvlMessage = true;
	global.level = _level;
}