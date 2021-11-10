#include maps\mp\_utility;
#include common_scripts\utility;

//	prototype for generic zipline / rappel 
//		- player can use their weapon while travelling on line
//		- player can drop off line by jumping

//	SETUP:
//		- trigger_touch marks the area where the player will be prompted to use the zipline (suggest 32x32x32 trigger touching ground)
//		- script_origin marked as the target of the trigger_use_touch is the destination

init()
{
	visuals = [];
	triggers = getentarray("zipline", "targetname");
	
	for( i = 0; i < triggers.size; i++ )
	{
		zipline = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", triggers[i], visuals, (0,0,0) );
		zipline maps\mp\gametypes\_gameobjects::allowUse( "any" );
		zipline maps\mp\gametypes\_gameobjects::setUseTime( 0.25 );		
		zipline maps\mp\gametypes\_gameobjects::setUseText( &"MP_ZIPLINE_USE" );
		zipline maps\mp\gametypes\_gameobjects::setUseHintText( &"MP_ZIPLINE_USE" );
		zipline maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		zipline.onBeginUse = ::onBeginUse;
		zipline.onUse = ::onUse;

		targets = [];
		target = getEnt( triggers[i].target, "targetname");
		
		if ( !isDefined( target ) )
			assertmsg( "No target found for zipline trigger located at: ( " + triggers[i].origin[0] + ", " + triggers[i].origin[1] + ", " + triggers[i].origin[2] + " )" );
		
		while ( isDefined( target ) )
		{
			targets[targets.size] = target;
			if ( isDefined( target.target ) )
				target = getEnt( target.target, "targetname");
			else
				break;
		}
		
		zipline.targets = targets;		
	}

	precacheModel( "tag_player" );
}


onBeginUse( player )
{
	player playSound( "scrambler_pullout_lift_plr" );
}


onUse( player )
{
	player thread zip( self );
}


zip( useObj )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "zipline_drop" );
	level endon( "game_ended" );
	
	//	make the carrier
	carrier = spawn( "script_origin", useObj.trigger.origin );
	carrier.origin = useObj.trigger.origin;
	carrier.angles = self.angles;
	carrier setModel( "tag_player" );
	
	//	link the player
	self playerLinkToDelta( carrier, "tag_player", 1, 180, 180, 180, 180 );
		
	//	monitor player
	self thread watchDeath( carrier );
	self thread watchDrop( carrier );
	
	//	loop through the path of targets
	targets = useObj.targets;
	for( i=0; i < targets.size; i++ )
	{			
		//	time
		//	JDS TODO: look into LDs specifying speed, accelleration, deceleration on the nodes
		time = distance( carrier.origin, targets[i].origin ) / 600;
		
		//	send it on its way
		acceleration = 0.0;
		if ( i==0 )
			acceleration = time*0.2;
		carrier moveTo( targets[i].origin, time, acceleration );
		if ( carrier.angles != targets[i].angles )
			carrier rotateTo( targets[i].angles, time*0.8 );
		
		//	wait
		wait( time );
	}
	
	//	all done
	self notify( "destination" );	
	self unlink();	
	carrier delete();
}


watchDrop( carrier )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "destination" );
	level endon( "game_ended" );
	
	self notifyOnPlayerCommand( "zipline_drop", "+gostand" );
	
	self waittill( "zipline_drop" );
	
	self unlink();
	carrier delete();	
}


watchDeath( carrier )
{
	self endon( "disconnect" );
	self endon( "destination" );
	self endon( "zipline_drop" );
	level endon( "game_ended" );
	
	self waittill( "death" );
	
	self unlink();
	carrier delete();
}