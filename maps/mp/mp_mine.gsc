#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;

CONST_KILLSTREAK_NAME = "mine_level_killstreak";
CONST_KILLSTREAK_WEAPON = "killstreak_minemarker_mp";
CONST_DEBUG_NAME = "Mine Killstreak";
CONST_KILLSTREAK_LOC_NAME = &"MP_MINE_LEVEL_KILLSTREAK";
CONST_KILLSTREAK_PICKUP = &"MP_MINE_LEVEL_KILLSTREAK_PICKUP";
CONST_CRATE_WEIGHT = 90;

main()
{
	maps\mp\mp_mine_precache::main();
	maps\createart\mp_mine_art::main();
	maps\mp\mp_mine_fx::main();
	
	maps\mp\_load::main();
	
//	AmbientPlay( "ambient_mp_setup_template" );
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_mine" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	SetDvar( "r_tessellationCutoffFalloffBase", 600 );
	SetDvar( "r_tessellationCutoffDistanceBase", 2000 );
	SetDvar( "r_tessellationCutoffFalloff", 600 );
	SetDvar( "r_tessellationCutoffDistance", 2000 );
	SetDvar( "r_reactiveMotionWindFrequencyScale", 0.1);
	SetDvar( "sm_sunSampleSizeNear", 0.43);

	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	// wheel anims are set in the script_noteworthy. wheelSpeed=0 -> idle; wheelSpeed=2 -> fast
	level.minecartWheelAnims = [ "mp_cart_idle_anim", "mp_cart_spin_slow_anim", "mp_cart_spin_mid_anim", "mp_cart_spin_fast_anim" ];
	
	thread setupElevator();
	thread MineCartSetup("cart1", "cart1TrackStart", "cart1AttachedModels","cart1dmg", "cart1_inside", "cart1_front" );
	thread MineCartSetup("cart2", "cart2TrackStart", "cart2AttachedModels","cart2dmg", "cart2_interior", "cart2_front" );
	thread setupElevatorKillTrigger();
	
	initKillstreak();
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
	
	wildlife();
	thread ambientAnimations();
	
	level._effect[ "gear_blood" ] = LoadFX( "vfx/moments/mp_zerosub/vfx_blood_explosion" );
	
	thread setupPushTrigger( "pushTrigger01", (10, 90, 0) );
	thread setupPushTrigger( "pushTrigger02", (10, 180, 0) );
//	thread setupPushTrigger( "pushTrigger03", (10, 90, 0) );
	thread setupPushTrigger( "pushTrigger04", (10, 270, 0) );
}

setupGameTypeFlags( elevator )
{
	level.mineBFlag = undefined;
	objectives = [];
	
	if ( level.gameType == "dom" || level.gameType == "siege" )
	{
		objectives = GetEntArray( "flag_primary", "targetname" );
	}
	else
	{
		return;
	}
	
	// cache the result so we don't have to find it each time
	foreach ( f in objectives )
	{
		if ( IsDefined( f.script_label ) && f.script_label == "_b" )
		{
			level.mineBFlag = f;
			break;
		}
	}
	
	if ( IsDefined( level.mineBFlag ) )
	{
		level thread updateBFlagObjIcon();
		
		domFlag = getDomFlagB();
		domflag EnableLinkTo();
		domflag LinkTo( ELEVATOR );
		
		while (!IsDefined(domflag.useObj))
		{
			waitframe();
		}
		foreach ( vis in domflag.useObj.visuals )
		{
			vis LinkTo( ELEVATOR );
		}
	}
}

getDomFlagB()
{
	return level.mineBFlag;
}

BASE_EFFECT_OFFSET_GOING_DOWN = 1.5;
BASE_EFFECT_OFFSET_GOING_UP = 16;

updateBFlagFxPos( goingUp, loop )
{
	level endon( "mp_mine_elevator_stopped" );
	
	bFlag = getDomFlagB();
	if ( !IsDefined( bFlag ) )
		return;
	
	offset = ter_op( goingUp, BASE_EFFECT_OFFSET_GOING_UP, BASE_EFFECT_OFFSET_GOING_DOWN );
	
	while ( true )
	{
		fxOrigin = bFlag.origin + ( 0, 0, offset );
		bFlag.useObj.baseEffectPos = fxOrigin;
		
		if ( IsDefined( bFlag.useObj.neutralFlagFx ) )
		{
			bFlag.useObj.neutralFlagFx.origin = fxOrigin;
			TriggerFX( bFlag.useObj.neutralFlagFx );
		}
		
		foreach ( player in level.players )
		{
			if ( IsDefined( player._domFlagEffect ) && IsDefined( player._domFlagEffect[ "_b" ] ) )
			{
				player._domFlagEffect[ "_b" ].origin = fxOrigin;
				TriggerFX( player._domFlagEffect[ "_b" ] );
			}
		}
		
		if ( !loop )
		{
			break;
		}
		wait 0.25;
	}
}

updateBFlagObjIcon()
{
	bFlag = getDomFlagB();
	while ( !IsDefined( bFlag.useObj ) )
	{
		waitframe();
	}
	
	// Force the objective icons to update
	tag_origin = spawn_tag_origin();
	tag_origin show();
	tag_origin.origin = bFlag.origin + ( 0, 0, 100 );
	tag_origin LinkTo( bFlag );	
	bFlag.useObj.objIconEnt = tag_origin;
	bFlag.useObj maps\mp\gametypes\_gameobjects::updateWorldIcons();
}

