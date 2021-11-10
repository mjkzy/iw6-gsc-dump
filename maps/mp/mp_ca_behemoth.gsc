#include common_scripts\utility;
#include maps\mp\_utility;

main()
{
	maps\mp\mp_ca_behemoth_precache::main();
	maps\createart\mp_ca_behemoth_art::main();
	maps\mp\mp_ca_behemoth_fx::main();
	
	level.mapCustomCrateFunc = ::behemothCustomCrateFunc;
	level.mapCustomKillstreakFunc = ::behemothCustomKillstreakFunc;
	level.mapCustomBotKillstreakFunc = ::behemothCustomBotKillstreakFunc;
	
	maps\mp\_load::main();
	
//	AmbientPlay( "ambient_mp_setup_template" );
	
	//CA:SJP - Override the default minimap setup function because the 45 degree rotation
	//causes a divide by zero error in the _compass::setupMiniMap function on some platforms
	//maps\mp\_compass::setupMiniMap( "compass_map_mp_ca_behemoth" );
	behemothSetMiniMap( "compass_map_mp_ca_behemoth" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	
	setdvar("bucket", 1);
	
	setdvar_cg_ng( "r_specularColorScale", 1.4, 10.75 );
	setdvar_cg_ng( "r_diffuseColorScale", 1.72, 2.25 );
	
	if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.55" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".15" );
	}
	else if ( level.xenon )
	{
		SetDvar( "sm_sunShadowScale", "0.56" +
			    "" ); //  optimization
		SetDvar( "sm_sunsamplesizenear", ".22" );
	}
	else
	{
		SetDvar( "sm_sunShadowScale", "0.9" ); // optimization
		SetDvar( "sm_sunsamplesizenear", ".27" );
	}
	
	//dvar
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	level.steam_burst_active = 0;
	level.steam_stream_points = [];
	level.steam_burst_points = [];
	level.steam_bokeh_points = [];
	
	thread setup_burstpipes();
	thread setup_extinguishers();
	thread setup_machinery();
	thread setup_rollers();
	thread setup_movers();
	thread setup_bucketwheels();
	
	thread setup_fans();
	
	thread setup_tvs();
	
	thread maps\mp\mp_ca_killstreaks_heliGunner::init();
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
}

setup_fans()
{
	fans = GetEntArray("destruct_fan", "targetname");
	array_thread(fans, ::update_fan);
}

rotate_fan()
{
	self endon ("stop_rotate");
	
	while(1)
	{
		self RotateYaw(360, 0.5);
		wait 0.25;
	}
}

update_fan()
{
	trigger_box = GetEnt(self.target, "targetname");
	if(isDefined(trigger_box))
	{
		trigger_box setCanDamage(true);
		self thread rotate_fan();
		trigger_box waittill("damage");
		
		PlayFX(level._effect["tv_explode"], self.origin);
		playSoundAtPos(self.origin, "tv_shot_burst");
		
		self notify("stop_rotate");
		
		trigger_box SetCanDamage(false);
		
		self RotateYaw(RandomFloat(360), 1.0, 0, .75);
		
	}	
}

setup_rollers()
{
	rollers = GetEntArray("beh_roller", "targetname");
	array_thread(rollers, ::update_roller);
}

update_roller()
{
	wait_time = 6.0;
	while(1)
	{
		self RotatePitch(360,wait_time);
		wait(wait_time);
	}
}

//monitors_01
//monitors_02
//monitors_03
//monitors_04

setup_tvs()
{
	tvs = GetEntArray("beh_destruct_tv", "targetname");
	array_thread(tvs, ::update_tv);
}

update_tv()
{
	monitor_effect = "monitors_0" + RandomIntRange(1,5);
	//monitor_effect = "monitors_01";
	
	if(isDefined(level._effect[monitor_effect]))
	{
	
		forward = anglestoright( self.angles ) * 0.125;
		end = self.origin + ( forward );
		
		angles = anglesToRight(self.angles);
		origin = end + (0,0,-1);
		
		fx_ent = playLoopedFX(level._effect[monitor_effect], 0.5, origin, 1000, angles);
		
		self setCanDamage(true);
		
		self waittill("damage");

		PlayFX(level._effect["tv_explode"], self.origin);
		playSoundAtPos(self.origin, "tv_shot_burst");
		
		fx_ent Delete();
		
		self setCanDamage(false);
	}
}

