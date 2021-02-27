///@desc Create objects

instance_create_depth(0,0,0,obj_deferred_control);

var _buff = colmesh_load_obj_to_buffer("XorOwl.obj");
global.buf_owl = vertex_create_buffer_from_buffer(_buff, global.ColMeshFormat);