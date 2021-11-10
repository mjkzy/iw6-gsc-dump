#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_sovereign_precache::main();
	maps\createart\mp_sovereign_art::main();
	maps\mp\mp_sovereign_fx::main();
	
	level thread walkway_collapse(); //Before load::main so it can be seen in createfx
	level thread maps\mp\mp_sovereign_events::assembly_line_precache();
	level thread maps\mp\_movable_cover::init();
	
	level.mapCustomCrateFunc = ::sovereignCustomCrateFunc;
	level.mapCustomKillstreakFunc = ::sovereignCustomKillstreakFunc;
	level.mapCustomBotKillstreakFunc = ::sovereignCustomBotKillstreakFunc;
	
	maps\mp\_load::main();
	
	thread maps\mp\_fx::func_glass_handler(); // Text on glass
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_sovereign" );
	
  if( ( level.ps3 ) || ( level.xenon ) )
	{
		setdvar( "sm_sunShadowScale", "0.5" ); // optimization
	}

	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	SetDvar("r_sky_fog_intensity","1");
	SetDvar("r_sky_fog_min_angle","60");
	SetDvar("r_sky_fog_max_angle","85");
	
	SetDvar( "r_ssaofadedepth", 1200 );
	setdvar_cg_ng( "r_specularColorScale", 3.5, 5 );	
  	setdvar_cg_ng( "r_diffuseColorScale", 1.5, 1.2 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";

	level thread maps\mp\mp_sovereign_events::assembly_line();
	level thread maps\mp\mp_sovereign_events::halon_system();
		
	level thread robot_arm();
	level thread malfunctioning_crane();
	level thread update_bot_maxsightdistsqrd();
}

update_bot_maxsightdistsqrd()
{
	halon_maxsightdists = 1200;
	halon_maxsightdistssqrd = halon_maxsightdists*halon_maxsightdists;
	
	while(!IsDefined(level.participants))
		waitframe();
	
	while(1)
	{
		players_in_fog = [];
		foreach(participant in level.participants)
		{
			if(!IsPlayer(participant))
				continue;
			
			in_fog = level.halon_fog_on && (participant GetEye())[2]<280;
			if(in_fog)
			{
				players_in_fog[players_in_fog.size] = participant;
			}
			
			
			if(isBot(participant))
			{
				if(!IsDefined(participant.default_maxsightdistsqrd))
					participant.default_maxsightdistsqrd = participant.maxsightdistsqrd;
				
				if(in_fog)
				{
					participant.maxsightdistsqrd = halon_maxsightdistssqrd;
				}
				else
				{
					participant.maxsightdistsqrd = participant.default_maxsightdistsqrd;
				}
			}
		}
		
		if(players_in_fog.size)
		{
			//Screen fx exploder
			exploder(39, players_in_fog);
		}
		
		wait .5;
	}
}

is_dynamic_path()
{
	return IsDefined(self.spawnflags) && self.spawnflags&1;
}

is_ai_sight_line()
{
	return IsDefined(self.spawnflags) && self.spawnflags&2;
}