setupElevator()
{
	ELEVATOR = GetEnt("elevator", "targetname");
	GEARS = GetEnt("elevatorGears", "targetname");
	BLOCKER = GetEnt("elevatorPathNodeHolders", "targetname");
	BLOCKERTOP = GetEnt("elevatorPathNodeTop", "targetname");
	BLOCKERMID = GetEnt("elevatorPathNodeMid", "targetname");
	BLOCKERBOT = GetEnt("elevatorPathNodeBot", "targetname");
	MOVETIME = 6; //how long it takes for elevator to move from floor to floor
	WAITTIME = 20; //how long elevator stays at floor
	STRUCTTOP = getstruct("elevatorTop", "targetname");
	STRUCTBOT = getstruct("elevatorBot", "targetname");
	
	//Link attached models to elevator
	ELEVATORMODELS = GetEntArray( "elevatorAttachedModels", "targetname" );
	foreach ( detail in ELEVATORMODELS )
	{
		detail LinkTo( ELEVATOR );
	}
	ELEVATORKILL = GetEnt("elevatorDamage", "targetname");
	ELEVATORKILL EnableLinkTo();
	ELEVATORKILL LinkTo(ELEVATOR);
	
	GEARKILL = ELEVATOR linkTrigger( "elevatorGearCrushTrigger" );
	
	BEAMKILL = GetEnt("elevatorSquish", "targetname");
	BEAMKILL.dmg = 0;
	//make all path blockers non solid so dogs and stuff can run through them.
	ELEVATOR ConnectPaths();
	BLOCKER Hide();
	BLOCKER NotSolid();
	BLOCKERTOP Hide();
	BLOCKERTOP NotSolid();
	//BLOCKERMID Hide();
	//BLOCKERMID NotSolid();
	//BLOCKERBOT Hide();
	//BLOCKERBOT NotSolid();
	
	setupGameTypeFlags( ELEVATOR );
	
	//Elevator Starts in TOP position, so enable those paths
	blockerConnect(BLOCKERTOP);
	
	
	// setup sound entities
	leftSoundEnt = GetEnt( "elevatorWheelLeft", "targetname" );
	leftSoundEnt LinkTo( GEARS );
	
	rightSoundEnt = GetEnt( "elevatorWheelRight", "targetname" );
	rightSoundEnt LinkTo( GEARS );
	
	wait 10;
	
	//movement loop
	while (true)
	{
		//MOVE DOWN
		GEARS RotatePitch( -1 * 256.1, MOVETIME, 1, 1);
		GEARS MoveTo((-59, 256, 287), MOVETIME, 1, 1);
		ELEVATOR MoveTo(STRUCTBOT.origin, MOVETIME, 1, 1);
		ELEVATORKILL.dmg = 1000;
		ELEVATOR.destroyDroneOnCollision = true;
		ELEVATOR.destroyAirdropOnCollision = true;
		
		level thread updateBFlagFxPos( false, true );
		
		// elevator down sound
		leftSoundEnt PlaySoundOnMovingEnt( "mine_elev_big_01" );
		rightSoundEnt PlaySoundOnMovingEnt( "mine_elev_big_02" );
		
		blockerConnect(BLOCKERMID);
		wait 2;
		//blockerDisconnect(BLOCKERTOP);
		wait 2;
		blockerDisconnect(BLOCKERTOP);
		blockerConnect(BLOCKERBOT);
		wait 2;
		blockerDisconnect(BLOCKERMID);
		
		level notify( "mp_mine_elevator_stopped" );
		level updateBFlagFxPos( false, false );
		wait WAITTIME;
		
		//MOVE UP
		GEARS RotatePitch( 1 * 256.1, MOVETIME, 1, 1);
		GEARS MoveTo((-59, 256, 543), MOVETIME, 1, 1);
		ELEVATOR MoveTo(STRUCTTOP.origin, MOVETIME, 1, 1);
		ELEVATORKILL.dmg = 0;
		ELEVATOR.destroyDroneOnCollision = false;
		ELEVATOR.destroyAirdropOnCollision = false;
		
		level thread updateBFlagFxPos( true, true );
		
		// elevator up sound
		leftSoundEnt PlaySoundOnMovingEnt( "mine_elev_big_01" );
		rightSoundEnt PlaySoundOnMovingEnt( "mine_elev_big_02" );
		
		blockerConnect(BLOCKERMID);
		wait 2;
		
		GEARKILL thread crushPlayerInTrigger();
		BEAMKILL.dmg = 1000;
		
		blockerDisconnect(BLOCKERBOT);
		blockerConnect(BLOCKERTOP);
		wait 2;
		//blockerConnect(BLOCKERTOP);
		wait 2;
		blockerDisconnect(BLOCKERMID);
		
		GEARKILL notify( "stopCrushing" );
		BEAMKILL.dmg = 0;
		
		level notify( "mp_mine_elevator_stopped" );
		level updateBFlagFxPos( false, false );
		wait WAITTIME;
	}
	
	/*if( level.gametype == "horde" )
		return;
	
	elevatorCfg = SpawnStruct();
	elevatorCfg.name = "elevator";
	// elevatorCfg.destinations = [ "elevatorBot", "elevatorTop" ];
	elevatorCfg.destinations = "elevatorDestination";
	elevatorCfg.destinationNames = ["elevatorTop","elevatorBot"];
	elevatorCfg.buttons = "elevatorButton";
	elevatorCfg.models = "elevatorAttachedModels";
	
	elevatorCfg.moveTime = 5.0;
	
	elevatorCfg.startSfx = "scn_elevator_startup";
	elevatorCfg.stopSfx = "scn_elevator_stopping";
	elevatorCfg.loopSfx = "scn_elevator_moving_lp";
	// elevatorCfg.beepSfx = "scn_elevator_beep";
	
	elevatorCfg.onMoveCallback = ::elevatorStartGears;
	
	// add start and stop functions
	
	elevator = maps\mp\_elevator_v2::init_elevator( elevatorCfg );
	
	//if( level.gametype == "dom" )
	//{
	//	wait(10);
	//	level.domFlags[1] LinkTo( elevator );
	//}
	
	gears = GetEntArray( "elevatorGears", "targetname" );
	foreach ( gear in gears )
	{
		//gear LinkTo( elevator );
	}
	
	elevator.pathBlockers[ "elevatorMid" ] = GetEnt( "elevatorPathNodeMid", "targetname" );
	elevator maps\mp\_elevator_v2::elevatorClearPath( elevator.curFloor );
	*/
}

