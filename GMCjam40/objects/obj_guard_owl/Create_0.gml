///@desc enemy init
//Enemy variables

event_inherited();

instance = new smf_instance(global.modOwl);
instance.play("Idle", .2, 1, true);

function draw()
{
	matrix_set(matrix_world,matrix_build(x,y,z,0,0,face,8,8,8));
	instance.draw();
	matrix_set(matrix_world,matrix_build_identity());
}