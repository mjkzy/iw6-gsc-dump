#include common_scripts\utility;
#include maps\mp\_utility;

#using_animtree( "animated_props_mp_descent" );

CONST_EARTHQUAKE_RANGE = 5000;
CONST_DEFAULT_PREFALL_TIME = 1.5;
CONST_DEFAULT_FALL_TIME = 3.0;
CONST_DEFAULT_SETTLE_TIME = 1.5;
CONST_DEFAULT_MAX_ROLL = 6;
CONST_DEFAULT_MIN_ROLL = 4;
CONST_DEFAULT_MAX_PITCH = 3;
CONST_DEFAULT_MIN_PITCH = 2;
CONST_FALL_EXPLODER_ID = 1;
CONST_GLASS_BUILDING_EXPLODER_ID = 3;
CONST_CONCRETE_FACADE_NAME = "concrete_building";
CONST_CONCRETE_FACADE_RUIN_MODEL = "desc_building_destroyed_02";
CONST_GLASS_FACADE_NAME = "facade_glass_";

CONST_COLUMN_FALL_ANIM = "mp_descent_column_collapsing";
CONST_COLUMN_FALL_SFX = "scn_dest_collapse_fall";
CONST_COLUMN_IMPACT_SFX = "scn_dest_collapse_impact";
CONST_COLUMN_IMPACT_VFX_EXPLODER_ID = 23;
CONST_COLUMN_IMPACT_OFFSET = 180;	// units below origin
CONST_COLUMN_IMPACT_DELAY = 3.5; // in seconds
CONST_COLUMN_DAMAGE_RADIUS = 192;
CONST_COLUMN_DAMAGE = 500;

CONST_SNIPER_DUCT_ANGLE = -90;
CONST_SNIPER_DUCT_TIME = 1;

CONST_EVENT_TRIGGER_FALL_DELAY_MIN = 3;	// in seconds
CONST_EVENT_TRIGGER_FALL_DELAY_MAX = 6;	// in seconds

main()
{
	maps\mp\mp_descent_new_precache::main();
	maps\createart\mp_descent_new_art::main();
	maps\mp\mp_descent_new_fx::main();
	
	maps\mp\_load::main();
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_descent_new" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	setdvar_cg_ng( "r_specularColorScale", 2.5				  	, 2.5 );
	
	if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.5" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".15" );
	}
	else if( level.xenon )
    {
        SetDvar( "sm_sunShadowScale", "0.8" );
		SetDvar( "sm_sunsamplesizenear", ".25" );
    }
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "elite";
	
//	level thread fall_objects();
//	level thread tilt_objects();
//	level thread hang_objects();
//	level thread gap_objects();
//	level thread world_tilt();
		
	level thread watersheet_trig_setup();
	
	/#
	thread debugDescent();
	#/	
	
	// level thread doubleDoorCreate( "door1" );
	
	// animated props for fall events
	animLength = GetAnimLength( %mp_descent_light01_fall );
	animateScriptableProps( "animated_model_descent_light01", animLength );
	animLength = GetAnimLength( %mp_descent_light02_fall );
	animateScriptableProps( "animated_model_descent_light02", animLength );
	animLength = GetAnimLength( %mp_descent_light03_fall );
	animateScriptableProps( "animated_model_descent_light03", animLength );
	animLength = GetAnimLength( %mp_descent_light04_fall );
	animateScriptableProps( "animated_model_descent_light04", animLength );
	animLength = GetAnimLength( %mp_descent_phone01_fall );
	animateScriptableProps( "animated_model_descent_phone01", animLength );
	animLength = GetAnimLength( %mp_descent_phone02_fall );
	animateScriptableProps( "animated_model_descent_phone02", animLength );
	animLength = GetAnimLength( %mp_descent_microwave_fall );
	animateScriptableProps( "animated_model_descent_microwave", animLength );
	animLength = GetAnimLength( %mp_descent_tv01_fall );
	animateScriptableProps( "animated_model_descent_tv01", animLength );
	// whiteboard and bulletin board use the same anim
	animLength = GetAnimLength( %mp_descent_whiteboard_fall );
	animateScriptableProps( "animated_model_descent_whiteboard", animLength );
	animateScriptableProps( "animated_model_descent_bulletinboard", animLength );
	animLength = GetAnimLength( %mp_descent_kitchen_fall );
	animateScriptableProps( "animated_model_descent_kitchen", animLength );
	
	// falling walls and columns
	// moverCreate( "side_wall_fall", "trigger_movers" );
	
	// elevator
	// elevator = GetEnt( "elevator", "targetname" );
	
	// building shake events
	level setupBuildingCollapse();
	// setupBuildingFx();
	level thread connect_watch();
	// level thread spawn_watch();
	
	thread setupCollapsingColumn( "column" );
	thread setupSniperDuct( "sniper_mover" );
	// thread animatedMoverCreate( "collapse", "mp_descent_wallscollapse_anim" );
}

connect_watch()
{
	while(1)
	{
		level waittill("connected", player);
		thread connect_watch_endofframe(player);
	}
}

connect_watch_endofframe(player)
{
	player endon("death");
	// self waittill( "player_spawned" );
	waittillframeend;	// so that spectators see it too?
	if(IsDefined(level.vista))
		player PlayerSetGroundReferenceEnt(level.vista);	
}

spawn_watch()
{
	while(1)
	{
		level waittill( "player_spawned", player );
		if(IsDefined(level.vista))
			player PlayerSetGroundReferenceEnt(level.vista);	
	}
}

anglesClamp180(angles)
{
	return (AngleClamp180(angles[0]),AngleClamp180(angles[1]),AngleClamp180(angles[2]));
}

