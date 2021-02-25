/// @description
xsize = 128;
ysize = 32;
zsize = 10;
z = 0;
M = matrix_build(x, y, z, 0, 0, 0, 1, 1, 1);
shape = levelColmesh.addDynamic(new colmesh_block(matrix_build(0, 0, 0, 0, 0, 0, xsize, ysize, zsize)), M);