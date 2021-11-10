#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	// indexes for lua omnvar
	// keep these in line with RoundEndHud.lua and SvSUtils.lua
	game[ "round_end" ][ "draw" ] 			= 1;
	game[ "round_end" ][ "round_draw" ]		= 2;
	game[ "round_end" ][ "round_win" ] 		= 3;
	game[ "round_end" ][ "round_loss" ] 	= 4;
	game[ "round_end" ][ "victory" ] 		= 5;
	game[ "round_end" ][ "defeat" ] 		= 6;
	game[ "round_end" ][ "halftime" ] 		= 7;
	game[ "round_end" ][ "overtime" ]		= 8;
	game[ "round_end" ][ "roundend" ]		= 9;
	game[ "round_end" ][ "intermission" ]	= 10;
	game[ "round_end" ][ "side_switch" ] 	= 11;
	game[ "round_end" ][ "match_bonus" ] 	= 12;
	game[ "round_end" ][ "tie" ] 			= 13;
	game[ "round_end" ][ "spectator" ] 		= 14;


	game[ "end_reason" ][ "score_limit_reached" ] 	= 1;
	game[ "end_reason" ][ "time_limit_reached" ] 	= 2;
	game[ "end_reason" ][ "players_forfeited" ] 	= 3;
	game[ "end_reason" ][ "target_destroyed" ] 		= 4;
	game[ "end_reason" ][ "bomb_defused" ] 			= 5;
	game[ "end_reason" ][ "allies_eliminated" ] 	= 6;
	game[ "end_reason" ][ "axis_eliminated" ] 		= 7;
	game[ "end_reason" ][ "allies_forfeited" ] 		= 8;
	game[ "end_reason" ][ "axis_forfeited" ] 		= 9;
	game[ "end_reason" ][ "enemies_eliminated" ]	= 10;
	game[ "end_reason" ][ "tie" ] 					= 11;
	game[ "end_reason" ][ "objective_completed" ] 	= 12;	
	game[ "end_reason" ][ "objective_failed" ] 		= 13;	
	game[ "end_reason" ][ "switching_sides" ] 		= 14;	
	game[ "end_reason" ][ "round_limit_reached" ] 	= 15;
	game[ "end_reason" ][ "ended_game" ] 			= 16;
	game[ "end_reason" ][ "host_ended_game" ] 		= 17;

	game[ "strings" ][ "overtime" ] = &"MP_OVERTIME";
		
	level thread onPlayerConnect();
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		player thread hintMessageDeathThink();
		player thread lowerMessageThink();
		
		player thread initNotifyMessage();
	}
}


hintMessage( hintText )
{
	notifyData = spawnstruct();
	
	notifyData.notifyText = hintText;
	notifyData.glowColor = game["colors"]["cyan"];
	
	notifyMessage( notifyData );
}


