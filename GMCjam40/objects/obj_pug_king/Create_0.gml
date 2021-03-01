///@desc king init
event_inherited();

face = 0;

instance = new smf_instance(global.modPugKing);
var animSpd = instance.getAnimSpeed("Idle");

instance.play("Idle", animSpd, 1, 1);

function draw()
{
	matrix_set(matrix_world,matrix_build(x,y,z,0,0,face,6,6,6));
	instance.draw();
	
	matrix_set(matrix_world,matrix_build_identity());
}