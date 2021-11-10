#include maps\mp\_utility;
#include common_scripts\utility;

/*script_brushmodel_mover (1 0.25 0.5) ?
script_brushmodel_movers will move and/or rotate to script_struct targets using the move 
parameters defined in script_parameters. Script_structs can target additional script 
structs to create paths and loops. Move parameters can be overridden with 
script_parameters on script structs.
--------------------------------------------------------------------------------

Call level thread maps\mp\_movers::main() before _load::main(); in your level script.
Include rawfile,maps/mp/_movers.gsc in the level csv

---------------------------------------------------------------------------

Valid parameters that can be included in script_parameters:
move_time: Time to move to target
accel_time: Time spent accelerating. accel_time+decel_time must be less then move_time.
decel_time: Time spent decelerating. accel_time+decel_time must be less then move_time.

move_speed: Move speed of the mover. Overrides move_time.
accel_frac: The faction of the total move time spent accelerating [0.0 to 1.0]
decel_frac: The faction of the total move time spent decelerating [0.0 to 1.0]

delay_time: Time the mover will wait before moving to the next position
wait_time: Time the mover will wait after reaching to it's position

delay_till: Wait till this level notify before moving to the next position
wait_till: Wait till this level notify after reaching position

usable: Sets the mover to usable, used in combination with delay_till_trigger
delay_till_trigger:  Will not move till target till mover receives "trigger" notify

solid: Set the brush to solid or or not

script_params: Allows parameters to be defined/added through script. Use
maps\mp\_movers::script_mover_add_parameters("example_set", "move_speed=5;accel_frac=.1")
in the level script to create a named set of parameters. The named parameters can be 
included by setting script_params=name_of_set

--------------------------------------------------------------------------------

Advanced Stuff:
-To set the "angles" of a mover have the mover target a script_struct with angles
set and script_noteworthy=origin. This helps when rotating to angles on targeted structs
-Script_models can be linked to the mover by having the mover target them and setting
script_notewothy=link
-Movers can target other movers. A mover will send "trigger" to its targeted movers when
it started moving. Targeted movers should have delay_till_trigger.
-Script_structs can also target movers and will trigger all targeted movers when a mover
arrives at the script_struct
-Move parameters can be randomized with this syntax: <param_name>=<min_value>,<max_value>;
-Move parameters can be set back to default with this syntax: <param_name>=default
-Script_struct 'A' can target script_struct 'B' with script_noteworthy=level_notify. When a
mover is moving to 'A' it will send a level notify when its path crosses 'B'. The level
notify is set by script_parameters on 'B'
-If a mover targets a trigger with script_noteworthy=use_trigger_link or 
script_noteworthy=use_trigger that trigger will trigger the mover when triggered. use_trigger_link
will link the trigger to the mover and use_trigger will not.
-Entities targeted by the mover or mover goals can modified. The targeted entity needs script_noteworthy
set to <action_name>_on_<notify>. Example script_noteworthy=show_on_arrive
	Notifies:
		"arrive": Fires action when mover arrives at a goal
		"depart": Fires action when mover leaves a position
	Actions:
		"delete": Deletes the entity
		"hide": Hides the entity
		"show": Shows the entity (hides entity on map start)
		"triggerhide": Hides the entity by placing it under the world
		"triggershow": Shows the entity by moving it into the world (ent is moved under the world at startup)
		 

-----------------------------------------------------------------

default:"script_parameters" "move_time=5;accel_time=0;decel_time=0"
*/