initNotifyMessage()
{
	if ( level.splitscreen || self isSplitscreenPlayer() )
	{
		titleSize = 1.5;
		textSize = 1.25;
		iconSize = 24;
		font = "default";
		point = "TOP";
		relativePoint = "BOTTOM";
		yOffset = 0;
		xOffset = 0;
	}
	else
	{
		titleSize = 2.5;
		textSize = 1.75;
		iconSize = 30;
		font = "objective";
		point = "TOP";
		relativePoint = "BOTTOM";
		yOffset = 50;
		xOffset = 0;
	}
	
	self.notifyTitle = createFontString( font, titleSize );
	self.notifyTitle setPoint( point, undefined, xOffset, yOffset );
	self.notifyTitle.glowColor = game["colors"]["blue"];
	self.notifyTitle.glowAlpha = 1;
	self.notifyTitle.hideWhenInMenu = true;
	self.notifyTitle.archived = false;
	self.notifyTitle.alpha = 0;

	self.notifyText = createFontString( font, textSize );
	self.notifyText setParent( self.notifyTitle );
	self.notifyText setPoint( point, relativePoint, 0, 0 );
	self.notifyText.glowColor = game["colors"]["blue"];
	self.notifyText.glowAlpha = 1;
	self.notifyText.hideWhenInMenu = true;
	self.notifyText.archived = false;
	self.notifyText.alpha = 0;

	self.notifyText2 = createFontString( font, textSize );
	self.notifyText2 setParent( self.notifyTitle );
	self.notifyText2 setPoint( point, relativePoint, 0, 0 );
	self.notifyText2.glowColor = game["colors"]["blue"];
	self.notifyText2.glowAlpha = 1;
	self.notifyText2.hideWhenInMenu = true;
	self.notifyText2.archived = false;
	self.notifyText2.alpha = 0;

	self.notifyIcon = createIcon( "white", iconSize, iconSize );
	self.notifyIcon setParent( self.notifyText2 );
	self.notifyIcon setPoint( point, relativePoint, 0, 0 );
	self.notifyIcon.hideWhenInMenu = true;
	self.notifyIcon.archived = false;
	self.notifyIcon.alpha = 0;

	self.notifyOverlay = createIcon( "white", iconSize, iconSize );
	self.notifyOverlay setParent( self.notifyIcon );
	self.notifyOverlay setPoint( "CENTER", "CENTER", 0, 0 );
	self.notifyOverlay.hideWhenInMenu = true;
	self.notifyOverlay.archived = false;
	self.notifyOverlay.alpha = 0;

	self.doingSplash = [];
	self.doingSplash[0] = undefined;
	self.doingSplash[1] = undefined;
	self.doingSplash[2] = undefined;
	self.doingSplash[3] = undefined;

	self.splashQueue = [];
	self.splashQueue[0] = [];
	self.splashQueue[1] = [];
	self.splashQueue[2] = [];
	self.splashQueue[3] = [];
}


oldNotifyMessage( titleText, notifyText, iconName, glowColor, sound, duration )
{
	notifyData = spawnstruct();
	
	notifyData.titleText = titleText;
	notifyData.notifyText = notifyText;
	notifyData.iconName = iconName;
	notifyData.glowColor = glowColor;
	notifyData.sound = sound;
	notifyData.duration = duration;
	
	notifyMessage( notifyData );
}


notifyMessage( notifyData )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	if ( !IsDefined( notifyData.slot ) )
		notifyData.slot = 0;
	
	slot = notifyData.slot;

	if ( !IsDefined( notifyData.type ) )
		notifyData.type = "";
	
	if ( !IsDefined( self.doingSplash[ slot ] ) )
	{
		self thread showNotifyMessage( notifyData );
		return;
	}/*
	else if ( notifyData.type == "rank" && self.doingSplash[ slot ].type != "challenge_splash" && self.doingSplash[ slot ].type != "killstreak_splash" )
	{
		self thread showNotifyMessage( notifyData );
		return;
	}*/
	
	self.splashQueue[ slot ][ self.splashQueue[ slot ].size ] = notifyData;
}


dispatchNotify( slot )
{	
	nextNotifyData = self.splashQueue[ slot ][ 0 ];
		
	for ( i = 1; i < self.splashQueue[ slot ].size; i++ )
		self.splashQueue[ slot ][i-1] = self.splashQueue[ slot ][i];
	self.splashQueue[ slot ][i-1] = undefined;

	if ( IsDefined( nextNotifyData.name ) )
		actionNotify( nextNotifyData );
	else
		showNotifyMessage( nextNotifyData );
}


promotionSplashNotify()
{
	if( !IsPlayer(self) )
		return;
		
	self endon ( "disconnect" );

	actionData = spawnStruct();
	
	splashRef = "promotion";
	actionData.name = splashRef;
	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );
	actionData.sound = TableLookup( get_table_name(), 0, splashRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}

weaponPromotionSplashNotify()
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );

	actionData = spawnStruct();

	splashRef = "promotion_weapon";
	actionData.name = splashRef;
	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );
	actionData.sound = TableLookup( get_table_name(), 0, splashRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}