blockerConnect(BLOCKENT)
{
	BLOCKENT Show();
	BLOCKENT Solid();
	BLOCKENT ConnectPaths();
	BLOCKENT Hide();
	BLOCKENT NotSolid();
}

blockerDisconnect(BLOCKENT)
{
	BLOCKENT Show();
	BLOCKENT Solid();
	BLOCKENT DisconnectPaths();
}

elevatorStartGears( floorName )	// self == elevator
{
	// can't rotate things that are linked?
	
	gears = GetEntArray( "elevatorGears", "targetname" );
	if ( floorName == self.destinationNames[0] )
	{
		// going down
		foreach ( gear in gears )
		{
			gear RotatePitch( 1 * 360, self.moveTime, 0, 0 );
			gear MoveTo((-59, 256, 543), self.moveTime, 0, 0);
		}
		
		//wait( .5 );
	
		self maps\mp\_elevator_v2::elevatorClearPath( "elevatorMid" );
		
		wait ( 5 );
		
		self maps\mp\_elevator_v2::elevatorBlockPath( "elevatorMid" );
	}
	else
	{
		// going up
		foreach ( gear in gears )
		{
			gear RotatePitch( -1 * 360, self.moveTime, 0, 0 );
			gear MoveTo((-59, 256, 287), self.moveTime, 0, 0);
		}
		
		//wait( .5 );
	
		self maps\mp\_elevator_v2::elevatorClearPath( "elevatorMid" );
		
		wait ( 5 );
		
		self maps\mp\_elevator_v2::elevatorBlockPath( "elevatorMid" );
	}
	
	
}

MINE_CART_SLOW_SPEED_LIMIT = 250;
MineCartSetup(CartName, FirstNode, LinkedModels, DamageTrigger, insideTriggerName, frontTriggerName )
{
	MINE_CART = GetEnt( CartName, "targetname" );
	MINE_CART_SPEED = 1.0/MINE_CART_SLOW_SPEED_LIMIT;
	MINE_CART_DESTINATION = getstruct( FirstNode, "targetname" );
	
	// MINE_CART_DAMAGE = MINE_CART linkTrigger( DamageTrigger );
	insideTrigger = MINE_CART linkTrigger( insideTriggerName );
	MINE_CART thread setupMineCartInsideTrigger( insideTrigger );
	
	frontTrigger = MINE_CART linkTrigger( frontTriggerName );
	MINE_CART thread setupMineCartFrontTrigger( frontTrigger );
	
	CartModels = GetEntArray( LinkedModels, "targetname" );
	foreach ( detail in CartModels )
	{
		detail LinkTo( MINE_CART );
		detail.destroyDroneOnCollision = false;
		detail.destroyAirdropOnCollision = true;
	}
	MINE_CART.destroyDroneOnCollision = false;	// this flag allows drones to clip through for a couple of seconds after spawning.
	MINE_CART.destroyAirdropOnCollision = true;
	
	killCamEnt = Spawn( "script_model", MINE_CART.origin + ( 0, 0, 60 ) );
	killCamEnt LinkTo( MINE_CART );
	MINE_CART.killCamEnt = killCamEnt;
	MINE_CART.killCamEnt SetScriptMoverKillCam( "explosive" );
	
	MINE_CART.unresolved_collision_func = ::cart_unresolved_collision_func;
	MINE_CART.unresolved_collision_notify_min = 6;
	
	MINE_CART mineCartSetupSparks();
	
	MINE_CART moveTo(MINE_CART_DESTINATION.origin, .1, 0, 0);
	MINE_CART rotateTo(MINE_CART_DESTINATION.angles, .1, 0, 0);
	
	MINE_CART.cartmodel = CartModels[0];
	MINE_CART mineCartHandleEvents( MINE_CART_DESTINATION.script_noteworthy );
	
	MINE_CART.speed = 0;
	
	wait(.5);
	
	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();
	Objective_Add( curObjID, "active", MINE_CART.origin, "mine_cart_icon" );
	Objective_OnEntityWithRotation( curObjID, MINE_CART );
	MINE_CART.curObjID = curObjID;
	
	while(true)
	{
		if(IsDefined(MINE_CART_DESTINATION.script_label))
		{
			speed = float(MINE_CART_DESTINATION.script_label);
			MINE_CART_SPEED = 1.0/speed;
			MINE_CART.speed = speed;
			
			MINE_CART mineCartPlaySparksOnSpeedChange( int(MINE_CART_DESTINATION.script_label) );
		}
		if(MINE_CART_DESTINATION.targetname == "cart2TrackStart")
		{
			thread MineCartElevatorMove(MINE_CART_SPEED);
		}
		MINE_CART_DESTINATION = MineCartMove(MINE_CART, MINE_CART_DESTINATION, MINE_CART_SPEED);
		//wait(MINE_CART_SPEED);
	}
}