/*script_model_mover (1 0.25 0.5) (-16 -16 -16) (16 16 16)
script_model_movers will move and/or rotate to script_struct targets using the move 
parameters defined in script_parameters. Script_structs can target additional script 
structs to create paths and loops. Move parameters can be overridden with 
script_parameters on script structs.
--------------------------------------------------------------------------------

Call level thread maps\mp\_movers::main() before _load::main(); in your level script.
Include rawfile,maps/mp/_movers.gsc in the level csv

---------------------------------------------------------------------------

Valid parameters that can be included in script_parameters:
move_time: Time to move to target
accel_time: Time spent accelerating. accel_time+decel_time must be less then move_time.
decel_time: Time spent decelerating. accel_time+decel_time must be less then move_time.

move_speed: Move speed of the mover. Overrides move_time.
accel_frac: The faction of the total move time spent accelerating [0.0 to 1.0]
decel_frac: The faction of the total move time spent decelerating [0.0 to 1.0]

delay_time: Time the mover will wait before moving to the next position
wait_time: Time the mover will wait after reaching to it's position

delay_till: Wait till this level notify before moving to the next position
wait_till: Wait till this level notify after reaching position

usable: Sets the mover to usable, used in combination with delay_till_trigger
delay_till_trigger:  Will not move till target till mover receives "trigger" notify

script_params: Allows parameters to be defined/added through script. Use
maps\mp\_movers::script_mover_add_parameters("example_set", "move_speed=5;accel_frac=.1")
in the level script to create a named set of parameters. The named parameters can be 
included by setting script_params=name_of_set

--------------------------------------------------------------------------------

Advanced Stuff:
-To set the "angles" of a mover have the mover target a script_struct with angles
set and script_noteworthy=origin. This helps when rotating to angles on targeted structs
-Script_models can be linked to the mover by having the mover target them and setting
script_notewothy=link
-Movers can target other movers. A mover will send "trigger" to its targeted movers when
it started moving. Targeted movers should have delay_till_trigger.
-Script_structs can also target movers and will trigger all targeted movers when a mover
arrives at the script_struct
-Move parameters can be randomized with this syntax: <param_name>=<min_value>,<max_value>;
-Move parameters can be set back to default with this syntax: <param_name>=default
-Script_struct 'A' can target script_struct 'B' with script_noteworthy=level_notify. When a
mover is moving to 'A' it will send a level notify when its path crosses 'B'. The level
notify is set by script_parameters on 'B'
-If a mover targets a trigger with script_noteworthy=use_trigger_link or 
script_noteworthy=use_trigger that trigger will trigger the mover when triggered. use_trigger_link
will link the trigger to the mover and use_trigger will not.
-Entities targeted by the mover or mover goals can modified. The targeted entity needs script_noteworthy
set to <action_name>_on_<notify>. Example script_noteworthy=show_on_arrive
	Notifies:
		"arrive": Fires action when mover arrives at a goal
		"depart": Fires action when mover leaves a position
	Actions:
		"delete": Deletes the entity
		"hide": Hides the entity
		"show": Shows the entity (hides entity on map start)
		"triggerhide": Hides the entity by placing it under the world
		"triggershow": Shows the entity by moving it into the world (ent is moved under the world at startup)
		
-----------------------------------------------------------------

default:"script_parameters" "move_time=5;accel_time=0;decel_time=0"
*/

///////
// Movers
///////
main()
{
	if( getDvar( "r_reflectionProbeGenerate" ) == "1" )
		return;
	
	level.script_mover_defaults = [];
	level.script_mover_defaults["move_time"] 	= 5;
	level.script_mover_defaults["accel_time"] 	= 0;
	level.script_mover_defaults["decel_time"] 	= 0;
	level.script_mover_defaults["wait_time"] 	= 0;
	level.script_mover_defaults["delay_time"] 	= 0;
	level.script_mover_defaults["usable"] 		= 0;
	level.script_mover_defaults["hintstring"] = "activate";
	
	script_mover_add_hintString("activate", &"MP_ACTIVATE_MOVER");
	
	script_mover_add_parameters("none", "");
	
	level.script_mover_named_goals = [];
	
	waitframe();
	
	movers = [];
	classnames = script_mover_classnames();
	foreach(class in classnames)
	{
		movers = array_combine(movers, GetEntArray(class, "classname"));
	}
	array_thread(movers, ::script_mover_int);
}

script_mover_classnames()
{
	return ["script_model_mover", "script_brushmodel_mover"];
}

script_mover_is_script_mover()
{
	if(IsDefined(self.script_mover))
		return self.script_mover;
	
	classnames = script_mover_classnames();
	foreach(class in classnames)
	{
		if(self.classname == class)
		{
			self.script_mover = true;
			return true;
		}
	}
	
	return false;
}

script_mover_add_hintString(name, hintString)
{
	if(!IsDefined(level.script_mover_hintstrings))	
		level.script_mover_hintstrings = [];
	
	level.script_mover_hintstrings[name] = hintString;
	
}

script_mover_add_parameters(name, parameters)
{
	if(!IsDefined(level.script_mover_parameters))
		level.script_mover_parameters = [];
	level.script_mover_parameters[name] = parameters;
}

