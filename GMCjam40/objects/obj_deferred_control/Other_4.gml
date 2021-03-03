/// @description

deferred_init();

if !variable_global_exists("gsettings") global.gsettings = 2;

var _list,_res;
_list = [256,1024,2048,8192];
_res = _list[global.gsettings]
light_init(_res);