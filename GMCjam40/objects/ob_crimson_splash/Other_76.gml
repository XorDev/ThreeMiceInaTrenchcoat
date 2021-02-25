if (event_data[? "event_type"] == "sequence event") {
	switch (event_data[? "message"]) {
	    case "splash_end":
	        if (room_next(room) != -1){
				room_goto_next();
			}
	    break;
	}
}