world_tilt()
{
	level endon ( "game_ended" );
	
	damage_triggers = GetEntArray("world_tilt_damage", "targetname");
	array_thread(damage_triggers, ::world_tilt_damage_watch);
	
	vista_ents = GetEntArray("vista", "targetname");
	if(!vista_ents.size)
		return;
	
	level.vista = vista_ents[0];
	foreach(ent in vista_ents)
	{
		if(IsDefined(ent.script_noteworthy) && ent.script_noteworthy=="main")
		{
			level.vista = ent;
			break;
		}
	}
	
	//Init rotation Origins
	level.vista_rotation_origins = [];
	rotation_orgs = getstructarray("rotation_point", "targetname");
	foreach(org in rotation_orgs)
	{
		if(!isDefined(org.script_noteworthy))
			continue;
		
		org.angles = (0,0,0);
		
		level.vista_rotation_origins[ org.script_noteworthy ] = org;
	}
	
	foreach(ent in vista_ents)
	{
		if(ent!=level.vista)
		{
			if( IsDefined(ent.classname) && IsSubStr( ent.classname, "trigger" ))
				ent EnableLinkTo();
			ent LinkTo(level.vista);
		}
		if(!IsDefined(ent.target))
			continue;
		
		targets = GetEntArray(ent.target, "targetname");
		foreach(target in targets)
		{
			if(!IsDefined(target.script_noteworthy))
				target.script_noteworthy = "link";
			
			switch(target.script_noteworthy)
			{
				case "link":
					target LinkTo(ent);
					break;
				default:
					break;
			}
		}
	}
	
	while(!IsDefined(level.players))
		waitframe();
	
	foreach(player in level.players)
	{
		player PlayerSetGroundReferenceEnt(level.vista);
	}
	
	level.max_world_pitch = 8;
	level.max_world_roll = 8;
	
	max_abs_pitch = level.max_world_pitch;
	max_abs_roll = level.max_world_roll;
	max_fall_dist = 6500;
	num_lerp_tilts = 2; //scale first num_lerp_tilts to be less severe
	tilt_chance = .5; //Chance of playspace being level after a fall.
	multi_fall_chance = [0,0,1,0]; //[ignored, ignored, double_fall_chance, triple_fall_chance]
	
	test_vista = SpawnStruct();
	test_vista.origin = level.vista.origin;
	test_vista.angles = level.vista.angles;
	
	//Create random falls until the building is on (near) the ground
	vista_trans = [];
	while(1)
	{
		rotate_to = (0,0,0);
		if(tilt_chance<RandomFloat(1))
		{
			rotate_to = (RandomFloatRange(-1*max_abs_pitch, max_abs_pitch), 0, RandomFloatRange(-1*max_abs_roll, max_abs_roll));
		}
		
		move_by = (0,0,RandomFloatRange(200,1000));
		
		scale = 1;
		if(num_lerp_tilts>0)
		{
			scale = (vista_trans.size+1)/num_lerp_tilts;
			scale = clamp(scale, 0, 1.0);
		}
		
		rotate_to *= scale;
		move_by *= scale;
		
		trans = test_vista world_tilt_get_trans(move_by, rotate_to);
		if(trans["origin"][2] > level.vista.origin[2] + max_fall_dist)
		{
			break;
		}
		trans["time"] = RandomFloatRange(1,2) * scale;
		
		test_vista.origin = trans["origin"];
		test_vista.angles = trans["angles"];
		
		vista_trans[vista_trans.size] = trans;	
	}
	
	fall_count = vista_trans.size;
	
	//Distribute any extra fall distance across existing falls
	extra_z = level.vista.origin[2] + max_fall_dist - vista_trans[vista_trans.size-1]["origin"][2];
	if(extra_z > 0)
	{
		add_z = array_zero_to_one(vista_trans.size, .5);
		for(i=0; i<vista_trans.size; i++)
		{
			vista_trans[i]["origin"] += (0,0,add_z[i]*extra_z);
		}
	}
	
	//Calculate wait times
	fall_wait_times = array_zero_to_one(fall_count, .5);
	for(i=0; i<fall_wait_times.size-1; i++)
	{
		multi_fall_start = i;
		multi_fall_end = i;
		
		chance = RandomFloatRange(0,1);
		max_falls = int(min(multi_fall_chance.size-1, fall_wait_times.size-i));
		for(j=max_falls; j>=2; j--)
		{
			if(multi_fall_chance[j]>chance)
			{
				multi_fall_end = multi_fall_start+(j-1);
				break;
			}
		}
		
		//Redistribute the wait times if there is a double/triple fall
		multi_fall_count = multi_fall_end - multi_fall_start;
		if(multi_fall_count>0)
		{
			delta = fall_wait_times[multi_fall_end] - fall_wait_times[multi_fall_start];
			delta *= RandomFloatRange(.2, .8);
			
			new_time = fall_wait_times[multi_fall_start] + delta;
			for(j=multi_fall_start; j<=multi_fall_end; j++)
			{
				fall_wait_times[j] = new_time;
			}
			i+=multi_fall_count;	
		}
	}
	
	
/*
 	Assign fall objects to a fall stage
	level.fall_object_stage = [];
	for(i=0; i<fall_count; i++)
	{
		level.fall_object_stage[i] = [];
	}
	
	for(i=0; i<level.fall_objects.size; i++)
	{
		fall_object = level.fall_objects[i];
		if( !IsDefined(fall_object.script_index) )
		{
			fall_object.script_index = RandomIntRange(0, fall_count);
		}
		else
		{
			fall_object.script_index = fall_object.script_index % fall_count;
		}
		
		count = level.fall_object_stage[fall_object.script_index].size;
		level.fall_object_stage[fall_object.script_index][count] = fall_object;
	}
	*/
	
	
	
	for(i=0; i<vista_trans.size; i++)
	{
		level.tilt_active = false;
		tilt_wait(fall_wait_times[i]);
		
		
		
		level.tilt_active = true;
		
		trans = vista_trans[i];
		move_time = trans["time"];
		
		/*
 		foreach(object in level.fall_object_stage[i])
		{
			object thread fall_object_run( RandomFloatRange(move_time*.25, move_time*.75) );
		}
		
		foreach(object in level.tilt_objects)
		{
			object thread tilt_object_run(trans["angles"][0], trans["angles"][2], max_abs_pitch, max_abs_roll);
		}
		
		foreach(object in level.hang_objects)
		{
			object thread hang_object_run(trans["angles"], move_time);
		}
		*/
		
		trans = vista_trans[i];
		level.vista world_tilt_move(trans);
		Earthquake(.35, 2, level.vista.origin, 100000);
		
		/*
		gap_object_moves = 0;
		max_gap_object_moves = 6;
		level.gap_objects = array_randomize(level.gap_objects);
		for(j=0; j<level.gap_objects.size && gap_object_moves<max_gap_object_moves; j++)
		{
			object = level.gap_objects[j];
			if(IsDefined(object) && !object.fallen)
			{
				object notify("gap_object_move");
				gap_object_moves++;
			}
		}
		*/
	}
}

world_tilt_damage_watch()
{	
	while(1)
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type );

		if(level.tilt_active)
			continue;
		
		if(!IsDefined(damage) || damage<150)
			continue;
		
		if(!IsDefined(type) || type != "MOD_PROJECTILE")
			continue;
		
		self thread world_tilt_damage(damage);
	}
}

world_tilt_damage(damage)
{
	damage_min = 100;
	damage_max = 1000;
	damage_scale = clamp( (damage - damage_min)/(damage_max-damage_min), .1, 1);

	pitch_move = RandomFloatRange(2,3) * damage_scale;
	if(IsDefined(self.script_noteworthy) && self.script_noteworthy=="east")
		pitch_move *= -1.0;
	
	new_pitch = level.vista.angles[0] + pitch_move;
	new_pitch = Clamp(new_pitch, -1*level.max_world_pitch, level.max_world_pitch);
	
	new_angles = (new_pitch,level.vista.angles[1], level.vista.angles[2]);
	
	move_time = .2;
	level.vista RotateTo(new_angles, move_time);
	Earthquake(.2, 1, level.vista.origin, 100000);
	wait move_time;
}


wait_game_percent_complete( time_percent, score_percent )
{
	if(!IsDefined(score_percent))
		score_percent = time_percent;

	gameFlagWait( "prematch_done" );
	
	if(!IsDefined(level.startTime))
		return;
	
	score_limit = getScoreLimit();
	time_limit	= getTimeLimit() * 60;
	
	ignore_score = false;
	ignore_time = false;
	
	if( ( score_limit <= 0 ) && ( time_limit <= 0 ) )
	{
		ignore_score = true;
		time_limit = 10*60;
	}
	else if ( score_limit <= 0 )
	{
		ignore_score = true;
	}
	else if( time_limit <= 0 )
	{
		ignore_time = true;
	}
	
	time_threshold = time_percent * time_limit;
	score_threshold = score_percent * score_limit;

	higher_score = get_highest_score();
	timePassed = (getTime() - level.startTime) / 1000;
	
	if( ignore_score )
	{
		while( timePassed < time_threshold )
		{
			wait( 0.5 );
			timePassed = (getTime() - level.startTime) / 1000;
		}
	}
	else if( ignore_time )
	{
		while( higher_score < score_threshold )
		{
			wait( 0.5 );
			higher_score = get_highest_score();
		}
	}
	else
	{
		while( ( timePassed < time_threshold ) && ( higher_score < score_threshold ) )
		{
			wait( 0.5 );
			higher_score = get_highest_score();
			timePassed = (getTime() - level.startTime) / 1000;
		}		
	}
}

get_highest_score()
{
	highestScore = 0;
	if( level.teamBased )
	{
		if( isDefined( game[ "teamScores" ] ) )
		{
			highestScore = game["teamScores"]["allies"];
			if( game["teamScores"]["axis"] > highestScore )
			{
				highestScore = game["teamScores"]["axis"];
			}
		}
	}
	else
	{
		if(IsDefined(level.players))
		{
			foreach( player in level.players )
			{
				if( IsDefined( player.score ) && player.score > highestScore )
					highestScore = player.score;
			}
		}
	}
	return highestScore;
}

world_tilt_get_trans(move_delta, rotate_to)
{
	delta_angles = anglesClamp180(rotate_to - self.angles);
	
	rotation_point = level.vista_rotation_origins["south"];
	if(delta_angles[2]<0)
	{
		rotation_point = level.vista_rotation_origins["north"];
	}
	
	rotation_point.angles = self.angles;
	
	goal = SpawnStruct();
	goal.origin = rotation_point.origin + move_delta;
	goal.angles = rotate_to;
	
	trans = TransformMove(goal.origin, goal.angles, rotation_point.origin, rotation_point.angles, self.origin, self.angles);

	return trans;	
}