showNotifyMessage( notifyData )
{
	self endon("disconnect");

	assert( IsDefined( notifyData.slot ) );
	slot = notifyData.slot;

	if ( level.gameEnded )
	{
		if ( IsDefined( notifyData.type ) && notifyData.type == "rank" )
		{
			self setClientDvar( "ui_promotion", 1 );
			self.postGamePromotion = true;
		}
		
		if ( self.splashQueue[ slot ].size )
			self thread dispatchNotify( slot );

		return;
	}
	
	self.doingSplash[ slot ] = notifyData;

	waitRequireVisibility( 0 );

	if ( IsDefined( notifyData.duration ) )
		duration = notifyData.duration;
	else if ( level.gameEnded )
		duration = 2.0;
	else
		duration = 4.0;
	
	self thread resetOnCancel();

	if ( IsDefined( notifyData.sound ) )
		self PlayLocalSound( notifyData.sound );

	if ( IsDefined( notifyData.leaderSound ) )
		self leaderDialogOnPlayer( notifyData.leaderSound );
	
	if ( IsDefined( notifyData.glowColor ) )
		glowColor = notifyData.glowColor;
	else
		glowColor = game["colors"]["cyan"];

	anchorElem = self.notifyTitle;

	if ( IsDefined( notifyData.titleText ) )
	{
		if ( IsDefined( notifyData.titleLabel ) )
			self.notifyTitle.label = notifyData.titleLabel;
		else
			self.notifyTitle.label = &"";

		if ( IsDefined( notifyData.titleLabel ) && !IsDefined( notifyData.titleIsString ) )
			self.notifyTitle setValue( notifyData.titleText );
		else
			self.notifyTitle setText( notifyData.titleText );
		self.notifyTitle setPulseFX( int(25*duration), int(duration*1000), 1000 );
		self.notifyTitle.glowColor = glowColor;	
		self.notifyTitle.alpha = 1;
	}

	if ( IsDefined( notifyData.textGlowColor ) )
		glowColor = notifyData.textGlowColor;

	if ( IsDefined( notifyData.notifyText ) )
	{
		if ( IsDefined( notifyData.textLabel ) )
			self.notifyText.label = notifyData.textLabel;
		else
			self.notifyText.label = &"";

		if ( IsDefined( notifyData.textLabel ) && !IsDefined( notifyData.textIsString ) )
			self.notifyText setValue( notifyData.notifyText );
		else
			self.notifyText setText( notifyData.notifyText );
		self.notifyText setPulseFX( 100, int(duration*1000), 1000 );
		self.notifyText.glowColor = glowColor;	
		self.notifyText.alpha = 1;
		anchorElem = self.notifyText;
	}

	if ( IsDefined( notifyData.notifyText2 ) )
	{
		self.notifyText2 setParent( anchorElem );
		
		if ( IsDefined( notifyData.text2Label ) )
			self.notifyText2.label = notifyData.text2Label;
		else
			self.notifyText2.label = &"";

		self.notifyText2 setText( notifyData.notifyText2 );
		self.notifyText2 setPulseFX( 100, int(duration*1000), 1000 );
		self.notifyText2.glowColor = glowColor;	
		self.notifyText2.alpha = 1;
		anchorElem = self.notifyText2;
	}

	if ( IsDefined( notifyData.iconName ) )
	{
		self.notifyIcon setParent( anchorElem );
		
		if( level.splitscreen || self isSplitscreenPlayer() )
			self.notifyIcon setShader( notifyData.iconName, 30, 30 );
		else
			self.notifyIcon setShader( notifyData.iconName, 60, 60 );
			
		self.notifyIcon.alpha = 0;

		if ( IsDefined( notifyData.iconOverlay ) )
		{
			self.notifyIcon fadeOverTime( 0.15 );
			self.notifyIcon.alpha = 1;

			//if ( !IsDefined( notifyData.overlayOffsetY ) )
				notifyData.overlayOffsetY = 0;

			self.notifyOverlay setParent( self.notifyIcon );
			self.notifyOverlay setPoint( "CENTER", "CENTER", 0, notifyData.overlayOffsetY );
			self.notifyOverlay setShader( notifyData.iconOverlay, 511, 511 );
			self.notifyOverlay.alpha = 0;
			self.notifyOverlay.color = game["colors"]["orange"];

			self.notifyOverlay fadeOverTime( 0.4 );
			self.notifyOverlay.alpha = 0.85;
	
			self.notifyOverlay scaleOverTime( 0.4, 32, 32 );
			
			waitRequireVisibility( duration );

			self.notifyIcon fadeOverTime( 0.75 );
			self.notifyIcon.alpha = 0;
	
			self.notifyOverlay fadeOverTime( 0.75 );
			self.notifyOverlay.alpha = 0;
		}
		else
		{
			self.notifyIcon fadeOverTime( 1.0 );
			self.notifyIcon.alpha = 1;

			waitRequireVisibility( duration );

			self.notifyIcon fadeOverTime( 0.75 );
			self.notifyIcon.alpha = 0;
		}		
	}
	else
	{
		waitRequireVisibility( duration );
	}

	self notify ( "notifyMessageDone" );
	self.doingSplash[ slot ] = undefined;

	if ( self.splashQueue[ slot ].size )
		self thread dispatchNotify( slot );
}


