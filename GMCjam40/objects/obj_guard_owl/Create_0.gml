///@desc enemy init
//Enemy variables

event_inherited();

instance = new smf_instance(global.modOwl);
instance.play("Idle", .2, 1, true);

function draw()
{
	var _sway = dcos(sway*3)*speed*3;
	matrix_set(matrix_world,matrix_build(x,y,z,_sway,0,face,6,6,6));
	instance.draw();
	matrix_set(matrix_world,matrix_build_identity());
}