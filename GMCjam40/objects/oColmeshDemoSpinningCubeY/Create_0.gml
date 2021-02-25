/// @description
size = 64;
z = size / 2;
M = matrix_build(x, y, z, 0, current_time / 50, 0, 1, 1, 1);
shape = levelColmesh.addDynamic(new colmesh_cube(0, 0, 0, size), M);