BEHEMOTH_KILLSTREAK_WEIGHT = 80;

//CA:SJP - some bits copied from _compass.gsc
behemothSetMiniMap(material)
{
	corners = getentarray("minimap_corner", "targetname");
	if (corners.size != 2)
		return;
	
	corner0 = (corners[0].origin[0], corners[0].origin[1], 0);
	corner1 = (corners[1].origin[0], corners[1].origin[1], 0);
	center = corner0 + 0.5 * (corner1 - corner0);
	
	northYaw = getnorthyaw();

	// Scale the map corners to fit the bounds of the map boundaries after rotating to desired north
	scaleFactor = abs(sin(northYaw)) + abs(cos(northYaw));
	corner0 = center + scaleFactor * (corner0 - center);
	corner1 = center + scaleFactor * (corner1 - center);
	
	// Save the map size before rotating
	level.mapSize = max(abs(corner0[1] - corner1[1]), abs(corner0[0] - corner1[0]));
	
	// Rotate map boundaries
	corner0 = RotatePoint2D(corner0, center, northYaw * -1);
	corner1 = RotatePoint2D(corner1, center, northYaw * -1);
	
	north = (cos(northYaw), sin(northYaw), 0);
	west = (0 - north[1], north[0], 0);
	
	cornerdiff = VectorNormalize(corner1 - corner0);
	
	// we need the northwest and southeast corners. all we know is that corner0 is opposite of corner1.
	if (vectordot(cornerdiff, west) > 0) {
		// corner1 is further west than corner0
		if (vectordot(cornerdiff, north) > 0) {
			// corner1 is northwest, corner0 is southeast
			northwest = corner1;
			southeast = corner0;
		}
		else {
			// corner1 is southwest, corner0 is northeast
			northwest = corner1 + VectorDot(north, corner0 - corner1) * north;
			southeast = 2 * center - northwest;
		}
	}
	else {
		// corner1 is further east than corner0
		if (vectordot(cornerdiff, north) > 0) {
			// corner1 is northeast, corner0 is southwest
			northwest = corner0 + VectorDot(north, corner1 - corner0) * north;
			southeast = 2 * center - northwest;
		}
		else {
			// corner1 is southeast, corner0 is northwest
			northwest = corner0;
			southeast = corner1;
		}
	}
	
	setMiniMap(material, northwest[0], northwest[1], southeast[0], southeast[1]);
}

vecscale(vec, scalar)
{
	return (vec[0]*scalar, vec[1]*scalar, vec[2]*scalar);
}

RotatePoint2D(point, center, angle)
{
	rotated = (point[0] - center[0], point[1] - center[1], point[2]);
	rotated = RotatePointAroundVector((0,0,1), rotated, angle);
	return (rotated[0] + center[0], rotated[1] + center[1], rotated[2]);
}

// map-specific killstreak
behemothCustomCrateFunc()
{
	if(!IsDefined(game["player_holding_level_killstrek"]))
		game["player_holding_level_killstrek"] = false;
		
	if(!allowLevelKillstreaks() || game["player_holding_level_killstrek"])
		return;
	
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault",	"heli_gunner", BEHEMOTH_KILLSTREAK_WEIGHT,	maps\mp\killstreaks\_airdrop::killstreakCrateThink,	maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), maps\mp\killstreaks\_airdrop::get_enemy_crate_model(),	&"MP_CA_KILLSTREAKS_HELI_GUNNER_PICKUP" );
	maps\mp\killstreaks\_airdrop::generateMaxWeightedCrateValue();
	level thread watch_for_behemoth_crate();
	
}

behemothCustomKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/Behemoth Killstreak\" \"set scr_devgivecarepackage heli_gunner; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Behemoth Killstreak\" \"set scr_givekillstreak heli_gunner\"\n");
	
	level.killStreakFuncs[ "heli_gunner" ] = ::tryUseBehemothKillstreak;
	
}

behemothCustomBotKillstreakFunc()
{
	AddDebugCommand("devgui_cmd  \"MP/Bots(Killstreak)/Level Events:5/Behemoth Killstreak\" \"set scr_testclients_givekillstreak heli_gunner\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( "heli_gunner",	maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
}

watch_for_behemoth_crate()
{
	while(1)
	{
		level waittill("createAirDropCrate", dropCrate);

		if(IsDefined(dropCrate) && IsDefined(dropCrate.crateType) && dropCrate.crateType=="heli_gunner")
		{	
			maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "heli_gunner", 0);
			captured = wait_for_capture(dropCrate);
			
			if(!captured)
			{
				//reEnable heli_gunner care packages if it expires with out anyone picking it up
				maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "heli_gunner", BEHEMOTH_KILLSTREAK_WEIGHT);
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

tryUseBehemothKillstreak(lifeId, streakName)
{	
	// this contains all the code to run the killstreak
	return maps\mp\mp_ca_killstreaks_heliGunner::tryUseHeliGunner(lifeId, streakName);
	
}

//BUCKETWHEELS
setup_bucketwheels()
{
	buckets = getentarray("bucket_wheel", "targetname");
	if(buckets.size)
		array_thread(buckets, ::update_bucketwheel);
}

update_bucketwheel()
{
	while(1)
	{
		self RotatePitch(360, 20.0);
		wait 20.0;
	}
}

//BURSTPIPES
CONST_STEAM_SFX_END_DELAY = 0.25;
setup_burstpipes()
{
	burstpipes = getstructarray("burstpipe", "targetname");
	array_thread(burstpipes, ::setup_pipe);
}

loop_pipe_fx(fx_loc, soundEnt )
{
	up_angles = (90, 0, 0);
	// give it a slightly delay between each loop to make it feel more natural
	duration = RandomFloatRange(7.5, 8.0);
	fx_node = PlayLoopedFX(level._effect["vfx_pipe_steam_ring"], duration, fx_loc, 0.0, up_angles);
	
	soundEnt PlayLoopSound( "mtl_steam_pipe_hiss_loop" );
	
	// wait until it's notified, and kill it
	self waittill("end_fx");
	
	soundEnt PlaySound( "mtl_steam_pipe_hiss_loop_end" );
	
	wait( CONST_STEAM_SFX_END_DELAY );
	
	soundEnt StopLoopSound( "mtl_steam_pipe_hiss_loop" );
	
	fx_node Delete();
}

update_pipe_fx(fx_loc)
{
	// wait a slightly random amount of time before starting up
	wait RandomFloat(.25);
	
	// while the pipe can accept damage
	while(self.waiting)
	{
		// loop the effects and wait until a pipe is hit
		fx_loc thread loop_pipe_fx(fx_loc.origin, self.soundEnt);
		level waittill("pipe_burst_cutoff");
		// notify the looping effect to cutoff 
		fx_loc notify("end_fx");
		// and wait until it's time to restart
		level waittill("pipe_burst_restart");
	}
}

play_effects_at_loc_array(loc_array, effect_id, rand_angle)
{
	burst_angle = (0,0,0);
	foreach(loc in loc_array)
	{
		if(rand_angle)
			burst_angle = (RandomFloat(180.0), RandomFloat(180.0), RandomFloat(180.0));
		PlayFX(effect_id, loc, burst_angle);
	}		
}

setup_pipe()
{
	// one-time setup steps
	fx_locs = GetStructArray(self.target, "targetname");
	
	// add the struct node to the burst points
	level.steam_burst_points[level.steam_burst_points.size] = self.origin;
	level.steam_bokeh_points[level.steam_bokeh_points.size] = self.origin + (0,0,30.0);
	
	// add all the targeted script_structs to a list of "stream points"
	// from which a steaming steam effect will spawn
	foreach(fx_loc in fx_locs)
		level.steam_stream_points[level.steam_stream_points.size] = fx_loc.origin;
	
	self update_pipe();
}

bokeh_timer(loc)
{
	fx_node = SpawnFX(level._effect["scrnfx_water_bokeh_dots_cam_16"], loc);
	TriggerFX(fx_node);
	wait 10.0;
	fx_node Delete();
}

play_bokeh()
{
	foreach(loc in level.steam_bokeh_points)
		thread bokeh_timer(loc);
}

update_pipe()
{
	self.waiting = 1;

	// the node locations for 
	fx_locs = GetStructArray(self.target, "targetname");
	
	// if no damage models are connected to this pipe parent struct,
	// just use it for its node locations
	damage_models = GetEntArray(self.target, "targetname");
	if(damage_models.size)
	{		
		self.soundEnt = damage_models[0];
		// start listening for damage
		array_thread(damage_models, ::burstpipe_damage_watcher, self);
		
		// start up the steam rings
		foreach(loc in fx_locs)
			self thread update_pipe_fx(loc);
		
		// wait until we're damaged, then notify all the steam rings to cutoff
		self waittill("burstpipe_damage");
		
		self.soundEnt PlaySound( "mtl_steam_pipe_hit" );
		
		level notify("pipe_burst_cutoff");
		
		// start playing the streams first before firing off the bursts
		thread play_effects_at_loc_array(level.steam_stream_points, level._effect["vfx_pipe_steam_stream"], 1);
		
		wait 0.5;
		
		thread play_bokeh();
		thread play_effects_at_loc_array(level.steam_burst_points, level._effect["vfx_pipe_steam_burst"], 1);
		
		
		// for all the other pipes to communicate with each other
		level.steam_burst_active = 1;
		
		self.soundEnt PlayLoopSound( "mtl_steam_pipe_hiss_loop" );
		
		// wait until it's all faded out, then notify all other pipes
		wait 10.0 - CONST_STEAM_SFX_END_DELAY;
		
		self.soundEnt PlaySound( "mtl_steam_pipe_hiss_loop_end" );
		
		wait( CONST_STEAM_SFX_END_DELAY );
		
		damage_models[0] StopLoopSound( "mtl_steam_pipe_hiss_loop" );
		
		level.steam_burst_active = 0;
		
		level notify("pipe_burst_restart");
		
		self.waiting = 0;
		
		// restart the pipe after a certain amount of time
		wait 120.0;
		
		// but don't restart it until the steamburst is inactive
		while(level.steam_burst_active)
		{
			wait 0.5;
		}
		self update_pipe();
	}
}

burstpipe_damage_watcher(struct)
{
	self SetCanDamage(true);
	while(struct.waiting)
	{
		self waittill( "damage", amount, attacker, direction_vec, point, type );
		// if it's damaged while the pipe is waiting to be damaged, make sure another
		// burst isn't already happening
		if(!level.steam_burst_active)
			struct notify("burstpipe_damage", direction_vec, point);	
	}
	self SetCanDamage(false);
}

//fire extinguishers
setup_extinguishers()
{
	extinguishers = GetEntArray("extinguisher", "targetname");
	array_thread(extinguishers, ::update_extinguisher);
}

update_extinguisher()
{
	self SetCanDamage(true);
	damaged = false;

	// wait until it's damaged by melee, grenade, or bullet	
	while(!damaged)
	{
		// this will only play its FX once and never again
		self waittill( "damage", amount, attacker, direction_vec, hit_point, damage_type);
		
		if ( IsSubStr( damage_type, "MELEE") || IsSubStr( damage_type, "BULLET" ))
		{
			self SetCanDamage(false);
			// point toward the player
			PlayFX(level._effect["vfx_fire_extinguisher"], hit_point, RotateVector(direction_vec, (0, 180.0, 0.0)));
			playSoundAtPos(self.origin, "extinguisher_break");
			damaged = true;
		}
		else
		{
			self SetCanDamage(false);
			PlayFX(level._effect["vfx_fire_extinguisher"], self.origin, AnglesToUp(self.angles));
			playSoundAtPos(self.origin, "extinguisher_break");
		}
	}
}

play_hit( effect_id, spawn_point, spawn_dir)
{
	vfx_ent = SpawnFx( effect_id, spawn_point, AnglesToForward( spawn_dir ), AnglesToUp( spawn_dir ) );
	TriggerFX( vfx_ent );
	wait 5.0;
	vfx_ent Delete();
}

#using_animtree( "mp_ca_behemoth" );
setup_machinery()
{
	machines = GetEntArray("machinery", "targetname");
	array_thread(machines, ::update_machine);
}

update_machine()
{
	anim_time = 10.0;
	play_anim = "";
	go = 1;
	if(isDefined(self.script_noteworthy))
	{
		if(self.script_noteworthy == "center")
		{
			anim_time = GetAnimLength( %mp_ca_beh_center_machine_idle );
			play_anim = "mp_ca_beh_center_machine_idle";
		}
		else if(self.script_noteworthy == "left")
		{
			anim_time = GetAnimLength( %mp_ca_beh_engine_a_idle );
			play_anim = "mp_ca_beh_engine_a_idle";
		}
		else if(self.script_noteworthy == "right")
		{
			anim_time = GetAnimLength( %mp_ca_beh_engine_b_idle );
			play_anim = "mp_ca_beh_engine_b_idle";
		}
		
		if(anim_time)
		{
			while(go)
			{
				self ScriptModelPlayAnim(play_anim);
				wait anim_time;
			}
		}
	}
}

setup_movers()
{
	movers = GetEntArray("mover", "targetname");
	array_thread(movers, ::update_mover);
}

setup_mover_nodes()
{
	next_point = GetStruct(self.target, "targetname");
	if(IsDefined(next_point))
	{		
		self.angles = VectorToAngles(self.origin - next_point.origin);
		good_to_go = 1;
		while((next_point != self) && (good_to_go))
		{
			curr_point = next_point;
			next_point = GetStruct(curr_point.target, "targetname");
			if(IsDefined(next_point))
			{
				next_point.angles = VectorToAngles(next_point.origin - curr_point.origin);
			}
			else
				good_to_go = 0;
		}
		
	}
}

update_mover()
{	
	
	current_point = GetStruct( self.target, "targetname" );
	if ( !IsDefined( current_point ) )
		return;

	// blocking so as to make sure all the angles are set up before launching
	current_point setup_mover_nodes();
	
	self.origin = current_point.origin;
	self.angles = current_point.angles;
	
	self.enabled = true;
	
	default_speed = 140.0;
	stop_time = 0.0;
	start_time = 0.0;
	if ( IsDefined( current_point.script_accel ) )
		start_time = current_point.script_accel;

	current_point = GetStruct( current_point.target, "targetname" );
	while ( IsDefined( current_point ) )
	{
		
		stop_time = 0.0;
		if ( IsDefined( current_point.script_decel ) )
			stop_time = current_point.script_decel;
		
		move_speed = default_speed;
		//move_speed /= Max( 1, GetDvarInt( "self_throttle", 1 ) );

		if ( IsDefined( current_point.script_physics ) )
			move_speed *= current_point.script_physics;
		move_time = Distance( self.origin, current_point.origin ) / move_speed;
		move_time = Max( move_time, stop_time + start_time );
		
		self MoveTo( current_point.origin, move_time, start_time, stop_time );
		self RotateTo( current_point.angles, move_time, start_time, stop_time );
		
		point_angle = current_point.angles[1];
		
		wait move_time - (start_time + stop_time);

		if ( IsDefined( current_point.script_node_pausetime ) )
			wait current_point.script_node_pausetime;

		start_time = 0.0;
		if ( IsDefined( current_point.script_accel ) )
			start_time = current_point.script_accel;
		
		current_point = GetStruct( current_point.target, "targetname" );
	}
}