MineCartMove(Cart, CurrentNode, CartSpeed)
{
	Cart endon( "death" );
	
	NEXT_NODE = getstruct(CurrentNode.target, "targetname" );
	MOVE_TIME = abs(Distance(Cart.origin, NEXT_NODE.origin)*CartSpeed);
	Cart MoveTo(NEXT_NODE.origin, MOVE_TIME, 0, 0);
	Cart RotateTo(NEXT_NODE.angles, MOVE_TIME, 0, 0);
	wait(MOVE_TIME);
	
	// we have arrived at the next node
	Cart mineCartHandleEvents( NEXT_NODE.script_noteworthy );
	
	return NEXT_NODE;
}

MineCartElevatorMove(ElevatorSpeed)
{
	CARTELEVATE = GetEnt("cart2Elevator", "targetname");
	ELEVATENODEBOT = getstruct("cart2TrackStart", "targetname" );
	ELEVATENODETOP = getstruct("cart2ElevatorTop", "targetname" );
	BLOCKERTOP = GetEnt("cartElevatorPathNodeTop", "targetname");
	BLOCKERBOT = GetEnt("cartElevatorPathNodeBot", "targetname");
	ELEVATEMOVETIME = abs(Distance(ELEVATENODEBOT.origin, ELEVATENODETOP.origin)*ElevatorSpeed);
	
	CARTELEVATE.unresolved_collision_kill = true;
	
	// move up
	CARTELEVATE.destroyDroneOnCollision = false;
	CARTELEVATE PlaySoundOnMovingEnt( "minecart2_elevator_up" );
	CARTELEVATE MoveTo(ELEVATENODETOP.origin, ELEVATEMOVETIME, 0, 0);
	blockerDisconnect(BLOCKERBOT);
	wait(ELEVATEMOVETIME);
	blockerConnect(BLOCKERTOP);
	wait(5);
	blockerDisconnect(BLOCKERTOP);
	
	// move down
	CARTELEVATE.destroyDroneOnCollision = true;
	CARTELEVATE PlaySoundOnMovingEnt( "minecart2_elevator_down" );
	CARTELEVATE MoveTo(ELEVATENODEBOT.origin, ELEVATEMOVETIME, 0, 0);
	wait(ELEVATEMOVETIME-2);
	trigger_on("cart2ElevatorKill", "targetname" );
	wait(2);
	trigger_off("cart2ElevatorKill", "targetname" );
	blockerConnect(BLOCKERBOT);
}

setupElevatorKillTrigger()
{
	trigger_off("cart2ElevatorKill", "targetname" );
}


linkTrigger( triggerName )
{
	trigger = GetEnt( triggerName, "targetname" );
	if ( IsDefined( trigger ) )
	{
		trigger EnableLinkTo();
		trigger LinkTo( self );
	}
	
	return trigger;
}

setupMineCartFrontTrigger( frontTrigger )
{
	level endon( "game_ended" );
	
	if ( !IsDefined( frontTrigger ) )
		return;
	
	while ( true )
	{
		frontTrigger waittill( "trigger", otherPlayer );
		
		if ( IsPlayer( otherPlayer ) || IsAgent( otherPlayer ) ) 
		{
			// react only when the cart is moving fast enough
			if ( isReallyAlive( otherPlayer ) && self.speed >= MINE_CART_SLOW_SPEED_LIMIT )
			{
				if ( otherPlayer IsMantling() )
					continue;
				
				// find a valid attacker in the cart
				enemyRider = undefined;
				if ( self.playersInCart.size > 0 )
				{
					foreach ( rider in self.playersInCart )
					{
						if ( isReallyAlive( rider ) && otherPlayer isEnemy( rider ) )
						{
							enemyRider = rider;
							break;
						}
					}
				}
				
				damageDirection = otherPlayer.origin - self.origin;
				attacker = undefined;
				inflictor = undefined;
				damageVal = 20;
				if ( IsDefined( enemyRider ) )
				{
					damageVal = 100;
					attacker = enemyRider;
					inflictor = self.killCamEnt;
				}
				else if ( level.hardcoreMode )
				{
					damageVal = 100;
				}
				else if ( IsAgent( otherPlayer ) )
				{
					damageVal = 50;
				}
				
				// unhappy about calling callback directly, but there's no way to specify weapon to DoDamage
				damageCallback = level.callbackPlayerDamage;
				if ( IsAgent( otherPlayer ) )
				{
					damageCallback = maps\mp\agents\_agent_common::CodeCallback_AgentDamaged;
				}
				
				otherPlayer thread [[ damageCallback ]](
					inflictor,
					attacker,
					damageVal,
					0,
					"MOD_EXPLOSIVE",
					"iw6_minecart_mp",
					self.origin,
					damageDirection,
					"none",
					0
				);
				
				wait(.2);
			}
		}
		
		wait( 0.05 );
	}
}

setupMineCartInsideTrigger( insideTrigger )
{
	level endon( "game_ended" );
	
	self.playersInCart = [];
	
	if ( !IsDefined( insideTrigger ) )
		return;
	
	while ( true )
	{
		insideTrigger waittill( "trigger", player );
		
		if ( IsPlayer( player ) && isReallyAlive( player ) )
		{
			entNum = player GetEntityNumber();
			
			if ( !IsDefined( self.playersInCart[ entNum ] ) )
			{
				self.playersInCart[ entNum ] = player;
				
				if ( self.playersInCart.size == 1 )
				{
					self thread waitForRiderExit( insideTrigger );
				}
			}
		}
		
		wait (0.05);
	}
}

