///@desc enemy init
event_inherited();

model = choose(global.modPugGuest, global.modOwl);
dance = choose("Dance1", "Dance2", "Dance3");
instance = new smf_instance(model);
angle = 180 + random(180);

animSpd = .018;
if (model == global.modOwl && dance == "Dance1")
{
	instance.play(dance, animSpd / 2, 1, true);
}
else
{
	instance.play(dance, animSpd, 1, true);
}
instance.fast_sampling(true);
M = matrix_build(x, y, z, 0, 0, angle, 6, 6, 6);