world_tilt_move(trans)
{
	exploder(1);
	level thread tilt_sounds();

	move_time = trans["time"];
	if(trans["origin"] != self.origin )
		self MoveTo(trans["origin"], move_time, move_time);
	if(anglesClamp180(trans["angles"]) != anglesClamp180(self.angles) )
		self RotateTo(trans["angles"], move_time);
	
	Earthquake(RandomFloatRange(.3, .5), move_time, self.origin, 100000);
	wait move_time;
}

array_zero_to_one_rand(count, min_value, max_value, sum_to)
{
	if(!IsDefined(min_value))
		min_value = 0;
	if(!IsDefined(max_value))
		max_value = 1;
	
	a = [];
	sum = 0;
	for(i=0; i<count; i++)
	{
		a[i] = RandomFloatRange(min_value, max_value);
		sum += a[i];
	}
	
	if(IsDefined(sum_to))
	{

		for(i=0; i<count; i++)
		{
			if(sum!=0)
			{
				a[i] = a[i] / sum;
				a[i] = a[i] * sum_to;
			}
			else
			{
				a[i] = sum_to/count;
			}
		}
	}
	
	return a;
}

array_zero_to_one(count, rand, sum_to)
{
	if(!IsDefined(rand))
		rand = 0;
	
	a = [];
	
	center_offset = (1/count) * .5;
	sum = 0;
	for(i=0; i<count; i++)
	{
		a[i] = (i/count) + center_offset;
	
		if(rand>0)
		{
			a[i] = a[i] + RandomFloatRange(-1*center_offset*rand, center_offset*rand);
		}
		
		sum += a[i];
	}
	
	if(IsDefined(sum_to))
	{
		for(i=0; i<count; i++)
		{
			a[i] = a[i] / sum;
			a[i] = a[i] * sum_to;
		}
	}
	
	return a;
}

tilt_wait(game_percent)
{
	level endon("tilt_start");
	/#
		level thread tilt_wait_dvar();
	#/
	wait_game_percent_complete(game_percent);
	level notify("tilt_start");
}

/#
tilt_wait_dvar()
{
	level endon("tilt_start");
	
	dvar_name = "trigger_tilt";
	default_value = 0;
	SetDevDvarIfUninitialized(dvar_name, default_value);
	
	while(GetDvarInt(dvar_name) == default_value)
	{
		waitframe();
	}
	SetDvar(dvar_name, GetDvarInt(dvar_name)-1);
	
	level notify("tilt_start");	
}
#/

tilt_sounds()
{
	sound_origins = getstructarray("tilt_sound", "targetname");
	
	foreach(org in sound_origins)
	{
		playSoundAtPos(org.origin, "cobra_helicopter_crash");
	}
}