killstreakSplashNotify( splashRef, streakVal, appendString )
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	waittillframeend;

	if ( level.gameEnded )
		return;

	actionData = spawnStruct();
	
	if ( IsDefined( appendString ) )
		splashRef += "_" + appendString;

	actionData.name = splashRef;
	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );
	actionData.optionalNumber = streakVal;
	actionData.sound = getKillstreakSound( splashRef );
	actionData.leaderSound = splashRef;
	actionData.leaderSoundGroup = "killstreak_earned";
	actionData.slot = 0;

	self thread actionNotify( actionData );
}


defconSplashNotify( defconLevel, forceNotify )
{
	/*
	actionData = spawnStruct();
	
	actionData.name = "defcon_" + defconLevel;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, actionData.name, 9 );
	actionData.slot = 0;
	actionData.forceNotify = forceNotify;

	self thread actionNotify( actionData );
	*/
}


challengeSplashNotify( challengeRef )
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	waittillframeend;
	
	// this is used to ensure the client receives the new challenge state before the splash is shown.
	wait ( 0.05 );

	//subtracting one from state becase state was incremented after completing challenge
	challengeState = ( self ch_getState( challengeRef ) - 1 );
	challengeTarget = ch_getTarget( challengeRef, challengeState );
	
	if( challengeTarget == 0 )
		challengeTarget = 1;
	
	if( challengeRef == "ch_longersprint_pro" || challengeRef == "ch_longersprint_pro_daily" || challengeRef == "ch_longersprint_pro_weekly" )
		challengeTarget = int( challengeTarget/528 );	// 2013-10-20 wallace: due to a loss of precision in player data for challenges, we track his in 10' increments, insead of 1'
	
	actionData = spawnStruct();

	actionData.name = challengeRef;	
	actionData.type = TableLookup( get_table_name(), 0, challengeRef, 11 );

	actionData.optionalNumber = challengeTarget;
	actionData.sound = TableLookup( get_table_name(), 0, challengeRef, 9 );

	// use the same slot as playercard
	actionData.slot = 1;

	self thread actionNotify( actionData );
}


splashNotify( splashRef, optionalNumber )
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	// wait until any challenges have been processed
	//self waittill( "playerKilledChallengesProcessed" );
	wait .05;

	actionData = spawnStruct();
	
	actionData.name = splashRef;	
	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( get_table_name(), 0, actionData.name, 9 );

	actionData.slot = 0;

	self thread actionNotify( actionData );
}

splashNotifyUrgent( splashRef, optionalNumber )
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	// wait until any challenges have been processed
	//self waittill( "playerKilledChallengesProcessed" );
	wait .05;

	actionData = spawnStruct();
	
	actionData.name = splashRef;

	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( get_table_name(), 0, splashRef, 9 );

	actionData.slot = 0;

	self thread actionNotify( actionData );
}

splashNotifyDelayed( splashRef, optionalNumber )
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	waittillframeend;

	if ( level.gameEnded )
		return;

	actionData = spawnStruct();
	
	actionData.name = splashRef;
	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );

	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( get_table_name(), 0, splashRef, 9 );

	actionData.slot = 0;

	self thread actionNotify( actionData );
}