#using_animtree("animated_props");
walkway_collapse()
{
	flag_init("walkway_collasped");
	
	if ( getdvar( "r_reflectionProbeGenerate" ) == "1" )
		return;
	
	PrecacheMpAnim("mp_sovereign_walkway_collapse_top");
	PrecacheMpAnim("mp_sovereign_walkway_collapse_bottom");
	PrecacheMpAnim("mp_sovereign_walkway_collapse_top_idle");
	PrecacheMpAnim("mp_sovereign_walkway_collapse_bottom_idle");

	waitframe(); //Allow structs to be init
	
	collapse_top_length = GetAnimLength(  %mp_sovereign_walkway_collapse_top );
	collapse_bottom_length = GetAnimLength(  %mp_sovereign_walkway_collapse_bottom );
	
	swap_time = GetNotetrackTimes( %mp_sovereign_walkway_collapse_top, "bottom_anim_begin")[0];
	swap_time *= collapse_top_length;
	
	walkway_trigger_damage = GetEnt("walkway_trigger_damage", "targetname");

	animated_walkway_tank 	= GetEnt("walkway_tank_animated", "targetname");
	animated_walkway_tank ScriptModelPlayAnimDeltaMotion("mp_sovereign_walkway_collapse_top_idle");
	if(IsDefined(animated_walkway_tank.target))
	{
		animated_walkway_tank.clip = GetEnt(animated_walkway_tank.target, "targetname");
		if(IsDefined(animated_walkway_tank.clip))
		{
			animated_walkway_tank.clip LinkTo(animated_walkway_tank, "j_canister_main");
			
			killcam_ent = spawn("script_model", (568, -722, 568));
			animated_walkway_tank.clip.killCamEnt = killcam_ent;
		}
	}
	//walkway_tank_end = GetEnt("walkway_tank_end", "targetname");
	//walkway_tank_end Hide();
	
	walkway_clip_end = GetEntArray("walkway_clip_end", "targetname");
	array_thread(walkway_clip_end, ::walkway_collapse_clip_hide);
	
	walkway_tank_trigger_hurt = GetEnt("walkway_tank_trigger_hurt", "targetname");
	if(IsDefined(walkway_tank_trigger_hurt))
	{
		//walkway_tank_trigger_hurt EnableLinkTo();
		//walkway_tank_trigger_hurt LinkTo(animated_walkway_tank, "j_canister_main");
		walkway_tank_trigger_hurt Delete();
	}
	
	animated_walkway = GetEnt("walkway_animated", "targetname");
	animated_walkway ScriptModelPlayAnimDeltaMotion("mp_sovereign_walkway_collapse_bottom_idle");
	animated_walkway Hide();
	
	walkway_non_destroyed = walkway_collapse_group("walkway_non_destroyed");
	walkway_destroyed = walkway_collapse_group("walkway_destroyed");
	walkway_destroyed walkway_collapse_hide();
	
	walkway_tank_fx = [];
	hose1_start_notetracks = GetNotetrackTimes( %mp_sovereign_walkway_collapse_top, "hose1_start");
	hose2_start_notetracks = GetNotetrackTimes( %mp_sovereign_walkway_collapse_top, "hose2_start");
	hose3_start_notetracks = GetNotetrackTimes( %mp_sovereign_walkway_collapse_top, "hose3_start");
	
	if(hose1_start_notetracks.size>0)
	{
		hose1_start = hose1_start_notetracks[0] * collapse_top_length;
		hose2_start = hose2_start_notetracks[0] * collapse_top_length;
		hose3_start = hose3_start_notetracks[0] * collapse_top_length;
		
		walkway_tank_fx[0] = ["tag_fx_canister_1",		"vfx_can_afterleak", 	hose1_start];
		walkway_tank_fx[1] = ["tag_fx_canister_2",		"vfx_can_afterleak", 	hose2_start];
		walkway_tank_fx[2] = ["tag_fx_canister_3",		"vfx_can_afterleak", 	hose3_start];
		walkway_tank_fx[3] = ["tag_fx_cables_1",		"vfx_can_jet", 			hose1_start];
		walkway_tank_fx[4] = ["tag_fx_cables_2",		"vfx_can_jet", 			hose2_start];
		walkway_tank_fx[5] = ["tag_fx_cables_3",		"vfx_can_jet", 			hose3_start];
	}
	while(1)
	{
		activate_player = walkway_wait(walkway_trigger_damage);
		
		flag_set("walkway_collasped");
		exploder(2);
		animated_walkway_tank.clip PlaySoundOnMovingEnt("scn_catwalk_break_away");
		noself_delayCall(swap_time, ::playSoundAtPos, (136, -412, 360), "scn_catwalk_impact");
		noself_delayCall(4.13, ::playSoundAtPos, (242, -326, 322), "scn_catwalk_steam_burst1" );
		noself_delayCall(4.46, ::playSoundAtPos, (277, -283, 256), "scn_catwalk_steam_burst2");
		animated_walkway_tank ScriptModelPlayAnimDeltaMotion("mp_sovereign_walkway_collapse_top");
		foreach(fx_set in walkway_tank_fx)
			thread walkway_play_fx(fx_set[2], animated_walkway_tank, fx_set[1], fx_set[0]);
		//walkway_tank_trigger_hurt thread walkway_collapse_hurt_trigger();
		
		level delayThread(swap_time, ::exploder, 3);
		animated_walkway delayCall(swap_time, ::Show);
		animated_walkway delayCall(swap_time, ::ScriptModelPlayAnimDeltaMotion, "mp_sovereign_walkway_collapse_bottom");
		walkway_non_destroyed delayThread(swap_time, ::walkway_collapse_hide);
		array_thread(walkway_clip_end, ::delayThread, swap_time, ::walkway_collapse_clip_show);
		
		//walkway_tank_trigger_hurt delayThread( swap_time+collapse_bottom_length, ::walkway_collapse_hurt_trigger_stop);
		walkway_destroyed delayThread(swap_time+collapse_bottom_length, ::walkway_collapse_show);

		if(IsDefined(animated_walkway_tank.clip))
		{
			animated_walkway_tank.clip thread maps\mp\_movers::player_pushed_kill(0);
			animated_walkway_tank.clip delayThread(swap_time+collapse_bottom_length, ::walkway_collapse_clip_hide );
			animated_walkway_tank.clip.unresolved_collision_kill = true;
			animated_walkway_tank.clip.unresolved_collision_notify_min = 1;
			animated_walkway_tank.clip.owner = activate_player;
		}
		
		wait swap_time+collapse_bottom_length;
		
		if(IsDefined(animated_walkway_tank.clip))
		{
			animated_walkway_tank.clip maps\mp\_movers::stop_player_pushed_kill();
			animated_walkway_tank.clip.unresolved_collision_kill = false;
			animated_walkway_tank.clip.unresolved_collision_notify_min = undefined;
			animated_walkway_tank.clip.owner = undefined;
		}
		walkway_wait();
		
		flag_clear("walkway_collasped");
		animated_walkway_tank Show();
		animated_walkway ScriptModelPlayAnimDeltaMotion("mp_sovereign_walkway_collapse_bottom_idle");
		//walkway_tank_end Hide();	
		animated_walkway Hide();
		array_thread(walkway_clip_end, ::walkway_collapse_clip_hide);
		walkway_non_destroyed walkway_collapse_show();
		walkway_destroyed walkway_collapse_hide();
		if(IsDefined(animated_walkway_tank.clip))
		{
			animated_walkway_tank.clip walkway_collapse_clip_show();
		}
		
		wait 1; //TODO: Don't know why I need a wait here to make this anim play. and waitframe() is not enough
		animated_walkway_tank ScriptModelPlayAnimDeltaMotion("mp_sovereign_walkway_collapse_top_idle");
	}
}