script_mover_int()
{
	if(!IsDefined(self.target))
		return;
	
	self.script_mover = true;
	self.moving = false;
	
	self.origin_ent = self;
	
	self.use_triggers = [];
	self.linked_ents = [];

	structs = GetStructArray(self.target, "targetname");
	
	
	foreach(target in structs)
	{
		if(!IsDefined(target.script_noteworthy))
			continue;
		
		switch(target.script_noteworthy)
		{
			case "origin":
				if(!IsDefined(target.angles))
					target.angles = (0,0,0);
				self.origin_ent = spawn("script_model", target.origin);
				self.origin_ent.angles = target.angles;
				self.origin_ent SetModel("tag_origin");
				self.origin_ent LinkTo(self);
				break;
			default:
				break;
		}
	}
	
	ents = GetEntArray(self.target, "targetname");
	foreach(target in ents)
	{
		if(!IsDefined(target.script_noteworthy))
			continue;
		
		switch(target.script_noteworthy)
		{
			case "use_trigger_link":
				target EnableLinkTo();
				target LinkTo(self);
				//Fallthrough
			case "use_trigger":
				target script_mover_parse_targets();
				self thread script_mover_use_trigger(target);
				self.use_triggers[self.use_triggers.size] = target;
				break;
			case "link":
				target LinkTo(self);
				self.linked_ents[self.linked_ents.size] = target;
				break;
			default:
				break;
		}
	}

	self thread script_mover_parse_targets();
	self thread script_mover_init_move_parameters();
	self thread script_mover_save_default_move_parameters();
	self thread script_mover_apply_move_parameters(self);
	self thread script_mover_move_to_target();
	
	foreach(trigger in self.use_triggers)
	{
		self script_mover_set_usable(trigger, true);
	}
}

script_mover_use_trigger(trigger)
{
	self endon("death");
	while(1)
	{
		trigger waittill("trigger");
		
		if(trigger.goals.size>0)
		{
			self notify("new_path");
			self thread script_mover_move_to_target(trigger);
		}
		else
		{
			self notify("trigger");
		}
	}
}

script_mover_move_to_named_goal(goal_name)
{
	if(IsDefined(level.script_mover_named_goals[goal_name]))
	{
		self notify("new_path");
		self.goals = [level.script_mover_named_goals[goal_name]];
		self thread script_mover_move_to_target();
	}
}

anglesClamp180(angles)
{
	return (AngleClamp180(angles[0]),AngleClamp180(angles[1]),AngleClamp180(angles[2]));
}

script_mover_parse_targets()
{
	if(IsDefined(self.parsed) && self.parsed)
		return;
	
	self.parsed = true;
	
	self.goals = [];
	self.movers = [];
	self.level_notify = [];
	
	structs = [];
	ents = [];
	if(IsDefined(self.target))
	{
		structs = GetStructArray(self.target, "targetname");
		ents = GetEntArray(self.target, "targetname");
	}
	for(i=0;i<structs.size;i++)
	{
		target = structs[i];
		if(!IsDefined(target.script_noteworthy))
			target.script_noteworthy = "goal"; //Assume goal this is a mover goal pos if not set
		
		switch(target.script_noteworthy)
		{
			case "ignore":
				if(IsDefined(target.target))
				{
					add_structs = GetStructArray(target.target, "targetname");
					foreach(add in add_structs)
					{
						structs[structs.size] = add;
					}
				}
				break;
			case "goal":
				target script_mover_init_move_parameters();
				target script_mover_parse_targets();
				self.goals[self.goals.size] = target;
				if(IsDefined(target.params["name"]))
				{
					level.script_mover_named_goals[target.params["name"]] = target;
				}
				break;
			case "level_notify":
				if(IsDefined(target.script_parameters))
				{
					self.level_notify[self.level_notify.size] = target;
				}
				break;
			default:
				break;
		}
	}
	
	foreach(ent in ents)
	{
		if(ent script_mover_is_script_mover())
		{
			self.movers[self.movers.size] = ent;
			continue;
		}
		
		if(!IsDefined(ent.script_noteworthy))
			continue;
		
		toks = StrTok(ent.script_noteworthy, "_");
		if(toks.size!=3 || toks[1] != "on")
			continue;
		
		//toks[2] arrive or depart 
		switch(toks[0])
		{
			case "delete":
				self thread script_mover_call_func_on_notify(ent, ::delete, toks[2]);
				break;
			case "hide":
				self thread script_mover_call_func_on_notify(ent, ::Hide, toks[2]);
				break;
			case "show":
				ent Hide();
				self thread script_mover_call_func_on_notify(ent, ::Show, toks[2]);
				break;
			case "triggerhide":
			case "triggerHide":
				self thread script_mover_func_on_notify(ent, ::trigger_off, toks[2]);
				break;
			case "triggershow":
			case "triggerShow":
				ent trigger_off();
				self thread script_mover_func_on_notify(ent, ::trigger_on, toks[2]);
				break;
			default:
				break;
		}
	}
}

