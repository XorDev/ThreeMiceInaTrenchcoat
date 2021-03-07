/// @description

//Draw mice
if (global.iframes > 0)
{
	if (global.iframes div 5) mod 2 == 0
	{
		exit;
	}
}
deferred_set(1);
for (var i = 0; i < array_length(global.mouseArray); i ++)
{
	global.mouseArray[i].draw();
	
	if (global.trenchcoat && trenchcoatTimer <= 0)
	{
		break;
	}
}
deferred_reset();
matrix_set(matrix_world, matrix_build_identity());

//Debug draw colmesh
/*
surface_set_target(global.surf_dif);
matrix_set(matrix_world, matrix_build_identity());
camera_apply(view_camera[0]);
levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, 0, 0, 1, radius, 0));
surface_reset_target();