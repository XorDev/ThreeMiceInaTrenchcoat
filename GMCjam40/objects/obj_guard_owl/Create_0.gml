///@desc enemy init
//Enemy variables

event_inherited();

scale = 8;
snd_attack = snd_owl_attack;
snd_huh = snd_owl_huh;

instance = new smf_instance(global.modOwl);
instance.play("Idle", .2, 1, true);