script_mover_func_on_notify(ent, func, note)
{
	self endon("death");
	ent endon("death");
	
	while(1)
	{
		self waittill(note);
		ent [[func]]();
	}
}

script_mover_call_func_on_notify(ent, func, note)
{
	self endon("death");
	ent endon("death");
	
	while(1)
	{
		self waittill(note);
		ent call [[func]]();
	}
}

script_mover_trigger_on()
{
	self trigger_on();
}

script_mover_move_to_target(current)
{
	self endon("death");
	self endon("new_path");
	
	if(!IsDefined(current))
		current = self;
	
	while(current.goals.size!=0)
	{
		goal = random(current.goals);
		
		mover = self;
		
		mover script_mover_apply_move_parameters( goal );
		
		if(IsDefined(mover.params["delay_till"]))
			level waittill(mover.params["delay_till"]);
		
		if(IsDefined(mover.params["delay_till_trigger"]) && mover.params["delay_till_trigger"])
			self waittill("trigger");
		
		if(mover.params["delay_time"]>0)
			wait mover.params["delay_time"];
		
		move_time = mover.params["move_time"];
		accel_time = mover.params["accel_time"];
		decel_time = mover.params["decel_time"];
		
		is_moveTo = false;
		is_rotateTo = false;
		
		trans = TransformMove(goal.origin, goal.angles, self.origin_ent.origin, self.origin_ent.angles, self.origin, self.angles);
		if(mover.origin != goal.origin)
		{
			if(IsDefined(mover.params["move_speed"]))
			{
				dist = distance(mover.origin, goal.origin);
				move_time = dist/mover.params["move_speed"];
			}
			
			if(IsDefined(mover.params["accel_frac"]))
			{
				accel_time = mover.params["accel_frac"] * move_time;
			}
			
			if(IsDefined(mover.params["decel_frac"]))
			{
				decel_time = mover.params["decel_frac"] * move_time;
			}
			
			mover MoveTo(trans["origin"], move_time, accel_time, decel_time );
			
			foreach(note in goal.level_notify)
			{
				self thread script_mover_run_notify(note.origin, note.script_parameters, self.origin, goal.origin);
			}
			
			is_moveTo = true;
		}
		
		if(anglesClamp180(trans["angles"]) != anglesClamp180(mover.angles))
		{
			mover RotateTo(trans["angles"], move_time, accel_time, decel_time);
			is_rotateTo = true;
		}
		
		//Trigger movers targeted my the mover
		foreach ( targeted_mover in mover.movers )
		{
			targeted_mover notify("trigger");
		}
		
		current notify("depart");
		
		mover script_mover_allow_usable(false);
		
		self.moving = true;
		
		if(IsDefined(mover.params["move_time_offset"]) && (mover.params["move_time_offset"]+move_time)>0)
		{
			wait mover.params["move_time_offset"]+move_time;
		}
		else if(is_moveTo)
		{
			self waittill("movedone");
		}
		else if(is_rotateTo)
		{
			self waittill("rotatedone");
		}
		else
		{
			wait move_time;
		}
		
		self.moving = false;
		self notify("move_end");
		goal notify("arrive");
		
		if(IsDefined(mover.params["solid"]))
		{
			if(mover.params["solid"])
				mover solid();
			else
				mover notsolid();
		}
		
		//Trigger movers targeted my the goal
		foreach ( targeted_mover in goal.movers )
		{
			targeted_mover notify("trigger");
		}
		
		if(IsDefined(mover.params["wait_till"]))
			level waittill(mover.params["wait_till"]);
			
		if(mover.params["wait_time"]>0)
			wait mover.params["wait_time"];
		
		mover script_mover_allow_usable(true);
		
		current = goal;
	}
}

