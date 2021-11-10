#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_chasm_precache::main();
	maps\createart\mp_chasm_art::main();
	maps\mp\mp_chasm_fx::main();
	
	level thread maps\mp\_movers::main();
	maps\mp\_movers::script_mover_add_parameters("falling_elevator", "delay_till_trigger=1");
	maps\mp\_movers::script_mover_add_parameters("falling_elevator_cables", "delay_till_trigger=1");
	maps\mp\_movers::script_mover_add_parameters("elevator_drop_1", "move_time=.7;accel_time=.7");
	maps\mp\_movers::script_mover_add_parameters("elevator_drop_2", "move_time=1.2;accel_time=1.2;name=elevator_end");
	
	maps\mp\_load::main();
	thread maps\mp\_fx::func_glass_handler();
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_chasm" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	//   			dvar_name 		      current_gen_val    next_gen_val   
	setdvar_cg_ng( "r_specularColorScale", 2.5				  	, 5 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	if ( level.gametype == "sd" 
		|| level.gameType == "sr" )
	{
		level.srKillCamOverridePosition = [];
		level.srKillCamOverridePosition["_b"] = (384, 278, 1716);
	}
	
	level thread falling_elevator();
	level thread setupBus();
	level thread initExtraCollision();
}

initExtraCollision()
{
	gryphonTrig1Ent = spawn( "trigger_radius", (-2304, -3072, 512), 0, 1024, 2048 );
	gryphonTrig1Ent.radius = 1024;
	gryphonTrig1Ent.height = 2048;
	gryphonTrig1Ent.angles = (0,0,0);
	gryphonTrig1Ent.targetname = "remote_heli_range";
	
	collision1 = GetEnt( "clip256x256x8", "targetname" );
	collision1Ent = spawn( "script_model", (-1216, 2112, 1376) );
	collision1Ent.angles = ( 0, 0, 0);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
	
	placeableBarrier = spawn( "script_model", (-2304, -936, 1492) );
	placeableBarrier setModel( "placeable_barrier" );
	placeableBarrier.angles = (0,0,12);
	
	collision2 = GetEnt( "clip32x32x32", "targetname" );
	collision2Ent = spawn( "script_model", (-1438, -1424, 1030) );
	collision2Ent.angles = ( 0, 0, 0);
	collision2Ent CloneBrushmodelToScriptmodel( collision2 );
}

BUS_FALL_DELAY = 1.0;
setupBus()
{
	bus = GetEnt( "falling_bus", "targetname" );
	busCol = GetEnt( "bus_collision", "targetname" );
	bus.collision = busCol;
	
	busInterior = GetEntArray( "falling_bus_parts", "targetname" );
	
	foreach ( item in busInterior )
	{
		item LinkTo( bus );
	}
	bus.unresolved_collision_func = maps\mp\_movers::unresolved_collision_void;
	
	bus thread explosive_damage_watch( bus, "bus_start_fall" );
	if ( IsDefined( busCol ) )
	{
		busCol LinkTo( bus );
		bus thread explosive_damage_watch( busCol, "bus_start_fall" );
	}
	
	// get the positions
	ent = bus;
	ent.keyframes = [];
	keyframeName = ent.target;
	i = 0;
	while ( IsDefined( keyframeName ) )
	{
		struct = getstruct( keyframeName, "targetname" );
		if ( IsDefined( struct ) )
		{
			ent.keyframes[i] = struct;
			
			i++;
			keyframeName = struct.target;
		}
		else
		{
			break;
		}
	}
	
	if ( ent.keyframes.size > 2 )
	{
		// !!! this is also a hack, but a quick way to tune
		// start falling
		ent.keyframes[1].script_duration = 0.75;
		ent.keyframes[1].script_accel = 0.75;
		ent.keyframes[1].script_decel = 0;
		ent.keyframes[1].shakeMag = .5;
		ent.keyframes[1].shakeDuration = 1.5;
		ent.keyframes[1].shakeDistance = 1000;
		
		// tip over the edge
		ent.keyframes[2].script_duration = 4.0;
		ent.keyframes[2].script_accel = 0.0;
		ent.keyframes[2].script_decel = 0;
	}
	
	bus.pathBlocker = GetEnt( "pathBlocker", "targetname" );
	wait(0.05);
	bus.pathBlocker elevatorClearPath();
	
	bus thread moverDoMove( "bus_start_fall" );
}