/*
gap_objects()
{
	level.gap_objects = [];
	objects = GetEntArray("gap_object", "targetname");
	array_thread(objects, ::gap_object_init);		
}

gap_object_init()
{
	self.fallen = false;
	self thread gap_object_damage_watch();
	self thread gap_object_move();
	level.gap_objects[level.gap_objects.size] = self;
}

gap_object_damage_watch()
{
	self endon("death");
	self endon("gap_object_fall");
	
	self SetCanDamage(true);
	
	while(1)
	{
		self.health = 10000;
		self waittill("damage");
		self notify("gap_object_move");
	}
}

gap_object_move()
{
	self endon("death");
	
	num_moves = RandomIntRange(2,4);
	
	while(1)
	{
		self waittill("gap_object_move");
		
		num_moves--;
		if(num_moves<=0)
			break;
		
		move_time = .2;
		self RotateTo((RandomFloatRange(-4,4), 0, RandomFloatRange(-4,4)), move_time);
		self MoveTo(self.origin + (0,0,-2), move_time);
		wait move_time;
	}
	
	self notify("gap_object_fall");
	self.fallen = true;
	
	fall_time = 20;
	self MoveGravity((0,0,-20), 20);
	wait fall_time;
	self Delete();
}

hang_objects()
{
	level.hang_objects = [];
	objects = GetEntArray("hang_object", "targetname");
	array_thread(objects, ::hang_object_init);		
}

hang_object_init()
{
	self.move_ent = self;
	
	things = [];
	
	if(IsDefined(self.target))
	{
		structs = getstructarray(self.target, "targetname");
		ents = GetEntArray(self.target, "targetname");
	
		things = array_combine(ents, structs);
	}
	
	foreach(thing in things)
	{
		type = thing.script_noteworthy;
		if(!IsDefined(type))
			continue;
			
		switch(type)
		{
			case "link":
				thing linkto(self);
				break;
			default:
				break;
		}
	}
	
	level.hang_objects[level.hang_objects.size] = self;
}

hang_object_run(rotate_to, move_time)
{
	self.move_ent RotateTo(rotate_to, move_time);
}

tilt_objects()
{
	level.tilt_objects = [];
	objects = GetEntArray("tilt_object", "targetname");
	array_thread(objects, ::tilt_object_init);	
}

tilt_object_init()
{
	self.positions = [];
	self.move_ent = self;
	
	self.start_origin = self.origin;
	self.start_angles = self.angles;
	
	pos_names = ["current", "current_ns", "current_we", "north", "south", "east", "west"];
	foreach(name in pos_names)
	{
		s = SpawnStruct();
		s.origin_offset = (0,0,0);
		s.angles_offset = (0,0,0);
		self.positions[name] = s;
	}
	
	things = [];
	
	if(IsDefined(self.target))
	{
		structs = getstructarray(self.target, "targetname");
		things = array_combine(things, structs);
		
		ents = GetEntArray(self.target, "targetname");
		things = array_combine(things, ents);
	}
		
	if(IsDefined(self.script_linkto))
	{
		structs = self get_linked_structs();
		things = array_combine(things, structs);
		
		ents = self get_linked_ents();
		things = array_combine(things, ents);
	}
	
	foreach(thing in things)
	{
		type = thing.script_noteworthy;
		if(!IsDefined(type))
			continue;
			
		switch(type)
		{
			case "link":
				thing linkto(self);
				break;
			case "angle_ref":
				self.move_ent = spawn("script_model", thing.origin);
				self.move_ent SetModel("tag_origin");
				self.move_ent.angles = thing.angles;
				self linkTo(self.move_ent);
				
				self.start_origin = thing.origin;
				self.start_angles = thing.angles;
				break;
			case "north":
			case "south":
			case "east":
			case "west":
				self.positions[type].target = thing;
				break;
			default:
				break;
		}
	}
	
	any_pos_defined = false;
	foreach(name in pos_names)
	{
		thing = self.positions[name].target;
		if(IsDefined(thing))
		{
			any_pos_defined = true;
			self.positions[name].origin_offset = thing.origin - self.start_origin;
			self.positions[name].angles_offset = delta_angles(self.start_angles, thing.angles);
		}
	}
	
	if(any_pos_defined)
	{
		level.tilt_objects[level.tilt_objects.size] = self;
	}
}

delta_angles(from, to)
{
	p = AnglesDelta((from[0], 0, 0), (to[0], 0, 0));
	y = AnglesDelta((0, from[1], 0), (0, to[1], 0));
	r = AnglesDelta((0, 0, from[2]), (0, 0, to[2]));
	
	return (p, y, r);
}

tilt_object_run(set_pitch, set_roll, max_pitch, max_roll)
{
	self notify("tilt_object_run");
	self endon("tilt_object_run");
	
	pos_a = self.positions["current_we"];
	pos_a_lerp = 1;
	if(abs(set_pitch)>0.1)
	{
		if(set_pitch<0)
		{
			
			pos_a = self.positions["west"];
		}
		else
		{
			pos_a = self.positions["east"];
		}
		self.positions["current_we"] = pos_a;
	}
	

	pos_b = self.positions["current_ns"];
	pos_b_lerp = 1;
	if(abs(set_roll)>0.1)
	{
		if(set_roll<0)
		{
			pos_b = self.positions["south"];
		}
		else
		{
			pos_b = self.positions["north"];
		}
		
		self.positions["current_ns"] = pos_b;
	}
	
	new_origin_offset = (0,0,0);
	new_origin_offset += pos_a.origin_offset * pos_a_lerp;
	new_origin_offset += pos_b.origin_offset * pos_b_lerp;
	self.positions["current"].origin_offset = new_origin_offset;
	
	new_angles_offset = (0,0,0);
	new_angles_offset += pos_a.angles_offset * pos_a_lerp;
	new_angles_offset += pos_b.angles_offset * pos_b_lerp;
	self.positions["current"].angles_offset = new_angles_offset;
	
	new_origin = self.start_origin + self.positions["current"].origin_offset;
	new_angles = self.start_angles + self.positions["current"].angles_offset;
	
	move_time = 3;
	
	if(new_origin!=self.move_ent.origin)
		self.move_ent MoveTo(new_origin, move_time, move_time*.3, move_time*.3);
	if(anglesClamp180(new_angles) != anglesClamp180(self.move_ent.angles))
		self.move_ent rotateTo(new_angles, move_time);
	
	wait move_time;
		
	if(self is_dynamic_path())
		self DisconnectPaths();
}

is_dynamic_path()
{
	return IsDefined(self.spawnflags) && self.spawnflags&1;
}

fall_objects()
{
	level.fall_objects = [];
	objects = GetEntArray("fall_object", "targetname");
	array_thread(objects, ::fall_object_init);
}

fall_object_init()
{
	self.end = self;
	self.clip_move = [];
	self.connect_paths = [];
	self.disconnect_paths = [];
	
	things = [];
	
	if(IsDefined(self.target))
	{
		structs = getstructarray(self.target, "targetname");
		set_default_script_noteworthy(structs, "angle_ref");
		things = array_combine(things, structs);
		
		ents = GetEntArray(self.target, "targetname");
		things = array_combine(things, ents);
	}
		
	if(IsDefined(self.script_linkto))
	{
		structs = self get_linked_structs();
		set_default_script_noteworthy(structs, "start");
		things = array_combine(things, structs);
		
		ents = self get_linked_ents();
		things = array_combine(things, ents);
	}
	
	foreach(thing in things)
	{
		if(!IsDefined(thing.script_noteworthy))
			continue;
			
		switch(thing.script_noteworthy)
		{
			case "angle_ref":
				self.end = thing;
				break;
			case "start":
				self.start = thing;
				break;
			case "link":
				thing linkto(self);
				break;
			case "connect_paths":
				self.connect_paths[self.connect_paths.size] = thing;
				thing DisconnectPaths();
				break;
			case "disconnect_paths":
				self.disconnect_paths[self.disconnect_paths.size] = thing;
				thing ConnectPaths();
				break;
			case "clip_move":
				thing.start_origin = thing.origin;
				self.clip_move[self.clip_move.size] = thing;
				break;
			default:
				break;
		}
	}
	
	set_default_angles(things);
	
	if(IsDefined(self.start) && IsDefined(self.end))
	{
		level.fall_objects[level.fall_objects.size] = self;
		self fall_object_set_start_pos();
	}
}

set_default_script_noteworthy(things, noteworthy)
{
	if(!IsDefined(things))
		return;
	
	if(!IsDefined(noteworthy))
		noteworthy = "";
	
	if(!isArray(things))
		things = [things];
	
	foreach(thing in things)
	{
		if(!IsDefined(thing.script_noteworthy))
			thing.script_noteworthy = noteworthy;
	}
}

set_default_angles(things, angles)
{
	if(!IsDefined(things))
		return;
	
	if(!IsDefined(angles))
		angles = (0,0,0);
	
	if(!isArray(things))
		things = [things];
	
	foreach(thing in things)
	{
		if(!IsDefined(thing.angles))
			thing.angles = angles;
	}
}

fall_object_set_start_pos()
{
	self.fall_to_origin = self.origin;
	self.fall_to_angles = self.angles;
	
	trans = TransformMove(self.start.origin, self.start.angles, self.end.origin, self.end.angles, self.origin, self.angles);
	self.origin = trans["origin"];
	self.angles = trans["angles"];
}

fall_object_run(delayTime)
{
	//Hack revisit this
	if(IsDefined(self.fall_object_done) && self.fall_object_done)
		return;
	
	self.fall_object_done = true;
	
	
	if(isDefined(delayTime) && delayTime>0)
		wait delayTime;
	
	//Move clip into place first
	if(self.clip_move.size)
	{
		clip_move_time = .5;
		foreach(clip in self.clip_move)
		{
			clip MoveTo(self.fall_to_origin, clip_move_time );
		}
		wait clip_move_time;
		
		foreach(clip in self.clip_move)
		{
			if(clip fall_object_is_dynamic_path())
				clip DisconnectPaths();
		}
	}
	
	fall_speed = RandomFloatRange(300,320);
	dist = Distance(self.fall_to_origin, self.origin);
	time = dist/fall_speed;
	
	self moveTo(self.fall_to_origin, time, time, 0);
	if(self.fall_to_angles != self.angles)
		self RotateTo(self.fall_to_angles, time, 0, 0);
	
	wait time;
	
	foreach(ent in self.disconnect_paths)
	{
		ent DisconnectPaths(); 
	}
	
	foreach(ent in self.connect_paths)
	{
		ent ConnectPaths();
		ent Delete();
	}
	
	foreach(clip in self.clip_move)
	{
		clip.origin = clip.start_origin;
	}
}

fall_object_is_dynamic_path()
{
	return self.spawnflags&1;
}

//Move to common script
get_linked_structs()
{
	array = [];

	if ( IsDefined( self.script_linkTo ) )
	{
		linknames = get_links();
		for ( i = 0; i < linknames.size; i++ )
		{
			ent = getstruct( linknames[ i ], "script_linkname" );
			if ( IsDefined( ent ) )
			{
				array[ array.size ] = ent;
			}
		}
	}

	return array;
}
*/

watersheet_trig_setup()
{
	
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "using_remote" );
	self endon( "stopped_using_remote" );	
	self endon( "disconnect" );
	self endon( "above_water" );
	
	trig = getent("watersheet", "targetname" );	
	//level.player ent_flag_init("water_sheet_sound");
	//level thread watersheet_sound( trig );
	
	while(1)
	{
			
		trig waittill("trigger", player );
		
		if ( !isDefined(player.isTouchingWaterSheetTrigger) || player.isTouchingWaterSheetTrigger == false)
		{
			
			thread watersheet_PlayFX( player );
		
		}
	
	}	
}

watersheet_PlayFX( player ) {
	
		player.isTouchingWaterSheetTrigger = true;
	
		player SetWaterSheeting( 1, 2 );
		wait( randomfloatrange( .15, .75) );
		player SetWaterSheeting( 0 );	
		
		player.isTouchingWaterSheetTrigger = false;
	
}

watersheet_sound( trig )
{
	trig endon("death");
	thread watersheet_sound_play(trig);
	while( 1 )
	{
		trig waittill( "trigger", player );
		
		trig.sound_end_time = GetTime() + 100;
		trig notify("start_sound");
	}
}

watersheet_sound_play(trig)
{
	trig endon("death");
	
	while(1)
	{
		trig waittill("start_sound");
		
		trig PlayLoopSound("scn_jungle_under_falls_plr");
		
		while(trig.sound_end_time>GetTime())
			wait (trig.sound_end_time-GetTime())/1000;
		
		trig StopLoopSound();
	}
}

animateScriptableProps( targetName, fallAnimLength )
{
	ents = GetScriptableArray( targetName, "targetname" );
	
	foreach ( ent in ents )
	{
		ent thread animateOneScriptableProp( fallAnimLength );
	}
}

animateOneScriptableProp( fallAnimLength )
{
	while ( true )
	{
		// random delay to offset the idle anims
//		frameDelay = RandomIntRange(0, 11) * 0.05;
//		wait( frameDelay );
		self SetScriptablePartState( 0, "idle" );
		
		level waittill( "shake_props" );
		
		frameDelay = RandomIntRange(0, 7) * 0.05;
		wait( frameDelay );
		
		self SetScriptablePartState( 0, "fall" );
		
		wait ( fallAnimLength );
		
	}
}