walkway_play_fx(delay, model, fx_name, joint)
{
	wait delay;
	PlayFXOnTag(level._effect[ fx_name ], model, joint);
}

walkway_collapse_hurt_trigger_stop()
{
	self notify("stop_walkway_collapse_hurt_trigger");
}

walkway_collapse_hurt_trigger(activate_player)
{
	self endon("stop_walkway_collapse_hurt_trigger");
	
	while(1)
	{
		self waittill("trigger", player);
		if ( isPlayer( player ) )
		{
			player DoDamage( 1000, player.origin );
		}
	}
}
	
walkway_wait(trigger)
{
	level thread walkway_wait_dvar();
	if(IsDefined(trigger))
		level thread walkway_wait_trigger(trigger);
	
	level waittill("activate_walkway", player);
	return player;
}

walkway_wait_trigger(trigger)
{
	level endon("activate_walkway");
	trigger waittill("trigger", attacker);
	level notify("activate_walkway",attacker);
}

walkway_wait_dvar()
{
	level endon("activate_walkway");
	SetDevDvarIfUninitialized("trigger_walkway", "0");
	while(GetDvarInt("trigger_walkway")==0)
		wait .05;
	SetDevDvar("trigger_walkway", "0");
	
	level notify("activate_walkway");
}

walkway_collapse_hide()
{
	if(isDefined(self.walkway_collapse_hide) && self.walkway_collapse_hide)
		return;
	
	self.walkway_collapse_hide = true;
	self.origin -= (0,0,1000);
	
	foreach(ent in self.clip)
	{
		ent walkway_collapse_clip_hide();
	}
	
	self DontInterpolate();
	
	foreach(node in self.traverse_nodes)
	{
		DisconnectNodePair(node, node.connected_to);
	}
	
	foreach(node in self.nodes)
	{
		node DisconnectNode();
	}
}