moverDoMove( waitString )	// self == mover entity
{
	level endon ( "game_ended" );
	
	self waittill( waitString, attacker );
	
	self PlaySound( "scn_bus_groan" );
	
	// Earthquake( 0.15, 1.5, self.origin, 1500 );
	self.pathBlocker elevatorBlockPath();
	
	self busSlidingEffect();
	
	self.collision killLinkedEntities( attacker );
	
	for ( i = 1 ; i < self.keyframes.size; i++ )
	{
		kf = self.keyframes[i];
		
		self MoveTo( kf.origin, kf.script_duration, kf.script_accel, kf.script_decel );
		self RotateTo( kf.angles, kf.script_duration, kf.script_accel, kf.script_decel );
		
		if ( IsDefined( kf.shakeMag ) )
		{
			Earthquake( kf.shakeMag, kf.shakeDuration, self.origin, kf.shakeDistance );
		}
		
		self waittill( "movedone" );
	}
	
	// play another sound?
	
	// shake?
	fakeBusPos = self.origin + (0, 0, 2000);
	
	Earthquake( 0.25, .5, fakeBusPos, 3000 );
	
	StopFXOnTag( getFx("vfx_bus_fall_dust"), self.busDust, "tag_origin" );
	self.busDust Delete();
	
	PlaySoundAtPos(fakeBusPos, "scn_bus_crash");
}

busSlidingEffect()	// self = bus
{
	// wait (BUS_FALL_DELAY);
	
	busDust = GetEnt( "busDustEffect2", "targetname" );
	busDust SetModel( "tag_origin" );
	busDust LinkTo( self );
	PlayFXOnTag( getfx( "vfx_bus_fall_dust" ), busDust, "tag_origin" );
	self.busDust = busDust;
	
	// find the entity
	scrapeDustLoc = GetEnt( "busDustEffect", "targetname" );
	if ( IsDefined( scrapeDustLoc ) )
	{
		PlayFX( getFX( "vfx_bus_scrape_dust"), scrapeDustLoc.origin, AnglesToForward( scrapeDustLoc.angles ) );
		scrapeDustLoc PlaySound( "scn_bus_slide" );
	}
}

killLinkedEntities( attacker )	// self == collision
{
	linkedObjs = self GetLinkedChildren();
	foreach ( obj in linkedObjs )
	{
		if ( IsDefined( obj.owner ) )
		{
			// not sure what the inflictor should be
			obj DoDamage( 1000, self.origin, attacker, self, "MOD_CRUSH" );
		}
	}
}