script_mover_run_notify(notify_origin, level_notify, start, end)
{
	self endon("move_end");
	
	mover = self;
	move_dir = VectorNormalize(end-start);
	while(1)
	{
		notify_dir = VectorNormalize(notify_origin - mover.origin);
		if(VectorDot(move_dir,notify_dir)<=0)
			break;
		wait .05;
	}
	
	level notify(level_notify);
}
script_mover_init_move_parameters()
{
	self.params = [];
	
	if(!IsDefined(self.angles))
		self.angles = (0,0,0);
	
	self.angles = anglesClamp180(self.angles);
	
	script_mover_parse_move_parameters(self.script_parameters);
}
script_mover_parse_move_parameters(parameters)
{
	if(!IsDefined(parameters))
		parameters = "";
	
	params = StrTok(parameters, ";");
	foreach(param in params)
	{
		toks = strtok(param,"=");
		if(toks.size!=2)
			continue;
		
		if(toks[1]=="undefined" || toks[1]=="default")
		{
			//If default exist it will be set in script_mover_set_defaults
			self.params[toks[0]] = undefined;
			continue;
		}
		
		switch(toks[0])
		{
			case "move_speed":
			case "accel_frac":
			case "decel_frac":
			case "move_time":
			case "accel_time":
			case "decel_time":
			case "wait_time":
			case "delay_time":
			case "move_time_offset":
				self.params[toks[0]] = script_mover_parse_range(toks[1]);
				break;
			case "wait_till":
			case "delay_till":
			case "name":
			case "hintstring":
				self.params[toks[0]] = toks[1];
				break;
			case "usable":
			case "delay_till_trigger":
			case "solid":
				self.params[toks[0]] = int(toks[1]);
				break;
			case "script_params":
				param_name = toks[1];
				additional_params = level.script_mover_parameters[param_name];
				if(IsDefined(additional_params))
				{
					script_mover_parse_move_parameters(additional_params);
				}
				break;
			default:
				break;
		}
	}
}

script_mover_parse_range(str)
{
	value = 0;
	
	toks = strtok(str,",");
	if(toks.size==1)
	{
		value = float(toks[0]);
	}
	else if(toks.size==2)
	{
		minValue = float(toks[0]);
		maxValue = float(toks[1]);
		
		if(minValue>=maxValue)
		{
			value = minValue;
		}
		else
		{
			value = RandomFloatRange(minValue,maxValue);
		}
	}
	
	return value;
}

//to = self
script_mover_apply_move_parameters(from)
{
	foreach(key, value in from.params)
	{
		script_mover_set_param(key, value);
	}
	
	script_mover_set_defaults();
}

script_mover_set_param(param_name, value)
{
	if(!IsDefined(param_name))
		return;
	
	if(param_name=="usable" && IsDefined(value))
	{
		self script_mover_set_usable(self, value);
	}
	
	self.params[param_name] = value;
}

script_mover_allow_usable(usable)
{
	if(self.params["usable"])
	{
		self script_mover_set_usable(self, usable);
	}
	foreach(trigger in self.use_triggers)
	{
		self script_mover_set_usable(trigger, usable);
	}
}

script_mover_set_usable(use_ent,usable)
{
	if(usable)
	{
		use_ent MakeUsable();
		use_ent SetCursorHint("HINT_ACTIVATE");
		use_ent SetHintString(level.script_mover_hintstrings[self.params["hintstring"]]);
	}
	else
	{
		use_ent MakeUnusable();
	}
}

script_mover_save_default_move_parameters()
{
	self.params_default = [];
	
	foreach(key, value in self.params)
	{
		self.params_default[key] = value;
	}
}

//Values in script_mover_defaults are assumed to always be defined
//this checks that they are.
script_mover_set_defaults()
{
	foreach(key, value in level.script_mover_defaults)
	{
		if(!IsDefined(self.params[key]))
			script_mover_set_param(key, value);
	}
	
	if(IsDefined(self.params_default))
	{
		foreach(key, value in self.params_default)
		{
			if(!IsDefined(self.params[key]))
				script_mover_set_param(key, value);
		}
	}	
}

init()
{
	level thread script_mover_connect_watch();
	level thread script_mover_agent_spawn_watch();
}

script_mover_connect_watch()
{
	while ( 1 )
	{
		level waittill( "connected", player );
		player thread player_unresolved_collision_watch();
	}
}