walkway_collapse_clip_hide()
{
	if(self is_dynamic_path())
		self ConnectPaths();
	
	if(self is_ai_sight_line())
		self SetAISightLineVisible(false);
	
	self.old_contents = self SetContents(0);
	self NotSolid();
	self Hide();
}

walkway_collapse_show()
{
	if(isDefined(self.walkway_collapse_hide) && !self.walkway_collapse_hide)
		return;
	
	self.walkway_collapse_hide = false;
	self.origin += (0,0,1000);
	
	foreach(ent in self.clip)
	{
		ent walkway_collapse_clip_show();
	}
	self DontInterpolate();
	
	foreach(node in self.traverse_nodes)
	{
		ConnectNodePair(node, node.connected_to);
	}
	
	foreach(node in self.nodes)
	{
		node ConnectNode();
	}
}

walkway_collapse_clip_show()
{
	self Solid();
	self SetContents(self.old_contents);
	self Show();
	
	if(self is_dynamic_path())
		self DisconnectPaths();
	
	if(self is_ai_sight_line())
		self SetAISightLineVisible(true);
}

walkway_collapse_group(targetname)
{
	struct = GetStruct(targetname, "targetname");
	if(!IsDefined(struct))
		return undefined;
	
	parent = Spawn("script_model", struct.origin);
	parent SetModel("tag_origin");
	
	parent.clip = [];
	parent.linked = [];
	
	ents = struct get_linked_ents();
	foreach(ent in ents)
	{
		if(ent.classname == "script_brushmodel")
		{
			parent.clip[parent.clip.size] = ent;
		}
		else
		{
			parent.linked[parent.linked.size] = ent;
			ent LinkTo(parent);
			//ent WillNeverChange();
		}
	}
	
	
	nodes = struct getLinkNameNodes();
	parent.traverse_nodes = [];
	parent.nodes = [];
	foreach(node in nodes)
	{
		if(IsDefined(node.targetname) && node.targetname == "traverse")
		{
			node.connected_to = GetNode(node.target, "targetname");
			parent.traverse_nodes[parent.traverse_nodes.size] = node;
		}
		else
		{
			parent.nodes[parent.nodes.size] = node;
		}
		
	}

	return parent;
}

#using_animtree("animated_props");
malfunctioning_crane()
{
	arm = GetEnt("malfunctioning_crane_arm","targetname");
	arm_clip = GetEnt("malfunctioning_crane_arm_clip","targetname");
	
	anim_length = GetAnimLength( %mp_sovereign_malfunctioning_crane_arm );
	
	if( !IsDefined(arm) )
		return;

	if(IsDefined(arm_clip))
	{
		arm_clip EnableLinkTo();
		arm_clip LinkTo(arm, "basetwist_jnt", (0,0,0), (180,0,0));
	}
	
	sound_ent = spawn("script_model", arm.origin);
	sound_ent SetModel("tag_origin");
	sound_ent LinkTo(arm, "basetwist_jnt");
	
	
	arm ScriptModelPlayAnimDeltaMotion("mp_sovereign_malfunctioning_crane_arm");
	
	while(1)
	{
		sound_ent PlaySoundOnMovingEnt("scn_sov_yellow_crane");
		wait anim_length;
	}
}