falling_elevator()
{
	elevator = GetEnt("falling_elevator", "targetname");
	cables = GetEnt("falling_elevator_cables", "targetname");
	
	elevatorPathBlocker1 = GetEnt( "elevatorBlockPaths1", "targetname" );
	elevatorPathBlocker1 elevatorBlockPath();
	
	if(!IsDefined(elevator) || !IsDefined(cables))
		return;
	
	while(!IsDefined(elevator.linked_ents))
		wait .05;
	
	elevator.state = 1;
	
	// Set up damage watchers
	elevator thread falling_elevator_cables(cables);
	elevator thread explosive_damage_watch(elevator, "next_stage");
	foreach(ent in elevator.linked_ents)
	{
		elevator thread explosive_damage_watch(ent, "next_stage"); 
	}
	
	cablePos = cables.origin;
	
	// wait a little for the second blocker--doesn't seem to be catching
	wait ( 0.05 );
	elevatorPathBlocker2 = GetEnt( "elevatorBlockPaths2", "targetname" );
	elevatorPathBlocker2 elevatorClearPath();
	elevatorPathBlocker2 SetContents(0);	// so that dogs don't actually hit these things
	
	// connect effect emmiters
	elevator.dustEffect = GetEntArray( "dustEffect", "targetname" );
	foreach (ent in elevator.dustEffect)
	{
		ent LinkTo( cables );
	}
	elevator.sparkEffect = GetEntArray( "sparkEffect", "targetname" );
	foreach (ent in elevator.sparkEffect)
	{
		ent LinkTo( cables );
	}
	
	while(1)
	{
		elevator waittill("next_stage", attacker );
		
		if(elevator.moving)
			continue;
		
		elevator.state++;
		
		elevator notify("trigger"); //Move to next state
		if(IsDefined(cables))
			cables notify("trigger");
		
		// start falling
		if (elevator.state == 2)
		{
			elevator PlaySoundOnMovingEnt( "scn_elevator_fall_move" );
			cables notify( "stop_watching_cable" );
			elevatorPathBlocker1 elevatorClearPath();
			elevatorPathBlocker1 SetContents(0);	// so that dogs don't actually hit these things
			//elevator maps\mp\_movers::notify_moving_platform_invalid(); (this line stops the elevator model from moving.)
			
			foreach (ent in elevator.dustEffect)
			{
				PlayFX( getfx( "vfx_elevator_fall_dust" ), ent.origin );
			}
		}
		else if (elevator.state == 3)
		{
			playSoundAtPos( cablePos, "scn_elevator_fall_cable_snap" );
			elevatorPathBlocker2 SetContents(1);
			elevatorPathBlocker2 elevatorBlockPath();
			
			
			foreach (ent in elevator.sparkEffect)
			{
				PlayFX( getfx( "vfx_spark_drip_child" ), ent.origin );
			}
			
			// get rid of any placed satcom, ims, etc
			elevator killLinkedEntities( attacker );
		}
		
		elevator waittill ( "move_end" );
		
		// end falling
		if (elevator.state == 2)
		{
			playSoundAtPos( cablePos, "scn_elevator_fall_cable_stress" );
			PlayFX( getfx( "vfx_elevator_shaft_dust" ), elevator.origin );
			Earthquake( 0.5, 1.5, elevator.origin, 1000 );
		}
		else if (elevator.state == 3)
		{
			elevator PlaySoundOnMovingEnt( "scn_elevator_fall_crash" );
			Earthquake( 0.75, 1.5, elevator.origin, 1000 );
			elevatorPathBlocker1 SetContents(1);
			elevatorPathBlocker1 elevatorBlockPath();
		}
	}
}

explosive_damage_watch(ent, note)
{
	if(!IsDefined(note))
		note = "explosive_damage";
	
	ent SetCanDamage(true);
	while(1)
	{
		ent.health = 1000000;
		ent waittill("damage", amount, attacker, direction_vec, point, type);
		if(!is_explosive(type))
		{
			continue;
		}
		self notify(note, attacker);
	}
}

falling_elevator_cables(cables)
{
	cables endon ("stop_watching_cable");
	
	large_health = 1000000;
	cables SetCanDamage(true);
	cables.health = large_health;
	cables.fake_health = 50;
	
	while(1)
	{
		cables waittill("damage", amount, attacker, direction_vec, point, type);
		
		if(cables.moving || (self.state==2 && !is_explosive(type)))
		{
			cables.health = cables.health + amount;
			continue;
		}
		
		if(cables.health>large_health-cables.fake_health)
		{
			continue;
		}
		
		self notify("next_stage");
		break;
	}
}

is_explosive( cause )
{
	if(!IsDefined(cause))
		return false;
	
	cause = tolower( cause );
	switch( cause )
	{
		case "mod_grenade_splash":
		case "mod_projectile_splash":
		case "mod_explosive":
		case "splash":
			return true;
		default:
			return false;
	}
	return false;
}

elevatorClearPath()	// self == blockingEnt
{
	self ConnectPaths();
	self Hide();
}

elevatorBlockPath()
{
	self Show();
	self DisconnectPaths();
}