script_mover_agent_spawn_watch()
{
	while ( 1 )
	{
		level waittill( "spawned_agent", agent );
		agent thread player_unresolved_collision_watch();
	}
}

player_unresolved_collision_watch()
{
	self endon("disconnect");
	if ( IsAgent( self ) )
	{
		self endon("death");
	}
		
	self.unresolved_collision_count = 0;
	while(1)
	{
		self waittill( "unresolved_collision", mover );
		self.unresolved_collision_count++;
		self thread clear_unresolved_collision_count_next_frame();
		
		unresolved_collision_notify_min = 3;
		if(IsDefined(mover) && IsDefined(mover.unresolved_collision_notify_min))
			unresolved_collision_notify_min = mover.unresolved_collision_notify_min;
		
		if(self.unresolved_collision_count>=unresolved_collision_notify_min)
		{
			if(IsDefined(mover))
			{
				if(IsDefined( mover.unresolved_collision_func ))
				{
					mover [[mover.unresolved_collision_func]](self);
				}
				else if(IsDefined(mover.unresolved_collision_kill) && mover.unresolved_collision_kill)
				{
					mover unresolved_collision_owner_damage(self);
				}
				else
				{
					mover unresolved_collision_nearest_node(self);
				}
			}
			else
			{
				unresolved_collision_nearest_node(self);
			}
			self.unresolved_collision_count = 0;
		}
	}
}

clear_unresolved_collision_count_next_frame()
{
	self endon("unresolved_collision");
	waitframe();
	if(IsDefined(self))
		self.unresolved_collision_count = 0;
}

unresolved_collision_owner_damage(player)
{
	inflictor = self;
	
	if(!IsDefined(inflictor.owner))
	{
		player maps\mp\_movers::mover_suicide();
		return;
	}
	
	canInflictorOwnerDamagePlayer = false;
	
	if( level.teambased )
	{
		if( IsDefined( inflictor.owner.team ) && inflictor.owner.team != player.team )
			canInflictorOwnerDamagePlayer = true;
	}
	else
	{
		if(player != inflictor.owner)
			canInflictorOwnerDamagePlayer = true;
	}
	
	if(!canInflictorOwnerDamagePlayer)
	{
		player maps\mp\_movers::mover_suicide();
		return;
	}
	
	damage_ammount = 1000; //Kill
	if(IsDefined(inflictor.unresolved_collision_damage))
		damage_ammount = inflictor.unresolved_collision_damage;
	
	
	player DoDamage( damage_ammount, inflictor.origin, inflictor.owner, inflictor, "MOD_CRUSH" );
}

unresolved_collision_nearest_node(player, bAllowSuicide)
{
	if ( IsDefined( level.override_unresolved_collision ) )
	{
		self [[level.override_unresolved_collision]]( player, bAllowSuicide );
		return;
	}

	nodes = self.unresolved_collision_nodes;
	if(IsDefined(nodes))
	{
		nodes = SortByDistance(nodes, player.origin);
	}
	else
	{
		nodes = GetNodesInRadius( player.origin, 300, 0, 200 ); //Sorted version sorts by 2d dist, we need 3d
		nodes = SortByDistance(nodes, player.origin);
	}
		
	avoid_telefrag_offset = (0,0,-100);
	
	player CancelMantle();
	player DontInterpolate();
	player SetOrigin(player.origin + avoid_telefrag_offset);
	
	for(i=0; i<nodes.size; i++)
	{
		check_node = nodes[i];
//		if( check_node NodeIsDisconnected())
//			continue;
		
		org = check_node.origin;
		if(!CanSpawn(org))
			continue;
		
		if(PositionWouldTelefrag(org))
			continue;
		
		if(player GetStance() == "prone")
			player Setstance("crouch");
		
		player SetOrigin( org );
		return;
	}
	
	player SetOrigin(player.origin - avoid_telefrag_offset);
	
	if( !IsDefined(bAllowSuicide) )
		bAllowSuicide = true;
	
	// no nodes found, fall back on suicide
	if( bAllowSuicide )
	{
		player mover_suicide();
	}
}

unresolved_collision_void(player)
{
	
}

mover_suicide()
{
	if( IsDefined(level.isHorde) && !IsAgent( self ) )
	{
		return;
	}
	
	self _suicide();
}

