///@desc Go to level 1

var _level = [rmLevel1,rmLevel1,rmLevel2,rmLevel3,rmLevel4,rmLevel5,rmLevel6];

global.climbdir = 1;
room_goto(_level[global.level]);