playerCardSplashNotify( splashRef, player, optionalNumber )
{
	if( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	waittillframeend;

	if ( level.gameEnded )
		return;

	actionData = spawnStruct();
	
	actionData.name = splashRef;
	actionData.type = TableLookup( get_table_name(), 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	
	actionData.sound = TableLookup( get_table_name(), 0, splashRef, 9 );

	actionData.playerCardPlayer = player;
	actionData.slot = 1;

	self thread actionNotify( actionData );
}


actionNotify( actionData )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	assert( IsDefined( actionData.slot ) );
	
	slot = actionData.slot;

	if ( !IsDefined( actionData.type ) )
		actionData.type = "";
	
	if ( !IsDefined( self.doingSplash[ slot ] ) )
	{
		self thread actionNotifyMessage( actionData );
		return;
	}
	else 
	{
		switch( actionData.type )
		{
			case "mp_dig_all_perks_splash":
			case "urgent_splash":
				self.notifyText.alpha = 0;
				self.notifyText2.alpha = 0;
				self.notifyIcon.alpha = 0;
				// need to turn off whatever other splash might be showing right now
				self SetClientOmnvar( "ui_splash_idx", -1 );
				self SetClientOmnvar( "ui_splash_killstreak_idx", -1 );
				self SetClientOmnvar( "ui_dig_killstreak_show", -1 );
				self thread actionNotifyMessage( actionData );
				return;
			case "killstreak_splash":
			case "splash":
				if( self.doingSplash[ slot ].type != "splash" && 
					self.doingSplash[ slot ].type != "urgent_splash" && 
					self.doingSplash[ slot ].type != "killstreak_splash" && 
					self.doingSplash[ slot ].type != "challenge_splash" && 
					self.doingSplash[ slot ].type != "promotion_splash" &&
					self.doingSplash[ slot ].type != "intel_splash" )
				{
					self.notifyText.alpha = 0;
					self.notifyText2.alpha = 0;
					self.notifyIcon.alpha = 0;
					self thread actionNotifyMessage( actionData );	
					return;
				}
				break;
		}
	}
	
	// push to front of queue
	if( actionData.type == "challenge_splash" || actionData.type == "killstreak_splash" )
	{
		if ( actionData.type == "killstreak_splash" )
			self removeTypeFromQueue( "killstreak_splash", slot );
		
		for ( i = self.splashQueue[ slot ].size; i > 0; i-- )
			self.splashQueue[ slot ][ i ] = self.splashQueue[ slot ][ i-1 ];

		self.splashQueue[ slot ][ 0 ] = actionData;
	}
	else
	{
		self.splashQueue[ slot ][ self.splashQueue[ slot ].size ] = actionData;
	}
}


removeTypeFromQueue( actionType, slot )
{
	newQueue = [];

	for ( i = 0; i < self.splashQueue[ slot ].size; i++ )
	{
		if ( self.splashQueue[ slot ][ i ].type != "killstreak_splash" )
			newQueue[ newQueue.size ] = self.splashQueue[ slot ][ i ];
	}

	self.splashQueue[ slot ] = newQueue;
}


actionNotifyMessage( actionData )
{
	self endon ( "disconnect" );

	assert( IsDefined( actionData.slot ) );
	slot = actionData.slot;
	
	if ( level.gameEnded )
	{
		if ( IsDefined( actionData.type ) && ( actionData.type == "promotion_splash" || actionData.type == "promotion_weapon_splash" ) )
		{
			self setClientDvar( "ui_promotion", 1 );
			self.postGamePromotion = true;
		}		
		else if ( IsDefined( actionData.type ) && actionData.type == "challenge_splash" )
		{
			self.pers["postGameChallenges"]++;
			self setClientDvar( "ui_challenge_"+ self.pers["postGameChallenges"] +"_ref", actionData.name );
		}

		if ( self.splashQueue[ slot ].size )
			self thread dispatchNotify( slot );

		return;
	}
	
	
	assertEx( TableLookup( get_table_name(), 0, actionData.name, 0 ) != "", "ERROR: unknown splash - " + actionData.name );
	
	// defensive ship hack for missing table entries
	if ( TableLookup( get_table_name(), 0, actionData.name, 0 ) != "" )
	{
		
		splashIdx = TableLookupRowNum( get_table_name(), 0, actionData.name );
		duration = stringToFloat( TableLookupByRow( get_table_name(), splashIdx, 4 ) );

		// need to let the ui know that a splash has been called
		switch( actionData.type )
		{
		case "killstreak_splash":		
			self SetClientOmnvar( "ui_splash_killstreak_idx", splashIdx );
			if ( IsDefined( actionData.playerCardPlayer ) && actionData.playerCardPlayer != self )
				self SetClientOmnvar( "ui_splash_killstreak_clientnum", actionData.playerCardPlayer GetEntityNumber() );
			else
				self SetClientOmnvar( "ui_splash_killstreak_clientnum", -1 );
			if( IsDefined( actionData.optionalNumber ) )
				self SetClientOmnvar( "ui_splash_killstreak_optional_number", actionData.optionalNumber );
			else
				self SetClientOmnvar( "ui_splash_killstreak_optional_number", 0 );	
			break;

		case "playercard_splash":
			if ( IsDefined( actionData.playerCardPlayer	) )	// actionData.playerCardPlayer could have disconnected during the wait
			{
				assert( IsPlayer( actionData.playerCardPlayer ) || IsAgent( actionData.playerCardPlayer ) );
				self SetClientOmnvar( "ui_splash_playercard_idx", splashIdx );
				self SetClientOmnvar( "ui_splash_playercard_clientnum", actionData.playerCardPlayer GetEntityNumber() );			
				if( IsDefined( actionData.optionalNumber ) )
					self SetClientOmnvar( "ui_splash_playercard_optional_number", actionData.optionalNumber );
			}
			break;

		case "splash":
		case "urgent_splash":
		case "intel_splash":
			self SetClientOmnvar( "ui_splash_idx", splashIdx );
			if( IsDefined( actionData.optionalNumber ) )
				self SetClientOmnvar( "ui_splash_optional_number", actionData.optionalNumber );
			break;
		case "challenge_splash":
		case "perk_challenge_splash":
			// we are reusing the the UpdateSplash omnvar handler in lua, so we only need a different main omnvar
			// the optional number is looked up in the function
			self SetClientOmnvar( "ui_challenge_splash_idx", splashIdx );
			if( IsDefined( actionData.optionalNumber ) )
				self SetClientOmnvar( "ui_challenge_splash_optional_number", actionData.optionalNumber );
			break;

		// 2013-09-02 wallace: promotion splashes now go into urgent_splash
//		case "promotion_splash":
//		case "promotion_weapon_splash":
//			break;
		
		case "mp_dig_all_perks_splash":
			self SetClientOmnvar( "ui_dig_killstreak_show", 1 );
			break;

		default:
			AssertMsg( "Splashes should have a type! FIX IT! Splash: " + actionData.name );
			break;
		}
	
		self.doingSplash[ slot ] = actionData;
	
		if ( IsDefined( actionData.sound ) )
			self PlayLocalSound( actionData.sound );
	
		if ( IsDefined( actionData.leaderSound ) )
		{
			if ( IsDefined( actionData.leaderSoundGroup ) )
				self leaderDialogOnPlayer( actionData.leaderSound, actionData.leaderSoundGroup, true );
			else
				self leaderDialogOnPlayer( actionData.leaderSound );
		}
	
		self notify ( "actionNotifyMessage" + slot );
		self endon ( "actionNotifyMessage" + slot );
	
		wait ( duration + 0.5 ); // wait the duration but put a buffer in between each splash

		self.doingSplash[ slot ] = undefined;
	}

	if ( self.splashQueue[ slot ].size )
		self thread dispatchNotify( slot );
}


// waits for waitTime, plus any time required to let flashbangs go away.
waitRequireVisibility( waitTime )
{
	interval = .05;
	
	while ( !self canReadText() )
		wait interval;
	
	while ( waitTime > 0 )
	{
		wait interval;
		if ( self canReadText() )
			waitTime -= interval;
	}
}


canReadText()
{
	if ( self maps\mp\_flashgrenades::isFlashbanged() )
		return false;
	
	return true;
}


resetOnDeath()
{
	self endon ( "notifyMessageDone" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self waittill ( "death" );

	resetNotify();
}


resetOnCancel()
{
	self notify ( "resetOnCancel" );
	self endon ( "resetOnCancel" );
	self endon ( "notifyMessageDone" );
	self endon ( "disconnect" );

	level waittill ( "cancel_notify" );
	
	resetNotify();
}


resetNotify()
{
	self.notifyTitle.alpha = 0;
	self.notifyText.alpha = 0;
	self.notifyIcon.alpha = 0;
	self.notifyOverlay.alpha = 0;
	
	self.doingSplash[0] = undefined;
	self.doingSplash[1] = undefined;
	self.doingSplash[2] = undefined;
	self.doingSplash[3] = undefined;
}


hintMessageDeathThink()
{
	self endon ( "disconnect" );

	for ( ;; )
	{
		self waittill ( "death" );
		
		if ( IsDefined( self.hintMessage ) )
			self.hintMessage destroyElem();
	}
}

lowerMessageThink()
{
	self endon ( "disconnect" );
	
	self.lowerMessages = [];
	
	lowerMessageFont = "default";
	if( isDefined ( level.lowerMessageFont ) )
		lowerMessageFont = level.lowerMessageFont;
	
	messageY = level.lowerTextY;
	messageFontSize = level.lowerTextFontSize;
	timerFontSize = 1.25;
	// checking IsAI because there is/was a code bug where ai would return true for IsSplitscreenPlayer
	if ( level.splitscreen || ( self isSplitscreenPlayer() && !IsAI( self ) ) )
	{
		messageY -= 40;
		messageFontSize = level.lowerTextFontSize * 1.3;
		timerFontSize *= 1.5;
	}

	self.lowerMessage = createFontString( lowerMessageFont, messageFontSize );
	self.lowerMessage setText( "" );
	self.lowerMessage.archived = false;
	self.lowerMessage.sort = 10;
	self.lowerMessage.showInKillcam = false;
	self.lowerMessage setPoint( "CENTER", level.lowerTextYAlign, 0, messageY );
	
	self.lowerTimer = createFontString( "default", timerFontSize );
	self.lowerTimer setParent( self.lowerMessage );
	self.lowerTimer setPoint( "TOP", "BOTTOM", 0, 0 );
	self.lowerTimer setText( "" );
	self.lowerTimer.archived = false;
	self.lowerTimer.sort = 10;
	self.lowerTimer.showInKillcam = false;
}


outcomeOverlay( winner )
{
	if ( level.teamBased )
	{
		if ( winner == "tie" )
			self matchOutcomeNotify( "draw" );
		else if ( winner == self.team )
			self matchOutcomeNotify( "victory" );
		else
			self matchOutcomeNotify( "defeat" );
	}
	else
	{
		if ( winner == self )
			self matchOutcomeNotify( "victory" );
		else
			self matchOutcomeNotify( "defeat" );
	}
}


matchOutcomeNotify( outcome )
{
	team = self.team;
	
	outcomeTitle = createFontString( "bigfixed", 1.0 );
	outcomeTitle setPoint( "TOP", undefined, 0, 50 );
	outcomeTitle.foreground = true;
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;

	outcomeTitle setText( game["strings"][outcome] );
	outcomeTitle.alpha = 0;
	outcomeTitle fadeOverTime( 0.5 );
	outcomeTitle.alpha = 1;	
	
	switch( outcome )
	{
		case "victory":
			outcomeTitle.glowColor = game["colors"]["cyan"];
			break;
		default:
			outcomeTitle.glowColor = game["colors"]["orange"];
			break;
	}

	centerIcon = createIcon( game["icons"][team], 64, 64 );
	centerIcon setParent( outcomeTitle );
	centerIcon setPoint( "TOP", "BOTTOM", 0, 30 );
	centerIcon.foreground = true;
	centerIcon.hideWhenInMenu = false;
	centerIcon.archived = false;
	centerIcon.alpha = 0;
	centerIcon fadeOverTime( 0.5 );
	centerIcon.alpha = 1;	
	
	wait ( 3.0 );
	
	outcomeTitle destroyElem();
	centerIcon destroyElem();
}


isDoingSplash()
{
	if ( IsDefined( self.doingSplash[0] ) )
		return true;

	if ( IsDefined( self.doingSplash[1] ) )
		return true;

	if ( IsDefined( self.doingSplash[2] ) )
		return true;

	if ( IsDefined( self.doingSplash[3] ) )
		return true;

	return false;		
}


teamOutcomeNotify( winner, isRound, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	// reset the ui_round_end_update_data so we can set it later
	self SetClientOmnvar( "ui_round_end_update_data", 0 );
	// make sure the round end menu shows
	self SetClientOmnvar( "ui_round_end", 1 );
	wait ( 0.5 );

	team = self.pers["team"];
	if ( self isMLGSpectator() )
		team = self GetMLGSpectatorTeam();
	if ( !IsDefined( team ) || (team != "allies" && team != "axis") )
		team = "allies";

	// wait for notifies to finish
	while ( self isDoingSplash() )
		wait 0.05;

	self endon ( "reset_outcome" );
		
	if ( winner == "halftime" )
	{
		self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "halftime" ] );
		winner = "allies";
	}
	else if ( winner == "intermission" )
	{
		self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "intermission" ] );
		winner = "allies";
	}
	else if ( winner == "roundend" )
	{
		self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "roundend" ] );
		winner = "allies";
	}
	else if ( winner == "overtime" )
	{
		self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "overtime" ] );
		winner = "allies";
	}
	else if ( winner == "tie" )
	{
		if ( isRound )
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "round_draw" ] );		
		else
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "draw" ] );		
		winner = "allies";
	}
	else if ( self IsMLGSpectator() )
	{
		//mlg spectator has no relative win or loss title, so leaving it blank in the case that we have a standard winner.
		self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "spectator" ] );
	}
	else if ( IsDefined( self.pers["team"] ) && winner == team )
	{
		if ( isRound )
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "round_win" ] );		
		else
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "victory" ] );		
	}
	else
	{
		if ( isRound )
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "round_loss" ] );		
		else
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "defeat" ] );		
	}
	
	self SetClientOmnvar( "ui_round_end_reason", endReasonText );		

	// Blitz was added in this check, because it is technically a round based game, even though we don't keep track of the score based on rounds won.
	if ( !isRoundBased() || !isObjectiveBased() || level.gameType == "Blitz" )
	{
		self SetClientOmnvar( "ui_round_end_friendly_score", maps\mp\gametypes\_gamescore::_getTeamScore( team ) );
		self SetClientOmnvar( "ui_round_end_enemy_score", maps\mp\gametypes\_gamescore::_getTeamScore( level.otherTeam[ team ] ) );
	}
	else
	{
		self SetClientOmnvar( "ui_round_end_friendly_score", game[ "roundsWon" ][ team ] );
		self SetClientOmnvar( "ui_round_end_enemy_score", game[ "roundsWon" ][ level.otherTeam[ team ] ] );
	}

	if ( IsDefined( self.matchBonus ) )
	{
		self SetClientOmnvar( "ui_round_end_match_bonus", self.matchBonus );
	}
	
	// update the data in the menu
	self SetClientOmnvar( "ui_round_end_update_data", 1 );	
}