waitForRiderExit( insideTrigger )
{
	level endon ("game_ended");
	
	while ( self.playersInCart.size > 0 )
	{
		foreach ( index, player in self.playersInCart )
		{
			if ( !IsDefined( player )
			    || !isReallyAlive( player )
			    || !player IsTouching( insideTrigger )
			   )
			{
				self.playersInCart[ index ] = undefined;
			}
		}
		
		wait ( 0.05 );
	}
}

mineCartSetupSparks()
{
	level._effect[ "cart_sparks" ]	= LoadFX( "vfx/moments/mp_mine/vfx_track_sparks_child" );
	level._effect[ "cart_sparks_loop" ] = LoadFX( "vfx/moments/mp_mine/vfx_track_sparks_loop" );
	self.lastSpeed = 10;
	self.sparkTimeStamp = 0;
}

CONST_SPARK_SPEED_LIMIT = 20;
CONST_SPARK_FREQUENCY = 3500; // in ms
mineCartPlaySparksOnSpeedChange( targetSpeed )
{
	// check velocity relative to target nodeSpeed
	if ( IsDefined( targetSpeed ) 
	    && GetTime() > self.sparkTimeStamp
	    && abs( targetSpeed - self.lastSpeed ) > CONST_SPARK_SPEED_LIMIT
	   )
	{
		self.lastSpeed = targetSpeed;
		self.sparkTimeStamp = GetTime() + CONST_SPARK_FREQUENCY;
		
		self thread mineCartPlaySparks( "cart_sparks" );
	}
}

CONST_REAR_SCALE = 1;
CONST_RIGHT_SCALE = 18;
CONST_TAG_WHEEL_L = "tag_wheelL";
CONST_TAG_WHEEL_R = "tag_wheelR";
mineCartPlaySparks( fxName )
{
	// play sound
/*	
	forward = -1 * AnglesToForward( self.angles );
	right = AnglesToRight( self.angles );
	up = AnglesToUp( self.angles );
	
	lrpos = self.origin + CONST_REAR_SCALE * forward - CONST_RIGHT_SCALE * right;
	rrpos = self.origin + CONST_REAR_SCALE * forward + CONST_RIGHT_SCALE * right;

	PlayFX( getfx( "cart_sparks" ), lrpos, forward, up );
	wait( 0.05 );
	PlayFX( getfx( "cart_sparks" ), rrpos, forward, up );
	
//	Sphere( lrpos, 5, (1, 0, 0), false, 20 );
//	Sphere( rrpos, 5, (0, 1, 0), false, 20 );

*/
	
	PlayFXOnTag( getfx( fxName ), self.cartmodel, CONST_TAG_WHEEL_L );
	PlayFXOnTag( getfx( fxName ), self.cartmodel, CONST_TAG_WHEEL_R );
}

mineCartStopSparks( fxName )
{
	StopFXOnTag( getfx( fxName ), self.cartmodel, CONST_TAG_WHEEL_L );
	StopFXOnTag( getfx( fxName ), self.cartmodel, CONST_TAG_WHEEL_R );
}

mineCartHandleEvents( node_noteworthy )	// self == cart
{
	if ( !IsDefined( node_noteworthy ) )
		return;
	
	tokens = StrTok( node_noteworthy, "," );
	
	foreach ( token in tokens )
	{
		if ( isStrStart( token, "sfx=" ) )
		{
			sfxName = GetSubStr( token, 4, token.size );
			
			self PlaySoundOnMovingEnt( sfxName );
		}
		else if ( isStrStart( token, "loop=" ) )
		{
			sfxName = GetSubStr( token, 5, token.size );
			self PlayLoopSound( sfxName );
		}
		else if ( token == "loopstop" )
		{
			self StopLoopSound();
		}
		else if ( token == "vfx" )
		{
			self thread mineCartPlaySparks( "cart_sparks" );
		}
		else if ( token == "vfxStart" )
		{
			self thread mineCartPlaySparks( "cart_sparks_loop" );
		}
		else if ( token == "vfxStop" )
		{
			self mineCartStopSparks( "cart_sparks_loop" );
		}
		else if ( isStrStart( token, "wheelSpeed=" ) )
		{
			wheelAnimId = Int( GetSubStr( token, 11, token.size ) );
			if ( wheelAnimId < level.minecartWheelAnims.size )
			{
				self.cartmodel ScriptModelPlayAnim( level.minecartWheelAnims[ wheelAnimId ] );
			}
		}
	}
}

// --------------------------------------------------
// Killstreaks
// --------------------------------------------------
initKillstreak()
{
	level.mapCustomKillstreakFunc = ::customKillstreakFunc;
	level.mapCustomCrateFunc = ::customCrateFunc;
	level.mapCustomBotKillstreakFunc = ::customBotKillstreakFunc;
	
	/#
	AddDebugCommand( "bind p \"set scr_givekillstreak " + CONST_KILLSTREAK_NAME + "\"\n" );
	#/
}

customCrateFunc()
{
	if(!IsDefined(game["player_holding_level_killstrek"]))
		game["player_holding_level_killstrek"] = false;
		
	if(!allowLevelKillstreaks() || game["player_holding_level_killstrek"])
		return;
	
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault", 
											   CONST_KILLSTREAK_NAME,
											   CONST_CRATE_WEIGHT,
											   maps\mp\killstreaks\_airdrop::killstreakCrateThink,
											   maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), 
											   maps\mp\killstreaks\_airdrop::get_enemy_crate_model(),
											   CONST_KILLSTREAK_PICKUP
											  );
	level thread watchForCrateUse();
}

