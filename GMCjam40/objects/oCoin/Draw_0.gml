/// @description
var angle = current_time / 300 + x + y + z;
var dx = cos(angle);
var dy = sin(angle);
var dz = 0;
colmesh_debug_draw_cylinder(x, y, z, dx, dy, dz, radius, radius / 5, c_yellow);