//*******************************************************************
//																	*
//																	*
//*******************************************************************

player_pushed_kill( min_mph ) //self == mover
{
	self endon("death");
	self endon("stop_player_pushed_kill");
	
	while( 1 )
	{
		self waittill( "player_pushed", player, platformMPH );
		if ( isPlayer( player ) || isAgent( player ) )
		{
			mph = Length(platformMPH);
			
			if ( mph >= min_mph )
			{
				self unresolved_collision_owner_damage(player);
			}
		}
	}
}

stop_player_pushed_kill()
{
	self notify("stop_player_pushed_kill");
}

//*******************************************************************
//																	*
//																	*
//*******************************************************************
script_mover_get_top_parent()
{
	topParent = self GetLinkedParent();
	parent = topParent;

	while ( IsDefined( parent ) )
	{
		topParent = parent;
		parent = parent GetLinkedParent();
	}

	return topParent;
}

script_mover_start_use( useEnt )
{	
	// Backup the starting position of the use entity's parent. 
	useParent = useEnt script_mover_get_top_parent();
	if ( IsDefined( useParent ) )
	{
		useParent.startUseOrigin = useParent.origin;
	}

	// Backup the player's mover and backup the start position. 
	self.startUseMover = self GetMovingPlatformParent();
	if ( IsDefined( self.startUseMover ) )
	{
		// Check for the highest parent, else just use the mover as is.
		topParent = self.startUseMover script_mover_get_top_parent();
		if ( IsDefined( topParent ) )
			self.startUseMover = topParent;

		self.startUseMover.startUseOrigin = self.startUseMover.origin;
	}
}

script_mover_has_parent_moved( parent )
{
	if ( !IsDefined( parent ) )
		return false;

	return LengthSquared( parent.origin - parent.startUseOrigin ) > 0.001;
}

script_mover_use_can_link( ent )
{
	if ( !IsPlayer( self ) )
		return true;
	
	if ( !IsDefined( ent ) )
		return false;

	topParent = ent script_mover_get_top_parent();
	playerParent = self.startUseMover;
	
	// If neither parent is defined, we are definitely not moving. 
	if ( !IsDefined( topParent ) && !IsDefined( playerParent ) )
		return true;

	// If both parents exist and they are the same, we can stay linked. 
	if ( IsDefined( topParent ) && IsDefined( playerParent ) && (topParent == playerParent) )
		return true;

	// If a parent has moved and the parents are not the same, we cannot stay linked.
	if ( script_mover_has_parent_moved( topParent ) )
		return false;

	if ( script_mover_has_parent_moved( playerParent ) )
		return false;

	return true;
}

script_mover_link_to_use_object( player )	// self == object
{
	// !!! FOR IW7: Request a function to disable player movement, but allow button input
	// which is what this linking is ultimately trying to achieve
	if ( IsPlayer(player) )
	{
		player maps\mp\_movers::script_mover_start_use( self );
		
		playerMover = player GetMovingPlatformParent();
		linkToObject = undefined;
		
		// the player is a moving platform, link him to that because it doesn't matter what the object is on
		if ( IsDefined( playerMover ) )
		{
			linkToObject = playerMover;
		}
		// the player is on the ground, and so is the object
		else if ( !IsDefined( self script_mover_get_top_parent() ) )
		{
			linkToObject = self;
		}
		// the player is on the ground, but the object is on a mover
		else
		{
			// spawn a dummy entity and link the player to that
			linkToObject = Spawn( "script_model", player.origin );
			linkToObject SetModel( "tag_origin" );
			player.scriptMoverLinkDummy = linkToObject;
			
			// thread off a cleaup function
			player thread sciprt_mover_use_object_wait_for_disconnect( linkToObject );
		}
		
		player PlayerLinkTo( linkToObject );
	}
	else
	{
		// 2014-06-23 wallace: bots currently don't support GetMovingPlatformParent, which should be fixed in IW7
		// as a result, they'll be subject to bug 184158 (getting stuck when trying to use a box on a platform)
		player LinkTo( self );
	}
	player PlayerLinkedOffsetEnable();
}

script_mover_unlink_from_use_object( player )	// self == object
{
	player Unlink();
	
	if ( IsDefined( player.scriptMoverLinkDummy ) )
	{
		player notify( "removeMoverLinkDummy" );
		player.scriptMoverLinkDummy Delete();
		player.scriptMoverLinkDummy = undefined;
	}
}