outcomeNotify( winner, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	// reset the ui_round_end so we can set it later
	self SetClientOmnvar( "ui_round_end_update_data", 0 );
	// make sure the round end menu shows
	self SetClientOmnvar( "ui_round_end", 1 );
	wait ( 0.5 );

	// wait for notifies to finish
	while ( self isDoingSplash() )
		wait 0.05;

	self endon ( "reset_outcome" );

	players = level.placement["all"];
	firstPlace =	players[0];
	secondPlace =	players[1];
	thirdPlace =	players[2];

	// this is going to be non team based and we display the top three
	// if this player is tied for first then show the tie message
	tied = false;
	if( IsDefined( firstPlace ) && 
		self.score == firstPlace.score && 
		self.deaths == firstPlace.deaths )
	{
		if( self != firstPlace )
			tied = true;
		else
		{
			if( IsDefined( secondPlace ) && 
				secondPlace.score == firstPlace.score && 
				secondPlace.deaths == firstPlace.deaths )
			{
				tied = true;
			}			
		}
	}
	
	if( tied )
	{
		self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "tie" ] );		
	}
	else
	{
		if( IsDefined( firstPlace ) && self == firstPlace )
		{
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "victory" ] );		
		}
		else
		{
			self SetClientOmnvar( "ui_round_end_title", game[ "round_end" ][ "defeat" ] );		
		}
	}

	self SetClientOmnvar( "ui_round_end_reason", endReasonText );		

	if ( IsDefined( self.matchBonus ) )
	{
		self SetClientOmnvar( "ui_round_end_match_bonus", self.matchBonus );
	}

	// update the data in the menu
	self SetClientOmnvar( "ui_round_end_update_data", 1 );	

	self waittill( "update_outcome" );
	// it never makes it here because of the endon( "reset_outcome" ) above
}

canShowSplash( type )
{
	
}

get_table_name()
{
	if ( is_aliens() )
	{
		return "mp/alien/splashTable.csv";
	}
	return  "mp/splashTable.csv";
}