CONST_DOUBLE_DOOR_MIN_DAMAGE = 50;
CONST_DOUBLE_DOOR_VFX = "equipment_explode_big";
CONST_DOUBLE_DOOR_ANGLE_MAX = 85;
CONST_DOUBLE_DOOR_EXPLODE_OPEN_TIME = 0.125;
doubleDoorCreate( doorName )
{
	door = GetEnt( doorName, "targetname" );
	if ( IsDefined( door ) )
	{
		door.collision = GetEnt( doorName + "_clip", "targetname" );
		
		door.ruins = [];
		door.ruins[0] = getRuin( doorName + "_upper" );
		door.ruins[1] = getRuin( doorName + "_lower" );
		
		door.destroyFxPoint = getstruct( door.ruins[0].target, "targetname" );
		Assert( IsDefined( door.destroyFxPoint ) );
		
		waitframe();
		door blockPath();
		
		door thread doubleDoorWaitForDamage();
	}
}

doubleDoorWaitForDamage()
{
	self.health = 9999;
	self SetCanDamage( true );
	
	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, impact_loc, damage_type );
		if ( IsExplosiveDamageMOD( damage_type ) && damage > CONST_DOUBLE_DOOR_MIN_DAMAGE )
		{
			self thread doubleDoorDestroy( attacker, direction_vec, impact_loc );
		}
	}
}

doubleDoorDestroy( attacker, direction_vec, impact_loc )
{
	self.collision clearPath();
	self clearPath();
	
	facingDir = AnglesToForward( self.destroyFxPoint.angles );
	dotProd = VectorDot( facingDir, direction_vec );
	isFront = dotProd > 0;
	angleLimit = CONST_DOUBLE_DOOR_ANGLE_MAX;
	
	thread drawLine( self.destroyFxPoint.origin, self.destroyFxPoint.origin + 20 * facingDir, 50, (1, 0, 0) );
	
	if ( !isFront )
	{
		facingDir *= -1;
	}
	else
	{
		angleLimit *= -1;
	}
	
	PlayFX( getfx( CONST_DOUBLE_DOOR_VFX ), self.destroyFxPoint.origin, facingDir );
	
	foreach( doorRuin in self.ruins )
	{
		doorRuin Show();
		doorRuin thread doorApplyImpulse( angleLimit );
		angleLimit *= -1;
	}
}

getRuin( ruinName )
{
	ruin = GetEnt( ruinName, "targetname" );
	Assert( IsDefined( ruin ) );
	ruin Hide();
	
	return ruin;
}


trapDoorCreate( doorName )
{
	door = GetEnt( doorName, "targetname" );
	if ( IsDefined( door ) )
	{
		self.pathBlocker = GetEnt( door.target, "targetname" );
		
		waitframe();
		self.pathBlocker blockPath();
		
		door thread trapDoorWaitForDamage();
	}
}

trapDoorWaitForDamage()
{
	self.health = 9999;
	self SetCanDamage( true );
	
	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, impact_loc, damage_type );
		
		self thread trapDoorDestroy( attacker, direction_vec, impact_loc );
	}
}

trapDoorDestroy( attacker, direction_vec, impact_loc )
{
	self.pathBlocker NotSolid();
	self.pathBlocker clearPath();
	
	/*
	
	facingDir = AnglesToForward( self.destroyFxPoint.angles );
	dotProd = VectorDot( facingDir, direction_vec );
	isFront = dotProd > 0;
	angleLimit = CONST_DOUBLE_DOOR_ANGLE_MAX;
	
	thread drawLine( self.destroyFxPoint.origin, self.destroyFxPoint.origin + 20 * facingDir, 50, (1, 0, 0) );
	
	if ( !isFront )
	{
		facingDir *= -1;
		angleLimit *= -1;
	}
	
	PlayFX( getfx( CONST_DOUBLE_DOOR_VFX ), self.destroyFxPoint.origin, facingDir );
	*/
	anglelimit = 90.0;
	
	self thread doorApplyImpulse( angleLimit ); 
}

doorApplyImpulse( angleLimit )
{
	self RotateBy( (angleLimit, 0, 0), CONST_DOUBLE_DOOR_EXPLODE_OPEN_TIME, CONST_DOUBLE_DOOR_EXPLODE_OPEN_TIME, 0 );
}

clearPath()	// self == blockingEnt
{
	self ConnectPaths();
	self Hide();
	self NotSolid();
}

blockPath()
{
	self Solid();
	self Show();
	self DisconnectPaths();
}

GRAVITY_DVAR = "phys_gravity";
levitateProps( minTime, maxTime )
{
	baseGravity = GetDvarInt( GRAVITY_DVAR, -800 );
	SetDvar( GRAVITY_DVAR, 0 );
	
	PhysicsJitter( level.mapCenter, 2500, 0, 5.0, 5.0 );
	
	gravityTime = RandomFloatRange( minTime, maxTime );
	
	wait( gravityTime );
	
	SetDvar( GRAVITY_DVAR, baseGravity );
}


// -----------------------------------
// Movers - big things that fall on a keyframed path
// Requires entity with a known <name>
// Collision named "<name>_collision"
// entity targets a series of script structs with position and orientation that represent the flight path of ent
// Each entity should have a script_duration, which specifies the MoveTo time
// optionally have script_accel and script_decel to control acceleration. First node should have script_accel = script_duration
// Somehow, we'll use script_noteworthy to control vfx and sounds?
// triggerFlag - the name of the notify that it will respond to.
// Also responds to explosions
moverCreate( moverName, triggerFlag )
{
	mover = GetEnt( moverName, "targetname" );
	mover.collision = GetEnt( moverName + "_collision", "targetname" );
	
	if ( IsDefined( mover.collision ) )
	{
		mover.collision LinkTo( mover );
		mover.collision thread moverExplosiveTrigger( triggerFlag );
	}
	
	mover.unresolved_collision_func = maps\mp\_movers::unresolved_collision_void;
	
	// get keyframes
	ent = mover;
	ent.keyframes = [];
	nextKeyFrameName = ent.target;
	i = 0;
	while ( IsDefined( nextKeyFrameName ) )
	{
		struct = getstruct( nextKeyFrameName, "targetname" );
		if ( IsDefined( struct ) )
		{
			ent.keyframes[i] = struct;
			
			// set default values
			if ( !IsDefined( struct.script_duration ) )
				struct.script_duration = 1.0;
			
			if ( !IsDefined( struct.script_accel ) )
				struct.script_accel = 0.0;
			
			if ( !IsDefined( struct.script_decel ) )
				struct.script_decel = 0.0;
			
			i++;
			nextKeyFrameName = struct.target;
		}
		else
		{
			break;
		}
	}
	
//	bus.pathBlocker = GetEnt( "pathBlocker", "targetname" );
//	wait(0.05);
//	bus.pathBlocker elevatorClearPath();
	
	mover thread moverDoMove( triggerFlag );
}

moverExplosiveTrigger( note )
{
	level endon( "game_ended" );
	
	if(!IsDefined(note))
		note = "explosive_damage";
	
	self SetCanDamage( true );
	while ( true )
	{
		self.health = 1000000;
		self waittill("damage", amount, attacker, direction_vec, point, type);
		if ( IsExplosiveDamageMOD( type ) )
		{
			level notify( note, self );
		}
	}
}

moverDoMove( waitString )	// self == mover entity
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		level waittill( waitString, mover );
		
		if ( !IsDefined( mover ) || mover == self )
		{
			break;
		}
	}
	
	// play start sfx, vfx
	
//	self.pathBlocker elevatorBlockPath();
//	self.collision killLinkedEntities( attacker );
	
	for ( i = 1 ; i < self.keyframes.size; i++ )
	{
		kf = self.keyframes[i];
		
		self MoveTo( kf.origin, kf.script_duration, kf.script_accel, kf.script_decel );
		self RotateTo( kf.angles, kf.script_duration, kf.script_accel, kf.script_decel );
		
		//	self PlaySound( "scn_bus_groan" );
		//	self busSlidingEffect();
		
		if ( IsDefined( kf.shakeMag ) )
		{
			Earthquake( kf.shakeMag, kf.shakeDuration, self.origin, kf.shakeDistance );
		}
		
		self waittill( "movedone" );
	}
	
	// play another sound?
	
	// shake?
	fakeImpactPoint = self.origin + (0, 0, 2000);
	
	Earthquake( 0.25, .5, fakeImpactPoint, 3000 );
	
	// play stop vfx, sfx
	// PlaySoundAtPos(fakeBusPos, "scn_bus_crash");
}