sciprt_mover_use_object_wait_for_disconnect( linkDummy )
{
	self endon( "removeMoverLinkDummy" );
	
	self waittill_any( "death", "disconnect" );
	
	self.scriptMoverLinkDummy Delete();
	self.scriptMoverLinkDummy = undefined;
}

//*******************************************************************
//																	*
//																	*
//*******************************************************************
notify_moving_platform_invalid()
{
	children = self GetLinkedChildren( false );
	if ( !IsDefined( children ) )
	{
		return;
	}

	foreach ( child in children )
	{
		if( IsDefined(child.no_moving_platfrom_unlink) && child.no_moving_platfrom_unlink )
			continue;
		
		child unlink();
		child notify( "invalid_parent", self );
	}
}

process_moving_platform_death( data, platform )
{
	if(IsDefined(platform) && IsDefined(platform.no_moving_platfrom_death) && platform.no_moving_platfrom_death)
		return; 
	
	if ( IsDefined( data.playDeathFx ) )
	{
		PlayFX( getfx( "airdrop_crate_destroy" ), self.origin );
	}

	if ( IsDefined( data.deathOverrideCallback ) )
	{
		// we should be passing platform as an argument
		data.lastTouchedPlatform = platform;
		self thread [[data.deathOverrideCallback]]( data );
	}
	else 
	{
		self delete();
	}
}

handle_moving_platform_touch( data )
{
	self notify( "handle_moving_platform_touch" );
	self endon( "handle_moving_platform_touch" );

	level endon( "game_ended" );
	self endon( "death" );
	self endon( "stop_handling_moving_platforms" );
	
	// Special endon string.
	if ( IsDefined( data.endonString ) )
	{
		self endon( data.endonString );
	}
	
	while ( 1 )
	{
		self waittill( "touching_platform", platform );

		if ( IsDefined( data.validateAccurateTouching ) && data.validateAccurateTouching )
		{
			if ( !self IsTouching( platform ) )
			{
				wait( 0.05 );
				continue;
			}
		}

		self thread process_moving_platform_death( data, platform );
		break;
	}
}

handle_moving_platform_invalid( data )
{
	self notify( "handle_moving_platform_invalid" );
	self endon( "handle_moving_platform_invalid" );

	level endon( "game_ended" );
	self endon( "death" );
	self endon( "stop_handling_moving_platforms" );
	
	// Special endon string.
	if ( IsDefined( data.endonString ) )
	{
		self endon( data.endonString );
	}
	
	self waittill( "invalid_parent", platform );
	if ( IsDefined( data.invalidParentOverrideCallback ) )
	{
		self thread [[data.invalidParentOverrideCallback]]( data );
	}
	else 
	{
		self thread process_moving_platform_death( data, platform );
	}
}

// data: Spawned struct passed into handler.
// data.linkParent: Parent to link this entity to.
// data.endonString: String that will kill this handler when notified to entity.
// data.playDeathFx: Flag to play a generic death effect.
// data.deathOverrideCallback: Callback that will call instead of the automatic delete (ex. ims_override_death( platform ) ).
// data.invalidParentOverrideCallback: Callback that will call instead of the automatic invalid parent handler.
// data.validateAccurateTouching: If true, performs an extra IsTouching test on the touching platform before processing. 
handle_moving_platforms( data )
{
	self notify( "handle_moving_platforms" );
	self endon( "handle_moving_platforms" );

	level endon( "game_ended" );
	self endon( "death" );
	self endon( "stop_handling_moving_platforms" );

	if ( !IsDefined( data ) )
	{
		data = SpawnStruct();
	}

	// Special endon string.
	if ( IsDefined( data.endonString ) )
	{
		self endon( data.endonString );
	}

	if ( IsDefined( data.linkParent ) )
	{
		parent = self GetLinkedParent();
		if ( !IsDefined( parent ) || parent != data.linkParent)
			self linkto( data.linkParent );
	}

	thread handle_moving_platform_touch( data );
	thread handle_moving_platform_invalid( data );
}

// Force kill this process without using data.endonString.
stop_handling_moving_platforms()
{
	self notify( "stop_handling_moving_platforms" );
}

moving_platform_empty_func( data )
{
	// Don't add anything.
}

//*******************************************************************
//																	*
//																	*
//*******************************************************************