watchForCrateUse()
{
	while( true )
	{
		level waittill("createAirDropCrate", dropCrate);

		if( IsDefined( dropCrate ) && IsDefined( dropCrate.crateType ) && dropCrate.crateType == CONST_KILLSTREAK_NAME )
		{	
			maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", CONST_KILLSTREAK_NAME, 0);
			captured = wait_for_capture(dropCrate);
			
			if(!captured)
			{
				//reEnable warhawk mortars care packages if it expires with out anyone picking it up
				maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", CONST_KILLSTREAK_NAME, CONST_CRATE_WEIGHT );
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

customKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/" + CONST_DEBUG_NAME + "\" \"set scr_devgivecarepackage " + CONST_KILLSTREAK_NAME + "; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/" + CONST_DEBUG_NAME + "\" \"set scr_givekillstreak " + CONST_KILLSTREAK_NAME + "\"\n");

//	initAirdropKS();
	
	maps\mp\killstreaks\mp_wolfpack_killstreak::init();
	
	// this is a hack so the mine cart will show a correct killcam icon
	level.killstreakWeildWeapons[ "iw6_minecart_mp" ] = "iw6_minecart_mp";
}

customBotKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Bots(Killstreak)/Level Events:5/" + CONST_DEBUG_NAME + "\" \"set scr_testclients_givekillstreak " + CONST_KILLSTREAK_NAME + "\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( CONST_KILLSTREAK_NAME,	maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
//	maps\mp\bots\_bots_ks::bot_register_killstreak_func( CONST_KILLSTREAK_NAME,	maps\mp\bots\_bots_ks::bot_killstreak_drop_outside );
}

ambientAnimations()
{
	wait( 3 );
	
	wheels = GetEnt( "spinny_wheels", "targetname" );
	if ( IsDefined( wheels ) )
	{
		wheels ScriptModelPlayAnim( "mp_mine_spinning_wheels" );
	}
}

wildlife()
{
	thread maps\interactive_models\vulture_mp::vulture_circling((565, -1870, 1500), 3);
	thread maps\interactive_models\vulture_mp::vulture_circling((-300, 1210, 1650), 2);
	/#thread maps\interactive_models\vulture_mp::vultures_toggle_thread();#/
		
	thread maps\interactive_models\batcave::vfxBatCaveWaitInit( "bats_flyaway_1", 1, "vfx_bats_flyaway_1", (-2028.06, 464.427, 413.921) );
	thread maps\interactive_models\batcave::vfxBatCaveWaitInit( "bats_flyaway_2", 2, "vfx_bats_flyaway_2", (-264.3, 927.7, 397.8), 2 );
}

crushPlayerInTrigger()	// self == gear
{
	level endon( "game_ended" );
	self endon( "stopCrushing" );
	
	while ( true )
	{
		self waittill( "trigger", player );
		
		if ( isReallyAlive( player ) )
		{
			player DoDamage( 1000, player.origin, undefined, undefined, "MOD_CRUSH" );
			
			player notify( "notify_moving_platform_invalid" );
			
			if ( IsPlayer( player ) || IsAgent( player ) )
			{
				thread cleanupCrushedbody( player GetCorpseEntity() );
			}
		}
	}
}

cleanupCrushedBody( body )
{
	PlayFX( getfx( "gear_blood" ), body.origin, -1 * AnglesToForward( body.angles ), AnglesToUp( body.angles ) );
	
	wait( 0.7 );
	
	if ( IsDefined( body ) )
	{
		PlayFX( getfx( "gear_blood" ), body.origin, -1 * AnglesToForward( body.angles ), AnglesToUp( body.angles ) );
		
		body Hide();
	}
}

cart_unresolved_collision_func(player, bAllowSuicide)
{
	if ( IsPlayer( player ) && player IsLinked() )
	{
		player Unlink();
	}
	
// disable node teleporting for the cart and allow players to clip through the cart briefly
//	self maps\mp\_movers::unresolved_collision_nearest_node( player, true );
	self maps\mp\_movers::unresolved_collision_owner_damage( player );
}

// 2014-07-03 wallace: there are some low overhangs on the mine cart tracks (mostly track1) that are too late to change.
// Instead, we'll push players who hit these triggers away and hopefully off the minecart.
setupPushTrigger( triggerName, pushAngles  )
{
	level endon( "game_ended" );
	trigger = GetEnt( triggerName, "targetname" );
	
	if ( !IsDefined( trigger ) )
		return;
	
	while ( true )
	{
		trigger waittill( "trigger", player );
		
		if ( IsPlayer( player ) || IsAgent( player ) )
		{
			// if the player is using a box or crate, allow him to be disconnected
			if ( player IsLinked() )
			{
				player Unlink();
				player.startUseMover = undefined;
			}
			
			dir = 100 * AnglesToForward( pushAngles );
			player SetVelocity( dir );
			
//			Sphere( player.origin, 10, (1, 0, 0), false, 1000 );
//			Line( player.origin, player.origin + dir, (1, 0, 0), 1, false, 1000 );
		}
		
		wait 0.1;
	}
}

// ---------------------------------------------------
// airstrike
// ---------------------------------------------------
/*
addDropObj( name, baseModel, fallSfx, fallVfx, impactSfx, impactVfx, impactModel, impactRadius )
{
	obj = [];
	obj["model"]			= baseModel;
	obj["fallSfx"]			= fallSfx;
	if ( IsDefined( fallVfx ) )
	{
		obj["fallTrailVfx"]		= getfx( fallVfx );
	}
	obj["impactSfx"]		= impactSfx;
	if ( IsDefined( impactVfx ) )
	{
		obj["impactVfx"]		= getfx( impactVfx );
	}
	obj["impactModel"]		= impactModel;
	obj["impactRadius"]		= impactRadius;
	
//	self.droppedObjs[ self.droppedObjs.size ] = obj;
	self.droppedObjs[ name ] = obj;
}

initAirdropKS()
{
	config = SpawnStruct();
	config.modelNames = [];
	config.modelNames[ "allies" ] = "vehicle_ac130_low_mp";
	config.modelNames[ "axis" ] = "vehicle_ac130_low_mp";
	config.inboundSfx = "veh_ac130_dist_loop";
	// veh_ac130_sonic_boom
	config.compassIconFriendly = "compass_objpoint_c130_friendly";
	config.compassIconEnemy = "compass_objpoint_c130_enemy";
	config.noLightFx = true;
	// sonic boom?
	config.speed = 2000;
	config.halfDistance = 12000;
	config.heightRange = 500;
	//config.attackTime = 2.0;
//	config.outboundFlightAnim = "airstrike_mp_roll";
	config.onAttackDelegate = ::dropBombs;
	config.onFlybyCompleteDelegate = ::cleanupFlyby;
	config.chooseDirection = true;
	config.selectLocationVO = "KS_hqr_airstrike";
	config.inboundVO = "KS_ast_inbound";
	config.chooseDirection = false;
	
	config.droppedObjs = [];
	
//	config addDropObj( "mine_anvil_bomb", undefined, "falling_trail", undefined, "cart_explode", undefined, 200 );
	config addDropObj( "piano", "mine_piano_bomb", undefined, "falling_trail", undefined, "cart_explode", "undefined", 300 );
	config addDropObj( "bomb", "mine_large_bomb", undefined, "falling_trail", undefined, "cart_explode", undefined, 300 );
	
	config.bombModel = "projectile_cbu97_clusterbomb";
	config.numBombs = 8;
	// should be 2x the effect radius to have no gaps/overlap
	config.distanceBetweenBombs = 350;
	config.effectRadius = 200;
	config.effectHeight = 120;
	
	level.planeConfigs[ CONST_KILLSTREAK_NAME ] = config;
	
	level.killstreakFuncs[CONST_KILLSTREAK_NAME] = ::onUse;
	level.killstreakWeildWeapons[ CONST_KILLSTREAK_WEAPON ] = CONST_KILLSTREAK_NAME;
}

onUse( lifeId, streakName )
{
	assert( isDefined( self ) );
	
	// check for active air_superiority strikes
	otherTeam = getOtherTeam( self.team );
	
	result = selectAirstrikeLocationWithGrenade( lifeId, streakName, getKillstreakWeapon( streakName ), ::doStrike );
	
	return ( IsDefined( result ) && result );
}

doStrike( lifeId, location, directionYaw, streakName )
{
	wait ( 1 );
	
	directionYaw = self.angles[1] + 90;
	
	planeFlyHeight = maps\mp\killstreaks\_plane::getPlaneFlyHeight();
	
	dirVector = AnglesToForward( (0, directionYaw, 0) );
	
	doOneFlyby( streakName, lifeId, location, dirVector, planeFlyHeight );
	
	self waittill( "airstrike_flyby_complete" );
	
	// play outbound vo
}

doOneFlyby( streakName, lifeId, targetPos, dir, flyHeight )
{
	config = level.planeConfigs[ streakName ];
	
	// absolute height should be derived from the heightEnt
	flightPath = maps\mp\killstreaks\_plane::getFlightPath( targetPos, dir, config.halfDistance, true, flyHeight, config.speed, 0, streakName );
	
	// Box( targetPos, dir[1], (0, 0, 1), false, 200);
	
	// may want to break this up into spawn, move, cleanup components
	// so that we can reuse the plane
	level thread maps\mp\killstreaks\_plane::doFlyby( lifeId, self, lifeId, 
													 flightPath["startPoint"] + (0, 0, randomInt(config.heightRange) ), 
													 flightPath["endPoint"] + (0, 0, randomInt(config.heightRange) ), 
													 flightPath["attackTime"],
													 flightPath["flyTime"],
													 dir, 
													 streakName );
}

cleanupFlyby( owner, plane, streakName )
{
	owner notify( "airstrike_flyby_complete" );
}


dropBombs( pathEnd, flyTime, beginAttackTime, owner, streakName )	// self == plane
{
	self endon( "death" );
	
	wait ( 0.95 * beginAttackTime);
	
	config = level.planeConfigs[ streakName ];
	
	numBombsLeft = config.numBombs;
	timeBetweenBombs = config.distanceBetweenBombs / config.speed;
	
	while (numBombsLeft > 0)
	{
		bombPos = pickRandomTargetPoint( self.origin, 50 );
		
		self thread dropOneBomb( owner, streakName, bombPos, "bomb" );
		
		numBombsLeft--;
		
		wait ( 0.1 );
	}
	
	bombPos = pickRandomTargetPoint( self.origin, 50 );
	self thread dropOneBomb( owner, streakName, bombPos, "piano" );
	
}

pickBombType( config )
{
	index = RandomInt( config.droppedObjs.size );
	
	return config.droppedObjs[ index ];
}

CONST_DRAW_TIME = 200;
GRAVITY_UNITS_PER_SEC = 800;
GRAVITY_UNITS_PER_SEC_DIV = 0.00125;
dropOneBomb( owner, streakName, spawnPoint, bombType )	// self == plane
{
	plane = self;
	
	config = level.planeConfigs[ streakName ];
	
	planeDir = AnglesToForward( plane.angles );
	
//	bombConfig = pickBombType( config );
	bombConfig = config.droppedObjs[ bombType ];
		
	bomb = spawnBomb( bombConfig["model"], spawnPoint, plane.angles );
	bomb.owner = owner;
	
	
	trace = BulletTrace( bomb.origin, bomb.origin + (0,0,-1000000), false, plane );
	impactPosition = trace["position"];
	
	// calculate time it takes to fall distance to impac
	timeSquared = Length( bomb.origin - impactPosition ) * 2 * GRAVITY_UNITS_PER_SEC_DIV;
	fallTime = sqrt( timeSquared );
	
	/#
//	Sphere( bomb.origin, 10, (0, 1, 0), false, CONST_DRAW_TIME );
//	Line( bomb.origin, impactPosition, (0, 1, 0), 1, false, CONST_DRAW_TIME );
//	Sphere( bomb.origin, 20, (0, 1, 0), false, CONST_DRAW_TIME );
	#/
		
	bomb MoveGravity( (0, 0, 0), fallTime );
	
	// add trail vfx
	// add falling sfx
	
	wait ( fallTime );

	PlayFX( bombConfig["impactVfx"], bomb.origin );
	
	bomb onBombImpact( owner, self, impactPosition, streakName, bombConfig );
}


spawnBomb( modelName, origin, angles )
{
	bomb = Spawn( "script_model", origin );
	bomb.angles = angles;
	bomb SetModel( modelname );

	return bomb;
}

onBombImpact( owner, plane, position, streakName, bombConfig )	// self == bomb?
{
	config = level.planeConfigs[ streakName ];
	
	PlayFX( bombConfig["impactVfx"], position );
	// play impact sfx
	
	// damage radius - need amount, weapon
	self RadiusDamage( position, bombConfig["impactRadius"], 200, 80, owner, "MOD_CRUSH", CONST_KILLSTREAK_WEAPON );
	
	/#
//	Sphere( position, 10, (1, 0, 0), false, CONST_DRAW_TIME );
//	Sphere( position, bombConfig["impactRadius"], (1, 0, 0), false, CONST_DRAW_TIME );
	#/
		
	self Hide();
	
	wait ( 5 );
	
	self Delete();
}

pickRandomTargetPoint( targetPoint, strikeRadius )
{
	x = RandomFloatRange( -1 * strikeRadius, strikeRadius );
	y = RandomFloatRange( -1 * strikeRadius, strikeRadius );
	return targetPoint + (x, y, 0);
}

selectAirstrikeLocationWithGrenade( lifeId, killstreakName, weaponName, onLocationSelected )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "death" );
	
	self notify( "selectAirstrikeLocationWithGrenade" );
	self endon( "selectAirstrikeLocationWithGrenade" );
	
	self childthread waitForMarkerUse( lifeId, killstreakName, weaponName, onLocationSelected );
	self childthread waitForWeaponSwitch( killstreakName, weaponName );
	
	result = self waittill_any_return( "airstrike_selected", "airstrke_canceled" );
	
	return ( result == "airstrike_selected" );
}

waitForMarkerUse( lifeId, killstreakName, markerName, onLocationSelected )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "airstrke_canceled" );
	
	self.threwAirDropMarker = undefined;
	while( true )
	{
		self waittill( "grenade_pullback", weaponName );

		if ( weaponName != markerName )
			continue;
		
		self _disableUsability();
		
		// need to thread something to enableUsability in case airstrike is cancelled
		self thread restoreUsability();
		
		self waittill( "grenade_fire", marker, weaponName );
		
		self _enableUsability();
		
		if ( weaponName != markerName )
			continue;
		
		marker.owner = self;
		marker.weaponName = weaponName;
		self TakeWeapon( weaponName );
		
		marker thread detonateOnStuck( lifeId, killstreakName, onLocationSelected );
		break;
	}
}

waitForWeaponSwitch( killstreakName, weaponName )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "airstrike_selected" );
	
	currentWeapon = self GetCurrentWeapon();
	// first, wait until we raise the marker
	while ( currentWeapon != weaponName )
	{
		self waittill( "weapon_change", currentWeapon );
	}
	
	// then wait until we switch away from the marker
	while ( currentWeapon == weaponName )
	{
		self waittill( "weapon_change", currentWeapon );
	}
	
	// check if we selected airstrike?
	if ( !IsDefined( self.threwAirDropMarker ) || !self.threwAirDropMarker )
	{
		self notify( "airstrke_canceled" );
	}
}

detonateOnStuck( lifeId, killstreakName, onLocationSelected )	// self == grenade
{
	owner = self.owner;
	owner.threwAirDropMarker = true;
	
	self waittill( "missile_stuck" );
	
	position = self.origin;
	
	self Detonate();
	
	BadPlace_Cylinder( "", 10, position, 600, 100, "axis", "allies" );
	
	// validate the grenade location?
	
	owner notify( "airstrike_selected" );
	
	owner thread [[ onLocationSelected ]]( lifeId, position, 0, killstreakName );
	
}

restoreUsability()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "airstrke_canceled" );
	self endon( "airstrike_selected" );
	
	self waittill( "weapon_change" );
	
	self _enableUsability();
}

deleteAfterTime( time )
{
	self endon ( "death" );
	wait ( time );
	
	self Delete();
}
*/