robot_arm()
{
	robot_arm_anim = "mp_sovereign_robot_arm_malfunction";
	PrecacheMpAnim(robot_arm_anim);
	
	waitframe(); //Allow Struct to init
	
	//This function makes assumptions about the robot arm moving axis aligned and
	//that the track moves N/S and the arm moves E/W
	robot_arm = GetEnt("robot_arm", "targetname");
	if(!IsDefined(robot_arm))
		return;
	
	if(IsDefined(robot_arm.target))
	{
		clip = GetEnt(robot_arm.target, "targetname");
		clip LinkTo(robot_arm, "j_anim_001");
	}
	
	robot_arm_parent = spawn("script_model", robot_arm.origin);
	robot_arm_parent SetModel("tag_origin");
	robot_arm_parent.angles = robot_arm.angles;
	
	robot_arm LinkTo(robot_arm_parent);
	
	robot_arm.ends = [];
	links = robot_arm get_links();
	foreach(link in links)
	{
		end = getstruct(link, "script_linkname");
		robot_arm.ends[robot_arm.ends.size] = end;
	}
	
	robot_arm_top = GetEnt("robot_arm_top", "targetname");
	robot_arm_top LinkTo(robot_arm_parent);
	
	robot_track = GetEnt("robot_arm_track", "targetname");
	
	robot_track.ends = [];
	links = robot_track get_links();
	foreach(link in links)
	{
		end = getstruct(link, "script_linkname");
		robot_track.ends[robot_track.ends.size] = end;
	}
	
	robot_x_min = min(robot_arm.ends[0].origin[0], robot_arm.ends[1].origin[0]);
	robot_x_max = max(robot_arm.ends[0].origin[0], robot_arm.ends[1].origin[0]);
	robot_y_min = min(robot_track.ends[0].origin[1], robot_track.ends[1].origin[1]);
	robot_y_max = max(robot_track.ends[0].origin[1], robot_track.ends[1].origin[1]);
	
	robot_mins = (robot_x_min, robot_y_min, 0);
	robot_maxs = (robot_x_max, robot_y_max, 0);
	
	corners = getStructArray("robot_arm_corner", "targetname");
	map_x_min = min(corners[0].origin[0], corners[1].origin[0]);
	map_x_max = max(corners[0].origin[0], corners[1].origin[0]);
	map_y_min = min(corners[0].origin[1], corners[1].origin[1]);
	map_y_max = max(corners[0].origin[1], corners[1].origin[1]);
	
	map_mins = (map_x_min, map_y_min, 0);
	map_maxs = (map_x_max, map_y_max, 0);
	
	robot_arm PlayLoopSound("scn_sov_single_robot_arm_lp");
	robot_arm ScriptModelPlayAnimDeltaMotion(robot_arm_anim);
	
	move_speed = 80;
	while(1)
	{
		topPlayer = maps\mp\gametypes\_gamescore::getHighestScoringPlayer();
		if(IsDefined(topPlayer))
		{
			new_pos = robot_arm_get_scaled_position(robot_mins, robot_maxs, map_mins, map_maxs, topPlayer.origin);
			new_pos_arm = (new_pos[0], new_pos[1], robot_arm.origin[2]);
			new_pos_track = (robot_track.origin[0], new_pos[1], robot_track.origin[2]);
			
			dist = Distance(robot_arm.origin, new_pos_arm);
			if(dist>10)
			{
				new_yaw = VectorToYaw(topPlayer.origin - robot_arm.origin);
				
				move_time = dist/move_speed;
				robot_arm_parent MoveTo(new_pos_arm, move_time);
				robot_arm_parent RotateTo((robot_arm.angles[0], new_yaw, robot_arm.angles[2]), move_time/2);
				robot_track MoveTo(new_pos_track, move_time);
				wait max(move_time, 6);
				continue;
			}
		}
		wait 3;
	}
}