//entName
//animName
//Sounds - start, stop
//VFX - start, stop 
// animation length?
animatedMoverCreate( entName, animName, fallSound, impactSound, impactDelay, impactOffset )
{
	mover = GetEnt( entName, "targetname" );
	
	if ( IsDefined( mover ) )
	{
		level waittill( "trigger_movers" );
		
		if ( IsDefined( fallSound ) )
		{
			mover PlaySound( fallSound );
		}
		
		mover ScriptModelPlayAnim( animName );
		
		if ( IsDefined( impactSound ) )
		{
			wait ( impactDelay );
			
			PlaySoundAtPos( impactOffset, impactSound );
		}
	}
}

setupCollapsingColumn( entName )
{
	mover = GetEnt( entName, "targetname" );
	if ( IsDefined( mover ) )
	{
		rubble = GetEnt( entName + "_debris_clip", "targetname" );
		// rubble Hide();
		rubble NotSolid();
		// rubble.clip clearPath();
		
		// must make sure that there are enough drop nodes for this to work
		// we also don't want to trigger the column on the first drop
		fallNum = RandomIntRange( 1, level.dropNodes.size );
		fallString = "buildingCollapseEnd_" + fallNum;
			
		level waittill_any( fallString, "trigger_movers" );
		
		// turn off collision on pristine model
		
		mover PlaySound( CONST_COLUMN_FALL_SFX );
		
		mover ScriptModelPlayAnim( CONST_COLUMN_FALL_ANIM );
		
		// This should use the position of rubble!
		impactPos = rubble.origin + (0, 0, 10);	// offset slightly for radius damage
		
		wait ( CONST_COLUMN_IMPACT_DELAY );
			
		PlaySoundAtPos( impactPos, CONST_COLUMN_IMPACT_SFX );
		
		// play effect
		exploder( CONST_COLUMN_IMPACT_VFX_EXPLODER_ID );
		
		Earthquake( 0.3, 0.25, impactPos, 500 );
		
		RadiusDamage( impactPos, CONST_COLUMN_DAMAGE_RADIUS, CONST_COLUMN_DAMAGE, CONST_COLUMN_DAMAGE, undefined, "MOD_CRUSH" );
			
		// swap in fallen model, connect paths, etc.
		// mover Hide();
	//	rubble Show();
		rubble Solid();
		// rubble.clip blockPath();
	}
}

setupSniperDuct( entName )
{
	duct = GetEnt( entName, "targetname" );
	if ( IsDefined( duct ) )
	{
		// have to create an ent to rotate around, because the origin of the duct isn't the right point
		rootStruct = getstruct( entName + "_origin", "targetname" );
		root = Spawn( "script_model", rootStruct.origin );
		duct LinkTo( root );
		
		duct2 = GetEnt( duct.target, "targetname" );
		duct2 LinkTo( root );
		
		// must make sure that there are enough drop nodes for this to work
		// we also don't want to trigger the column on the first drop
		fallNum = RandomIntRange( 1, level.dropNodes.size );
		fallString = "buildingCollapseEnd_" + fallNum;
		
		// dbg
//		while ( true ) {
		
		level waittill_any( fallString, "trigger_movers" );
		
		// duct PlaySound( CONST_COLUMN_FALL_SFX );
		// play fx
		// rotate some swinging
		root RotatePitch( 1.1 * CONST_SNIPER_DUCT_ANGLE, CONST_SNIPER_DUCT_TIME, 0.85 * CONST_SNIPER_DUCT_TIME, 0.15 * CONST_SNIPER_DUCT_TIME );
		wait ( CONST_SNIPER_DUCT_TIME );
		
		CONST_SWING_PERCENTAGE = 0.5;
		recoveryTime = CONST_SWING_PERCENTAGE * CONST_SNIPER_DUCT_TIME;
		root RotatePitch( -0.15 * CONST_SNIPER_DUCT_ANGLE, recoveryTime, 0.5 * recoveryTime, 0.5 * recoveryTime );
		wait ( recoveryTime );
		
		// root RotatePitch( 0.3 * CONST_SNIPER_DUCT_ANGLE, recoveryTime, 0.5 * recoveryTime, 0.5 * recoveryTime );
		// wait ( recoveryTime );
		
		root RotatePitch( 0.05 * CONST_SNIPER_DUCT_ANGLE, recoveryTime, 0.5 * recoveryTime, 0.5 * recoveryTime );
		wait ( recoveryTime );
		
		// dbg
//		wait ( 3 );
//		
//		root RotatePitch( -1 * CONST_SNIPER_DUCT_ANGLE, recoveryTime, 0.5 * recoveryTime, 0.5 * recoveryTime );
//		
//		wait ( recoveryTime );
//		}
	}
}

