/// @description
size = 64;
z = size / 2;
var h = size;
var s = sqrt(2);
shape = levelColmesh.addShape(new colmesh_block(colmesh_matrix_build(x, y - h / s, z - h / s, 45, 0, 0, size / 2, size / s, h)));