robot_arm_get_scaled_position(robot_mins, robot_maxs, map_mins, map_maxs, pos)
{
	robot_size = robot_maxs - robot_mins;
	map_size = map_maxs - map_mins;
	map_size = (map_size[0], map_size[1], 1); //Avoid divide by zero
	
	scale = (pos - map_mins)/map_size;	
	scale = (clamp(scale[0],0,1), clamp(scale[1],0,1),0);
	
	return (robot_size*scale) + robot_mins;
}

SOVEREIGN_GAS_WEIGHT = 55;
sovereignCustomCrateFunc()
{
	if(!IsDefined(game["player_holding_level_killstrek"]))
		game["player_holding_level_killstrek"] = false;
	
	allow_level_killstreak = level.gametype!="sotf" && level.gametype!="infect" && level.gametype!="horde";
	if(!allow_level_killstreak || game["player_holding_level_killstrek"])
		return;
	
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault",	"sovereign_gas",	SOVEREIGN_GAS_WEIGHT,	maps\mp\killstreaks\_airdrop::killstreakCrateThink,	maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), maps\mp\killstreaks\_airdrop::get_enemy_crate_model(), &"KILLSTREAKS_HINTS_SOVEREIGN_GAS" );
	level thread watch_for_sovereign_gas_crate();
}

watch_for_sovereign_gas_crate()
{
	while(1)
	{
		level waittill("createAirDropCrate", dropCrate);

		if(IsDefined(dropCrate) && IsDefined(dropCrate.crateType) && dropCrate.crateType=="sovereign_gas")
		{	
			disable_sovereign_gas();
			captured = wait_for_capture(dropCrate);
			
			if(!captured)
			{
				//reEnable Soveign Gas care packages if it expires with out anyone picking it up
				maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "sovereign_gas", SOVEREIGN_GAS_WEIGHT);
			}
			else
			{
				//Once its picked up it needs to remain off.
				game["player_holding_level_killstrek"] = true;
				break;
			}
		}
	}
}

//death and capture are sent on the same frame but death is processed first :(
wait_for_capture(dropCrate)
{
	result = watch_for_air_drop_death(dropCrate);
	return !IsDefined(result); //If !isdefined the captured notify was also sent.
}

watch_for_air_drop_death(dropCrate)
{
	dropCrate endon("captured");
	
	dropCrate waittill("death");
	waittillframeend;
	
	return true;
}

disable_sovereign_gas()
{
	maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "sovereign_gas", 0);
}

sovereignCustomKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/Sovereign Gas\" \"set scr_devgivecarepackage sovereign_gas; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Sovereign Gas\" \"set scr_givekillstreak sovereign_gas\"\n");
	
	level.killStreakFuncs[ "sovereign_gas" ] 	= ::tryUseSovereignGas;
	
	level.killstreakWeildWeapons["sovereign_gas_mp"] ="sovereign_gas";
}

sovereignCustomBotKillstreakFunc()
{
	AddDebugCommand("devgui_cmd  \"MP/Bots(Killstreak)/Level Events:5/Sovereign Gas\" \"set scr_testclients_givekillstreak sovereign_gas\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( "sovereign_gas", maps\mp\bots\_bots_ks::bot_killstreak_simple_use, maps\mp\mp_sovereign_events::bot_clear_of_gas );
}

tryUseSovereignGas(lifeId, streakName)
{
	game["player_holding_level_killstrek"] = false;
	level notify("sovereign_gas_killstreak", self);
	
	return true;
}
