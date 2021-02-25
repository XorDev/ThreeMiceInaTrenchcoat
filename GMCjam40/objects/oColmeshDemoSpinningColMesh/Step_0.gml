/// @description
M = matrix_build(x, y, z, 15 * cos(current_time / 1000), 15 * cos(current_time / 1600), current_time / 50, 1, 1, 1);
shape.setMatrix(M, true);

var _M = matrix_build(30 * cos(current_time / 600), 0, 30 * cos(current_time / 440), 0, 0, current_time / 10, 1, 1, 1);
cube.setMatrix(_M, true);