// these are the structs that control the position/orientation of each stage of the building collapsing
setupBuildingCollapse()
{
	// find all the sound sources for the falling builindgs
	level.soundSources = [];
	soundStructs = getstructarray( "tilt_sound", "targetname" );
	if ( IsDefined( soundStructs ) )
	{
		foreach( struct in soundStructs )
		{
			level.soundSources[ struct.script_label ] = struct;
		}
	}
	
	// configuration data for each stage of collapse
	level.collapseSettings = [];
	
	curSettings = [];
	curSettings[ "prefalltime" ] = CONST_DEFAULT_PREFALL_TIME;	// amount of time to play sfx/vfx before actually moving
	curSettings[ "falltime" ] = CONST_DEFAULT_FALL_TIME;
	curSettings[ "sfx" ] = [];
	curSettings[ "sfx" ][ "rubble_left" ]	= "scn_bldg_fall1_rubble_left";
	curSettings[ "sfx" ][ "rubble_right" ]	= "scn_bldg_fall1_rubble_right";
	curSettings[ "sfx" ][ "glass_left" ]	= "scn_bldg_fall1_glass_left";
	curSettings[ "sfx" ][ "glass_right" ]	= "scn_bldg_fall1_glass_right";
	level.collapseSettings[ level.collapseSettings.size ] = curSettings;
	
	curSettings = [];
	curSettings[ "prefalltime" ] = CONST_DEFAULT_PREFALL_TIME;	// amount of time to play sfx/vfx before actually moving
	curSettings[ "falltime" ] = CONST_DEFAULT_FALL_TIME;
	curSettings[ "sfx" ] = [];
	curSettings[ "sfx" ][ "rubble_left" ]	= "scn_bldg_fall2_rubble_left";
	curSettings[ "sfx" ][ "rubble_right" ]	= "scn_bldg_fall2_rubble_right";
	curSettings[ "sfx" ][ "glass_left" ]	= "scn_bldg_fall2_glass_left";
	curSettings[ "sfx" ][ "glass_right" ]	= "scn_bldg_fall2_glass_right";
	level.collapseSettings[ level.collapseSettings.size ] = curSettings;
	
	curSettings = [];
	curSettings[ "prefalltime" ] = CONST_DEFAULT_PREFALL_TIME;	// amount of time to play sfx/vfx before actually moving
	curSettings[ "falltime" ] = CONST_DEFAULT_FALL_TIME;
	curSettings[ "sfx" ] = [];
	curSettings[ "sfx" ][ "rubble_left" ]	= "scn_bldg_fall3_rubble_left";
	curSettings[ "sfx" ][ "rubble_right" ]	= "scn_bldg_fall3_rubble_right";
	curSettings[ "sfx" ][ "glass_left" ]	= "scn_bldg_fall3_glass_left";
	curSettings[ "sfx" ][ "glass_right" ]	= "scn_bldg_fall3_glass_right";
	level.collapseSettings[ level.collapseSettings.size ] = curSettings;
	
	curSettings = [];
	curSettings[ "prefalltime" ] = CONST_DEFAULT_PREFALL_TIME;	// amount of time to play sfx/vfx before actually moving
	curSettings[ "falltime" ] = CONST_DEFAULT_FALL_TIME;
	curSettings[ "sfx" ] = [];
	curSettings[ "sfx" ][ "rubble_left" ]	= "scn_bldg_fall4_rubble_left";
	curSettings[ "sfx" ][ "rubble_right" ]	= "scn_bldg_fall4_rubble_right";
	curSettings[ "sfx" ][ "glass_left" ]	= "scn_bldg_fall4_glass_left";
	curSettings[ "sfx" ][ "glass_right" ]	= "scn_bldg_fall4_glass_right";
	level.collapseSettings[ level.collapseSettings.size ] = curSettings;
	
	curSettings = [];
	curSettings[ "prefalltime" ] = 0.5;	// amount of time to play sfx/vfx before actually moving
	curSettings[ "falltime" ] = CONST_DEFAULT_FALL_TIME;
	curSettings[ "sfx" ] = [];
	curSettings[ "sfx" ][ "rubble_left" ]	= "scn_bldg_fall5_rubble_left";
	curSettings[ "sfx" ][ "rubble_right" ]	= "scn_bldg_fall5_rubble_right";
	curSettings[ "sfx" ][ "glass_left" ]	= "scn_bldg_fall5_glass_left";
	curSettings[ "sfx" ][ "glass_right" ]	= "scn_bldg_fall5_glass_right";
	level.collapseSettings[ level.collapseSettings.size ] = curSettings;
	
	level.vista = GetEnt( "vista_test", "targetname" );
	
	dropNodeOffsets = [];
	dropNodeOffsets[0] = 550;
	dropNodeOffsets[1] = 400;
	dropNodeOffsets[2] = 350;
	
	level.dropNodes = [];
	curNode = getstruct( "drop_node2", "targetname" );
	
	// maybe should be per-fall
	maxPitch = CONST_DEFAULT_MAX_PITCH;
	maxRoll = CONST_DEFAULT_MAX_ROLL;
	
	curHeight = level.vista.origin[2];
	i = 0;
	while ( IsDefined( curNode ) )
	{
		curNode.angles = (RandomFloatRange(-1*maxPitch, maxPitch), 0, RandomFloatRange(-1*maxRoll, maxRoll));
		curNode.origin -= (0, 0, dropNodeOffsets[i]);
		i++;
		
		// add a secondary angle?
		level.dropNodes[ level.dropNodes.size ] = curNode;
		
		if ( IsDefined( curNode.target ) )
			curNode = getstruct( curNode.target, "targetname" );
		else
			break;
	}
	
	level thread dropNodeWait();
	level thread setupDropEventTrigger();
	
	// setup concrete building facades
	level.facadeConcrete = [];
	for ( i = 0; i < level.dropNodes.size; i++ )
	{
		entName = CONST_CONCRETE_FACADE_NAME + i;
		facade = GetEnt( entName, "targetname" );
		facade LinkTo( level.vista );
		level.facadeConcrete[ i ] = facade;
	}
	
	// setup glass building facades
	level.facadeGlass = [];
	level.ruinGlass = [];
	for ( i = 0; i < level.dropNodes.size; i++ )
	{
		entName = CONST_GLASS_FACADE_NAME + i;
		facades = GetEntArray( entName, "targetname" );
		
		facades = array_sort_with_func( facades, ::compareHeight );
		
		level.facadeGlass[ i ] = facades;
		
		foreach ( item in facades )
		{
			item LinkTo( level.vista );
		}
		
		ruinName = CONST_GLASS_FACADE_NAME + "ruin_" + i;
		ruin = GetEnt( ruinName, "targetname" );
		if ( IsDefined( ruin ) )
		{
			ruin LinkTo ( level.vista );
			ruin Hide();
			level.ruinGlass[ i ] = ruin;
		}
	}
}

compareHeight( a, b )
{
	return (a.origin[2] > b.origin[2]);
}

dropNodeWait()
{
	level.dropStage = 0;
	
	while ( level.dropStage < level.dropNodes.size )
	{
		level waittill( "buildingCollapse" );
		
		doBuildingFall( level.dropStage );
		
		level.dropStage++;
	}
}

doBuildingFall( nodeIndex )
{
	level.buildingIsFalling = true;
	
	targetPos = level.dropNodes[ nodeIndex ];
	settings = level.collapseSettings[ nodeIndex ];
	
	startShockTime = settings[ "prefalltime" ];
	moveTime = settings[ "falltime" ];
	
	// ----------------------------------
	// start sequence
	// trigger sounds
	foreach ( structName, struct in level.soundSources )
	{
		PlaySoundAtPos( struct.origin, settings[ "sfx" ][ structName ] );
	}
	
	Earthquake( RandomFloatRange( 0.1, 0.2), startShockTime, level.mapCenter, CONST_EARTHQUAKE_RANGE );
	
	targetRoll = RandomFloatRange( CONST_DEFAULT_MIN_ROLL, CONST_DEFAULT_MAX_ROLL );
	if ( RandomFloat( 1 ) < 0.5 )
		targetRoll *= -1;
	
	targetPitch = RandomFloatRange( CONST_DEFAULT_MIN_PITCH, CONST_DEFAULT_MAX_PITCH );
	if ( RandomFloat( 1 ) < 0.5 )
		targetPitch *= -1;
	
	targetAngle = (targetPitch, 0, targetRoll );
	level.vista RotateTo( 0.75 * targetAngle, startShockTime, 1.0 * startShockTime, 0.0 );
	
	level thread destroyAirKillstreaks();
	
	wait( startShockTime );
	
	level.disableVanguardsInAir = true;
	
	exploder( CONST_GLASS_BUILDING_EXPLODER_ID );
	
	playRumble( "damage_light" );
	
	// ----------------------------------
	// Main fall
	// shake for the duration of the fall
	Earthquake( RandomFloatRange( 0.3, 0.45), moveTime, level.mapCenter, CONST_EARTHQUAKE_RANGE );
	
	// play some effects, hide the old facade
	level thread animateConcreteBuildingFacade( nodeIndex, moveTime );
	level thread animateGlassBuildingFacade( nodeIndex, moveTime );
	
	level.vista MoveTo( targetPos.origin, moveTime, 0.25 * moveTime, 0.0 );
	level.vista RotateTo( -1 * targetAngle, moveTime, 0.25 * moveTime, 0.0 );
	
	// trigger other effects
	level notify( "shake_props" );
	level notify( "buildingCollapseStart_" + nodeIndex );
	
	wait( moveTime );
	
	// -----------------------------------
	// Impact
	// should get these earthquake values from elsewhere?
	Earthquake( RandomFloatRange(0.8, 1.0), 1.5, level.mapCenter, CONST_EARTHQUAKE_RANGE );
	exploder( CONST_FALL_EXPLODER_ID );
	exploder( CONST_GLASS_BUILDING_EXPLODER_ID );
	
	level notify( "buildingCollapseEnd_" + nodeIndex );
	
	level.disableVanguardsInAir = undefined;
	
	playRumble( "artillery_rumble" );
	
	wait( 0.5 );
	
	// --------------------
	// Settle into position
	settleTime = CONST_DEFAULT_SETTLE_TIME;
	finalAngles = ( -0.25 * targetPitch, 0, 0.25 * targetRoll);
	level.vista RotateTo( finalAngles, settleTime, 0.8 * settleTime, 0.2 * settleTime );
	
	wait( 0.75 * settleTime );
	Earthquake( RandomFloatRange(0.3, 0.5), 0.25 * settleTime + 1.0, level.mapCenter, CONST_EARTHQUAKE_RANGE );
	
	playRumble( "damage_light" );
	
	// play fall impact sound
	
	level.buildingIsFalling = undefined;
}

animateConcreteBuildingFacade( nodeIndex, moveTime )
{
	// only show the first two facades
	// if ( nodeIndex >= 2 ) return;
	
	facade = level.facadeConcrete[ nodeIndex ];
	if ( IsDefined( facade ) )
	{
		// trigger particle effects
		
		oldModel = facade.model;
		facade SetModel( CONST_CONCRETE_FACADE_RUIN_MODEL );
		
		// create a new model of the pristine building to slide away
		oldFace = Spawn( "script_model", facade.origin );
		oldFace.angles = facade.angles;
		oldFace SetModel( oldModel );
		
		upVec = AnglesToUp( oldFace.angles );
		
		endPos = oldFace.origin - 150 * upVec;
		oldFace MoveTo( endPos, moveTime, moveTime, 0 );
		oldFace RotateRoll( 20, moveTime, moveTime, 0 );
		
		wait ( movetime );
		oldFace Delete();
	}
}

