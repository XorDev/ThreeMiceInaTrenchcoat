///@desc

gpu_set_tex_filter(1);

if lvlMessage && !global.fade
{
	draw_primitive_begin(pr_trianglestrip);
	draw_vertex_color(0,0,0,0.6);
	draw_vertex_color(global.screen_w,0,0,0.6);
	draw_vertex_color(0,.4*global.screen_h,0,0.3);
	draw_vertex_color(global.screen_w,.4*global.screen_h,0,0.3);
	draw_vertex_color(0,.6*global.screen_h,0,0);
	draw_vertex_color(global.screen_w,.6*global.screen_h,0,0);
	draw_primitive_end();

	var _t1,_t2;
	_t1 = "";
	_t2 = "";
	switch(room)
	{
		case rmLevel1:
		_t1 = "This kingdom has been ruled by the evil Pug King for far too long. It's time we mice take it back!";
		_t2 = "Watch out for pug guards; they may try to catch you and imprison you.\n[X] to close"
		break;
		case rmLevel2:
		_t1 = "There's a key around here somewhere. You're going to need it to free any mice you find in cages."
		_t2 = "Touching cages while you have the key will free mice that may be trapped inside. \n[X] to close"
		break;
		case rmLevel3:
		_t1 = "Beware the all-seeing owls!"
		_t2 = "Watch out for owl guards; they have a wide field of view.\n[X] to close"
		break;
		case rmLevel4:
		_t1 = "Find the trench coat. Maybe it will fool them!"
		_t2 = "As long as you have three mice you may activate the trench coat disguise by pressing [E]. \n[X] to close"
		break;
		case rmLevel5:
		_t1 = "That is one big party! Sneak your way through the crowd and find the bone."
		_t2 = "Make sure you stay on the move, or else they may become suspicious.\n[X] to close"
		break;
		case rmLevel6:
		_t1 = "You are nearing the king's private rooms, so be on guard!"
		_t2 = "You may use the bone to distract the king. Press [B] to throw it.\n[X] to close"
		break;
	}

	draw_set_font(fnt_menu_smaller);
	var _h = string_height_ext(_t1,48,global.screen_w*.9);
	draw_set_color($AAAAAA);
	draw_text_ext(.5*global.screen_w,.1*global.screen_h,_t1,48,global.screen_w*.9);
	draw_set_color($FFFFFF);
	
	var _o = 4*cos(current_time/400);
	draw_text_ext_transformed(.5*global.screen_w,.2*global.screen_h+_h+_o,_t2,48,global.screen_w*.9,.8,.8,0);

	global.messageFade *= .99;
	var _fade = global.messageFade;

	draw_set_alpha(_fade);

	draw_set_font(fnt_menu_smaller);
	draw_set_color($FFFFFF);
	draw_text_transformed(.5*global.screen_w,.1*(0.5+sqrt(_fade))*global.screen_h,global.message,.8,.8,0);
	draw_set_alpha(1);
	gpu_set_tex_filter(0);
}