animateGlassBuildingFacade( nodeIndex, moveTime )
{
	if ( IsDefined( level.facadeGlass[ nodeIndex ] ) )
	{
		timeStep = moveTime / level.facadeGlass[ nodeIndex ].size;
		
		level.ruinGlass[ nodeIndex ] Show();
		
		foreach ( item in level.facadeGlass[ nodeIndex ] )
		{
			item thread glassFacadeFall( moveTime );
			wait( timeStep );
		}
	}
}

glassFacadeFall( moveTime )
{
	self Unlink();
	
	upVec = AnglesToUp( self.angles );
	
	endPos = self.origin - 400 * upVec;
	self MoveTo( endPos, moveTime, moveTime, 0 );
	self RotateRoll( -60, moveTime, moveTime, 0 );
	
	wait( moveTime );
	
	self Delete();
}

setupDropEventTrigger()
{
	numIntervals = level.dropNodes.size + 1;	// +1 so we can to play in the level after the last drop
	
	// this should be set up per game mode
	
	if ( level.gameType == "sr" || level.gameType == "sd" )
	{
		level thread searchAndRescueEventTriggerDrop();
	}
	else
	{
		// setup score-based events
		scoreLimit = getWatchedDvar( "scorelimit" );
		if ( level.teamBased && scoreLimit >= level.dropNodes.size * 20 )	// do a drop at most every X kills
		{
			level thread scoreLimitTriggerDrop( scoreLimit, level.dropNodes.size );
		}
		else 
		{
			timeLimit = getWatchedDvar( "timelimit" );
			if ( timeLimit <= 0 )
			{
				timeLimit = 10;	// in minutes
			}
			timeLimit *= 60;	// convert to seconds
			
			level thread timeLimitTriggerDrop( timeLimit, numIntervals );
		}
	}
}

searchAndRescueEventTriggerDrop()
{
	level endon( "game_ended" );
	
	while ( true )
	{
		result = level waittill_any_return( "last_alive", "bomb_exploded", "bomb_dropped" );
		
		if ( result == "last_alive" || !level.bombPlanted )
		{
			// unfortunately, I don't know how to get the game end time, so always fire off the event
			// luckily, we can only trigger one fall at a time
		
			interval = RandomFloatRange( CONST_EVENT_TRIGGER_FALL_DELAY_MIN, CONST_EVENT_TRIGGER_FALL_DELAY_MAX );
			wait( interval );
		}
		else if ( result != "bomb_exploded" )
		{
			continue;
		}
		
		level notify( "buildingCollapse" );
	}
}

scoreLimitTriggerDrop( scoreLimit, numDrops )
{
	level endon( "game_ended" );
	
	level thread periodicTremor( 90, 120 );
	
	// !!! hack. We assume numIntervals == 3, because we're going to go 30%, 60% 90%
	scoreInterval = Int( 0.3 * scoreLimit );
	/#
		SetDvarIfUninitialized( "scr_desc_scoreInterval", scoreInterval );	
	#/
	curDrop = 1;
	
	while ( true )
	{
		level waittill ( "update_team_score", team, newScore );
		
		/#
			scoreInterval = GetDvarInt( "scr_desc_scoreInterval" );
		#/
		
		if ( newScore >= curDrop * scoreInterval )
		{
			interval = RandomFloatRange( CONST_EVENT_TRIGGER_FALL_DELAY_MIN, CONST_EVENT_TRIGGER_FALL_DELAY_MAX );
			wait( interval );
			
			level notify( "buildingCollapse" );
			curDrop++;
		}
	}
}

timeLimitTriggerDrop( timeLimit, numIntervals )
{
	level endon( "game_ended" );
	
	timeInterval = timeLimit / numIntervals;
	
	level thread periodicTremor( 0.8 * timeInterval, 1.2 * timeInterval );
	
	while ( level.dropStage < level.dropNodes.size )
	{
		wait( timeInterval );
		level notify( "buildingCollapse" );
	}
}

periodicTremor( minTime, maxTime )
{
	level endon( "game_ended" );
	
	// wait an initial delay
	interval = 0.5 * RandomFloatRange( minTime, maxTime );
	/#
	debugInterval = GetDvarInt( "scr_dbg_tremor_interval" );
	if ( debugInterval > 0 )
		interval = debugInterval;
	#/
	
	
	wait( interval );
	
	while ( true )
	{
		if ( !IsDefined( level.buildingIsFalling ) )
		{
			// play sound
			PlaySoundAtPos( level.mapCenter, "scn_bldg_tremor_lr" );
			
			magnitude = RandomFloatRange( 0.2, 0.3 );
			duration = RandomFloatRange( 1.0, 1.5 );
			
			Earthquake( magnitude, duration, level.mapCenter, CONST_EARTHQUAKE_RANGE );
			
		}
		
		interval = RandomFloatRange( minTime, maxTime );
		/#
		debugInterval = GetDvarInt( "scr_dbg_tremor_interval" );
		if ( debugInterval > 0 )
			interval = debugInterval;
		#/
		wait( interval );
	}
}

/*
shakePlayerControlledHelis( duration )
{
	if ( IsDefined( level.littleBirds ) )
	{
		foreach ( heli in level.littleBirds )
		{
			Earthquake( 0.5, duration, heli.origin, 512 );
		}
	}
}
*/

setupBuildingFx()
{
	fxRig = GetEnt( "column_chunk", "targetname" );
	
	PlayFXOnTag( getfx( "vfx_building_debris_runner" ), fxRig, "tag_03_vfx_building_debris_runner" );
	PlayFXOnTag( getfx( "vfx_spark_drip_dec_runner" ), fxRig, "tag_02_vfx_spark_drip_dec_runner" );
	PlayFXOnTag( getfx( "vfx_building_hole_elec_short_runner" ), fxRig, "tag_01_vfx_building_hole_elec_short_runner" );
}

// ugh, this is very heavy handed
// Becuase the fall sequence looks bad from the air, we will kill all air vehicles. 
destroyAirKillstreaks()
{
	// play an effect?
	
	destroyAirKillstreaksForTeam( undefined, "allies" );
	destroyAirKillstreaksForTeam( undefined, "axis" );
}

destroyAirKillstreaksForTeam( attacker, victimTeam )
{
	maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", level.heli_pilot );
	if ( IsDefined( level.lbSniper ) )
	{
		// kind of hack, but destroyTargets does a lot of needed setup
		tempArray = [];
		tempArray[0] = level.lbSniper;
		maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", tempArray );
	}
}

playRumble( rumbleType )
{
	foreach ( player in level.players )
	{
		player PlayRumbleOnEntity( rumbleType );
	}
}

/#
debugDescent()
{
	SetDvarIfUninitialized( "scr_dbg_shake_props", 0 );
	SetDvarIfUninitialized( "scr_dbg_movers", 0 );
	SetDvarIfUninitialized( "scr_dbg_building_collapse", 0 );
	SetDvarIfUninitialized( "scr_dbg_tremor_interval", 0 );
	
	while ( true )
	{
		checkDbgDvar( "scr_dbg_shake_props", undefined, "shake_props" );
		checkDbgDvar( "scr_dbg_movers", undefined, "trigger_movers" );
		checkDbgDvar( "scr_dbg_building_collapse", undefined, "buildingCollapse" );
		checkDbgDvar( "scr_desc_fx", ::dbgFireFx, undefined );
		
		wait ( 0.1 );
	}
}

checkDbgDvar( dvarName, callback, notifyStr )
{
	if ( GetDvarInt( dvarName ) > 0 )
	{
		if ( IsDefined( callback ) )
			[[ callback ]]( GetDvarInt( dvarName ) );
		
		if ( IsDefined( notifyStr ) )
			level notify( notifyStr );
		
		SetDvar( dvarName, 0 );
	}
}

dbgFireFx( fxId )
{
	exploder( fxId );
}
#/
