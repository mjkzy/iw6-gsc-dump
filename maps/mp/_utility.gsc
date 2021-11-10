#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

KILLSTREAK_GIMME_SLOT = 0;
KILLSTREAK_SLOT_1 = 1;
KILLSTREAK_SLOT_2 = 2;
KILLSTREAK_SLOT_3 = 3;
KILLSTREAK_ALL_PERKS_SLOT = 4;
KILLSTREAK_STACKING_START_SLOT = 5;

MAX_VEHICLES = 8;

LIGHTWEIGHT_SCALAR = 1.07;

ATTACHMAP_TABLE					 = "mp/attachmentmap.csv";
ATTACHMAP_COL_CLASS_OR_WEAP_NAME = 0;
ATTACHMAP_ROW_ATTACH_BASE_NAME	 = 0;

ALIENS_ATTACHMAP_TABLE			 = "mp/alien/alien_attachmentmap.csv"; 
ALIENS_ATTACHMAP_COL_CLASS_OR_WEAP_NAME = 0;
ALIENS_ATTACHMAP_ROW_ATTACH_BASE_NAME	 = 0;

MAX_CUSTOM_DEFAULT_LOADOUTS = 6; // See recipes.raw: CustomGameClass defaultClasses[ PlayerGroup ][ 6 ];

exploder_sound()
{
	if ( isdefined( self.script_delay ) )
		wait self.script_delay;

	self playSound( level.scr_sound[ self.script_sound ] );
}

_beginLocationSelection ( streakName, selectorType, directionality , size )
{
	self BeginLocationSelection( selectorType, directionality, size );
	self.selectingLocation = true;
	self setblurforplayer( 10.3, 0.3 );
	
	self thread endSelectionOnAction( "cancel_location" );
	self thread endSelectionOnAction( "death" );
	self thread endSelectionOnAction( "disconnect" );
	self thread endSelectionOnAction( "used" );
	self thread endSelectionOnAction( "weapon_change" );
	
	self endon( "stop_location_selection" );
	self thread endSelectionOnEndGame();
	self thread endSelectionOnEMP();
	
	if ( IsDefined( streakName) && self.team != "spectator" )
	{
		if ( IsDefined( self.streakMsg ) )
			self.streakMsg destroy();				
		
		if( self IsSplitscreenPlayer() )
		{
			self.streakMsg = self maps\mp\gametypes\_hud_util::createFontString( "default", 1.3 );
			self.streakMsg maps\mp\gametypes\_hud_util::setPoint( "CENTER", "CENTER", 0 , -98 );
		}
		else
		{
			self.streakMsg = self maps\mp\gametypes\_hud_util::createFontString( "default", 1.6 );
			self.streakMsg maps\mp\gametypes\_hud_util::setPoint( "CENTER", "CENTER", 0 , -190 );
		}
		streakString = getKillstreakName( streakName );
		self.streakMsg setText( streakString );
	}
}

stopLocationSelection( disconnected, reason )
{
	if ( !IsDefined( reason ) )
		reason = "generic";
	
	if ( !disconnected )
	{
		self setblurforplayer( 0, 0.3 );
		self endLocationSelection();
		self.selectingLocation = undefined;
		
		if ( IsDefined( self.streakMsg ) )
			self.streakMsg destroy();
	}
	self notify( "stop_location_selection", reason );
}

endSelectionOnEMP()
{
	self endon( "stop_location_selection" );
	for ( ;; )
	{
		level waittill( "emp_update" );
	
		if ( !self isEMPed() )
			continue;
			
		self thread stopLocationSelection( false, "emp" );
		return;
	}
}

endSelectionOnAction( waitfor )
{
	self endon( "stop_location_selection" );
	self waittill( waitfor );
	self thread stopLocationSelection( (waitfor == "disconnect"), waitfor );
}

endSelectionOnEndGame()
{
	self endon( "stop_location_selection" );
	level waittill( "game_ended" );
	self thread stopLocationSelection( false, "end_game" );
}

isAttachment( attachmentName )
{
	if ( is_aliens() )
		attachment = tableLookup( "mp/alien/alien_attachmentTable.csv", 4, attachmentName, 0 );
	else
		attachment = tableLookup( "mp/attachmentTable.csv", 4, attachmentName, 0 );
	
	if( IsDefined( attachment ) && attachment != "" )
		return true;
	else
		return false;	
}

getAttachmentType( attachmentName )
{
	if ( is_aliens() )
		attachmentType = tableLookup( "mp/alien/alien_attachmentTable.csv", 4, attachmentName, 2 );
	else
		attachmentType = tableLookup( "mp/attachmentTable.csv", 4, attachmentName, 2 );

	return attachmentType;		
}

/*
saveModel()
{
	info["model"] = self.model;
	info["viewmodel"] = self getViewModel();
	attachSize = self getAttachSize();
	info["attach"] = [];
	
	assert(info["viewmodel"] != ""); // No viewmodel was associated with the player's model
	
	for(i = 0; i < attachSize; i++)
	{
		info["attach"][i]["model"] = self getAttachModelName(i);
		info["attach"][i]["tag"] = self getAttachTagName(i);
		info["attach"][i]["ignoreCollision"] = self getAttachIgnoreCollision(i);
	}
	
	return info;
}

loadModel(info)
{
	self detachAll();
	self setModel(info["model"]);
	self setViewModel(info["viewmodel"]);

	attachInfo = info["attach"];
	attachSize = attachInfo.size;
    
	for(i = 0; i < attachSize; i++)
		self attach(attachInfo[i]["model"], attachInfo[i]["tag"], attachInfo[i]["ignoreCollision"]);
}
*/

/* 
============= 
///ScriptDocBegin
"Name: delayThread( <delay>, <function>, <arg1>, <arg2>, <arg3>, <arg4> )"
"Summary: Delaythread is cool! It saves you from having to write extra script for once off commands. Note you don’t have to thread it off. Delaythread is that smart!"
"Module: Utility"
"MandatoryArg: <delay> : The delay before the function occurs"
"MandatoryArg: <delay> : The function to run."
"OptionalArg: <arg1> : parameter 1 to pass to the process"
"OptionalArg: <arg2> : parameter 2 to pass to the process"
"OptionalArg: <arg3> : parameter 3 to pass to the process"
"OptionalArg: <arg4> : parameter 4 to pass to the process"
"OptionalArg: <arg5> : parameter 5 to pass to the process"
"Example: delayThread( 3, ::flag_set, "player_can_rappel" );
"SPMP: both"
///ScriptDocEnd
============= 
*/ 
delayThread( timer, func, param1, param2, param3, param4, param5 )
{
	// to thread it off
	thread delayThread_proc( func, timer, param1, param2, param3, param4, param5 );
}


delayThread_proc( func, timer, param1, param2, param3, param4, param5 )
{
	wait( timer );
	if ( !IsDefined( param1 ) )
	{
		assertex( !isdefined( param2 ), "Delaythread does not support vars after undefined." );
		assertex( !isdefined( param3 ), "Delaythread does not support vars after undefined." );
		assertex( !isdefined( param4 ), "Delaythread does not support vars after undefined." );
		assertex( !isdefined( param5 ), "Delaythread does not support vars after undefined." );
		thread [[ func ]]();
	}
	else
	if ( !IsDefined( param2 ) )
	{
		assertex( !isdefined( param3 ), "Delaythread does not support vars after undefined." );
		assertex( !isdefined( param4 ), "Delaythread does not support vars after undefined." );
		assertex( !isdefined( param5 ), "Delaythread does not support vars after undefined." );
		thread [[ func ]]( param1 );
	}
	else
	if ( !IsDefined( param3 ) )
	{
		assertex( !isdefined( param4 ), "Delaythread does not support vars after undefined." );
		assertex( !isdefined( param5 ), "Delaythread does not support vars after undefined." );
		thread [[ func ]]( param1, param2 );
	}
	else
	if ( !IsDefined( param4 ) )	
	{
		assertex( !isdefined( param5 ), "Delaythread does not support vars after undefined." );
		thread [[ func ]]( param1, param2, param3 );
	}
	else
	if ( !IsDefined( param5 ) )	
	{
		thread [[ func ]]( param1, param2, param3, param4 );
	}
	else
	{
		thread [[ func ]]( param1, param2, param3, param4, param5 );
	}
}

// JC-ToDo: This should be in common script between sp and mp but it's late in the project.
array_contains_index( array, index )
{
	AssertEx( IsArray( array ), "array_contains_index() passed invalid array." );
	AssertEx( IsDefined( index ), "array_contains_index() passed undefind index." );
	
	foreach ( i, _ in array )
		if ( i == index )
			return true;
	return false;
}

getPlant()
{
	start = self.origin + ( 0, 0, 10 );

	range = 11;
	forward = anglesToForward( self.angles );
	forward = ( forward * range );

	traceorigins[ 0 ] = start + forward;
	traceorigins[ 1 ] = start;

	trace = bulletTrace( traceorigins[ 0 ], ( traceorigins[ 0 ] + ( 0, 0, -18 ) ), false, undefined );
	if ( trace[ "fraction" ] < 1 )
	{
		//println("^6Using traceorigins[0], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace[ "position" ];
		temp.angles = orientToNormal( trace[ "normal" ] );
		return temp;
	}

	trace = bulletTrace( traceorigins[ 1 ], ( traceorigins[ 1 ] + ( 0, 0, -18 ) ), false, undefined );
	if ( trace[ "fraction" ] < 1 )
	{
		//println("^6Using traceorigins[1], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace[ "position" ];
		temp.angles = orientToNormal( trace[ "normal" ] );
		return temp;
	}

	traceorigins[ 2 ] = start + ( 16, 16, 0 );
	traceorigins[ 3 ] = start + ( 16, -16, 0 );
	traceorigins[ 4 ] = start + ( -16, -16, 0 );
	traceorigins[ 5 ] = start + ( -16, 16, 0 );

	besttracefraction = undefined;
	besttraceposition = undefined;
	for ( i = 0; i < traceorigins.size; i++ )
	{
		trace = bulletTrace( traceorigins[ i ], ( traceorigins[ i ] + ( 0, 0, -1000 ) ), false, undefined );

		//ent[i] = spawn("script_model",(traceorigins[i]+(0, 0, -2)));
		//ent[i].angles = (0, 180, 180);
		//ent[i] setmodel("105");

		//println("^6trace ", i ," fraction is ", trace["fraction"]);

		if ( !isdefined( besttracefraction ) || ( trace[ "fraction" ] < besttracefraction ) )
		{
			besttracefraction = trace[ "fraction" ];
			besttraceposition = trace[ "position" ];

			//println("^6besttracefraction set to ", besttracefraction, " which is traceorigin[", i, "]");
		}
	}

	if ( besttracefraction == 1 )
		besttraceposition = self.origin;

	temp = spawnstruct();
	temp.origin = besttraceposition;
	temp.angles = orientToNormal( trace[ "normal" ] );
	return temp;
}

orientToNormal( normal )
{
	hor_normal = ( normal[ 0 ], normal[ 1 ], 0 );
	hor_length = length( hor_normal );

	if ( !hor_length )
		return( 0, 0, 0 );

	hor_dir = vectornormalize( hor_normal );
	neg_height = normal[ 2 ] * - 1;
	tangent = ( hor_dir[ 0 ] * neg_height, hor_dir[ 1 ] * neg_height, hor_length );
	plant_angle = vectortoangles( tangent );

	//println("^6hor_normal is ", hor_normal);
	//println("^6hor_length is ", hor_length);
	//println("^6hor_dir is ", hor_dir);
	//println("^6neg_height is ", neg_height);
	//println("^6tangent is ", tangent);
	//println("^6plant_angle is ", plant_angle);

	return plant_angle;
}

deletePlacedEntity( entity )
{
	entities = getentarray( entity, "classname" );
	for ( i = 0; i < entities.size; i++ )
	{
		//println("DELETED: ", entities[i].classname);
		entities[ i ] delete();
	}
}

playSoundOnPlayers( sound, team, excludeList )
{
	assert( isdefined( level.players ) );

	if ( level.splitscreen )
	{
		if ( isdefined( level.players[ 0 ] ) )
			level.players[ 0 ] playLocalSound( sound );
	}
	else
	{
		if ( IsDefined( team ) )
		{
			if ( isdefined( excludeList ) )
			{
				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[ i ];

					if( player isSplitscreenPlayer() && !player isSplitscreenPlayerPrimary() )
						continue;

					if ( isdefined( player.pers[ "team" ] ) && ( player.pers[ "team" ] == team ) && !isExcluded( player, excludeList ) )
						player playLocalSound( sound );
				}
			}
			else
			{
				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[ i ];

					if( player isSplitscreenPlayer() && !player isSplitscreenPlayerPrimary() )
						continue;

					if ( isdefined( player.pers[ "team" ] ) && ( player.pers[ "team" ] == team ) )
						player playLocalSound( sound );
				}
			}
		}
		else
		{
			if ( isdefined( excludeList ) )
			{
				for ( i = 0; i < level.players.size; i++ )
				{
					if( level.players[ i ] isSplitscreenPlayer() && !level.players[ i ] isSplitscreenPlayerPrimary() )
						continue;

					if ( !isExcluded( level.players[ i ], excludeList ) )
						level.players[ i ] playLocalSound( sound );
				}
			}
			else
			{
				for ( i = 0; i < level.players.size; i++ )
				{
					if( level.players[ i ] isSplitscreenPlayer() && !level.players[ i ] isSplitscreenPlayerPrimary() )
						continue;

					level.players[ i ] playLocalSound( sound );
				}
			}
		}
	}
}


sortLowerMessages()
{
	for ( i = 1; i < self.lowerMessages.size; i++ )
	{
		message = self.lowerMessages[ i ];
		priority = message.priority;
		for ( j = i - 1; j >= 0 && priority > self.lowerMessages[ j ].priority; j -- )
			self.lowerMessages[ j + 1 ] = self.lowerMessages[ j ];
		self.lowerMessages[ j + 1 ] = message;
	}
}


addLowerMessage( name, text, time, priority, showTimer, shouldFade, fadeToAlpha, fadeToAlphaTime, hideWhenInDemo, hideWhenInMenu )
{
	newMessage = undefined;
	foreach ( message in self.lowerMessages )
	{
		if ( message.name == name )
		{
			if ( message.text == text && message.priority == priority )
				return;

			newMessage = message;
			break;
		}
	}

	if ( !IsDefined( newMessage ) )
	{
		newMessage = spawnStruct();
		self.lowerMessages[ self.lowerMessages.size ] = newMessage;
	}

	newMessage.name = name;
	newMessage.text = text;
	newMessage.time = time;
	newMessage.addTime = getTime();
	newMessage.priority = priority;
	newMessage.showTimer = showTimer;
	newMessage.shouldFade = shouldFade;
	newMessage.fadeToAlpha = fadeToAlpha;
	newMessage.fadeToAlphaTime = fadeToAlphaTime;
	newMessage.hideWhenInDemo = hideWhenInDemo;
	newMessage.hideWhenInMenu = hideWhenInMenu;

	sortLowerMessages();
}


removeLowerMessage( name )
{
	if( IsDefined( self.lowerMessages ) )
	{
		// since we're changing the array in the loop, we should iterate backwards
		for ( i = self.lowerMessages.size; i > 0; i-- )
		{
			if ( self.lowerMessages[ i - 1 ].name != name )
				continue;

			message = self.lowerMessages[ i - 1 ];
			
			// now move every message down one to fill the empty space
			for( j = i; j < self.lowerMessages.size; j++ )
			{
				if ( IsDefined( self.lowerMessages[ j ] ) )
					self.lowerMessages[ j - 1 ] = self.lowerMessages[ j ];
			}

			// make the last one undefined because we filled the space above
			self.lowerMessages[ self.lowerMessages.size - 1 ] = undefined;
		}

		sortLowerMessages();
	}
}


getLowerMessage()
{
	if ( !isdefined( self.lowerMessages ) )
		return undefined;
	
	return self.lowerMessages[ 0 ];
}


/*
============= 
///ScriptDocBegin
"Name: setLowerMessage( <name>, <text>, <time>, <priority>, <showTimer>, <shouldFade>, <fadeToAlpha>, <fadeToAlphaTime> )"
"Summary: Creates a message to show on the lower half of the screen."
"Module: HUD"
"CallOn: A player"
"MandatoryArg: <name> The name of the message."
"MandatoryArg: <text> The text of the message to display."
"OptionalArg: <time> How long the message will display (default 0 - infinite)."
"OptionalArg: <priority> The priority of the message to display (default 1)."
"OptionalArg: <showTimer> If you pass in time do you want the timer text to show, if not then lower message will fade over time (default false)."
"OptionalArg: <shouldFade> If you want the message to fade to an alpha after coming up the first time (default false)."
"OptionalArg: <fadeToAlpha> If you want the message to fade to an alpha after coming up the first time, pass in the value (default 0.85)."
"OptionalArg: <fadeToAlphaTime> The time that this message will fade to the alpha value passed in before this (default 3.0)."
"OptionalArg: <hideWhenInDemo> Show hud when in demo playback (default false)."
"OptionalArg: <hideWhenInDemo> Hide hud when in a menu (default true)."
"Example: self setLowerMessage( "last_stand", &"PLATFORM_COWARDS_WAY_OUT", undefined, 50 );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
setLowerMessage( name, text, time, priority, showTimer, shouldFade, fadeToAlpha, fadeToAlphaTime, hideWhenInDemo, hideWhenInMenu )
{
	if ( !IsDefined( priority ) )
		priority = 1;

	if ( !IsDefined( time ) )
		time = 0;

	if ( !IsDefined( showTimer ) )
		showTimer = false;

	if ( !IsDefined( shouldFade ) )
		shouldFade = false;

	if ( !IsDefined( fadeToAlpha ) )
		fadeToAlpha = 0.85;

	if ( !IsDefined( fadeToAlphaTime ) )
		fadeToAlphaTime = 3.0;
		
	if ( !IsDefined( hideWhenInDemo ) )
		hideWhenInDemo = false;
	
	if ( !IsDefined( hideWhenInMenu ) )
		hideWhenInMenu = true;

	self addLowerMessage( name, text, time, priority, showTimer, shouldFade, fadeToAlpha, fadeToAlphaTime, hideWhenInDemo, hideWhenInMenu );
	self updateLowerMessage();
	//self notify( "lower_message_set" );
}


updateLowerMessage()
{
	if ( !isdefined( self ) )
		return;
	
	message = self getLowerMessage();

	if ( !IsDefined( message ) )
	{
		if ( isDefined ( self.lowerMessage ) && isDefined ( self.lowerTimer ) )
		{
			self.lowerMessage.alpha = 0;
			self.lowerTimer.alpha = 0;
		}
		return;
	}

	self.lowerMessage setText( message.text );
	self.lowerMessage.alpha = 0.85;
	self.lowerTimer.alpha = 1;
	
	self.lowerMessage.hideWhenInDemo = message.hideWhenInDemo;
	self.lowerMessage.hideWhenInMenu = message.hideWhenInMenu;
	
	if( message.shouldFade )
	{
		self.lowerMessage FadeOverTime( min( message.fadeToAlphaTime, 60 ) );
		self.lowerMessage.alpha = message.fadeToAlpha;
	}

	if ( message.time > 0 && message.showTimer )
	{
		self.lowerTimer setTimer( max( message.time - ( ( getTime() - message.addTime ) / 1000 ), 0.1 ) );
	}
	else if( message.time > 0 && !message.showTimer )
	{
		self.lowerTimer setText( "" );
		self.lowerMessage FadeOverTime( min( message.time, 60 ) );
		self.lowerMessage.alpha = 0;
		self thread clearOnDeath( message );
		self thread clearAfterFade( message );
	}
	else
	{
		self.lowerTimer setText( "" );
	}
}

clearOnDeath( message )
{
	self notify( "message_cleared" );
	self endon( "message_cleared" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "death" );
	self clearLowerMessage( message.name );
}

clearAfterFade( message )
{
	wait( message.time );
	self clearLowerMessage( message.name );
	self notify( "message_cleared" );
}

/*
============= 
///ScriptDocBegin
"Name: clearLowerMessage( <name> )"
"Summary: Clears the message on the lower portion of the screen."
"Module: HUD"
"CallOn: A player"
"MandatoryArg: <name> The name of the message."
"Example: self clearLowerMessage( "last_stand" );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
clearLowerMessage( name )
{
	self removeLowerMessage( name );
	self updateLowerMessage();
}

clearLowerMessages()
{
	for ( i = 0; i < self.lowerMessages.size; i++ )
		self.lowerMessages[ i ] = undefined;

	if ( !IsDefined( self.lowerMessage ) )
		return;

	self updateLowerMessage();
}

printOnTeam( printString, team )
{
	foreach ( player in level.players )
	{
		if ( player.team != team )
			continue;

		player iPrintLn( printString );
	}
}

printBoldOnTeam( text, team )
{
	assert( isdefined( level.players ) );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		if ( ( isdefined( player.pers[ "team" ] ) ) && ( player.pers[ "team" ] == team ) )
			player iprintlnbold( text );
	}
}

printBoldOnTeamArg( text, team, arg )
{
	assert( isdefined( level.players ) );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		if ( ( isdefined( player.pers[ "team" ] ) ) && ( player.pers[ "team" ] == team ) )
			player iprintlnbold( text, arg );
	}
}

printOnTeamArg( text, team, arg )
{
	assert( isdefined( level.players ) );
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		if ( ( isdefined( player.pers[ "team" ] ) ) && ( player.pers[ "team" ] == team ) )
			player iprintln( text, arg );
	}
}

printOnPlayers( text, team )
{
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		if ( IsDefined( team ) )
		{
			if ( ( isdefined( players[ i ].pers[ "team" ] ) ) && ( players[ i ].pers[ "team" ] == team ) )
				players[ i ] iprintln( text );
		}
		else
		{
			players[ i ] iprintln( text );
		}
	}
}

printAndSoundOnEveryone( team, otherteam, printFriendly, printEnemy, soundFriendly, soundEnemy, printarg )
{
	shouldDoSounds = IsDefined( soundFriendly );

	shouldDoEnemySounds = false;
	if ( IsDefined( soundEnemy ) )
	{
		assert( shouldDoSounds );// can't have an enemy sound without a friendly sound
		shouldDoEnemySounds = true;
	}

	if ( level.splitscreen || !shouldDoSounds )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];
			playerteam = player.team;
			if ( isdefined( playerteam ) )
			{
				if ( playerteam == team && isdefined( printFriendly ) )
					player iprintln( printFriendly, printarg );
				else if ( playerteam == otherteam && isdefined( printEnemy )  )
					player iprintln( printEnemy, printarg );
			}
		}
		if ( shouldDoSounds )
		{
			assert( level.splitscreen );
			level.players[ 0 ] playLocalSound( soundFriendly );
		}
	}
	else
	{
		assert( shouldDoSounds );
		if ( shouldDoEnemySounds )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[ i ];
				playerteam = player.team;
				if ( isdefined( playerteam ) )
				{
					if ( playerteam == team )
					{
						if ( isdefined( printFriendly ) )
							player iprintln( printFriendly, printarg );
						player playLocalSound( soundFriendly );
					}
					else if ( playerteam == otherteam )
					{
						if ( isdefined( printEnemy ) )
							player iprintln( printEnemy, printarg );
						player playLocalSound( soundEnemy );
					}
				}
			}
		}
		else
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[ i ];
				playerteam = player.team;
				if ( isdefined( playerteam ) )
				{
					if ( playerteam == team )
					{
						if ( isdefined( printFriendly ) )
							player iprintln( printFriendly, printarg );
						player playLocalSound( soundFriendly );
					}
					else if ( playerteam == otherteam )
					{
						if ( isdefined( printEnemy ) )
							player iprintln( printEnemy, printarg );
					}
				}
			}
		}
	}
}

printAndSoundOnTeam( team, printString, soundAlias )
{
	foreach ( player in level.players )
	{
		if ( player.team != team )
			continue;

		player printAndSoundOnPlayer( printString, soundAlias );
	}
}

printAndSoundOnPlayer( printString, soundAlias )
{
	self iPrintLn( printString );
	self playLocalSound( soundAlias );
}

_playLocalSound( soundAlias )
{
	if ( level.splitscreen && self getEntityNumber() != 0 )
		return;

	self playLocalSound( soundAlias );
}

dvarIntValue( dVar, defVal, minVal, maxVal )
{
	dVar = "scr_" + level.gameType + "_" + dVar;
	if ( getDvar( dVar ) == "" )
	{
		setDvar( dVar, defVal );
		return defVal;
	}

	value = getDvarInt( dVar );

	if ( value > maxVal )
		value = maxVal;
	else if ( value < minVal )
		value = minVal;
	else
		return value;

	setDvar( dVar, value );
	return value;
}

dvarFloatValue( dVar, defVal, minVal, maxVal )
{
	dVar = "scr_" + level.gameType + "_" + dVar;
	if ( getDvar( dVar ) == "" )
	{
		setDvar( dVar, defVal );
		return defVal;
	}

	value = getDvarFloat( dVar );

	if ( value > maxVal )
		value = maxVal;
	else if ( value < minVal )
		value = minVal;
	else
		return value;

	setDvar( dVar, value );
	return value;
}

play_sound_on_tag( alias, tag )
{
	if ( isdefined( tag ) )
	{
		playsoundatpos( self getTagOrigin( tag ), alias );
	}
	else
	{
		playsoundatpos( self.origin, alias );
	}
}

getOtherTeam( team )
{
	if( level.multiTeamBased )
	{
		assertMsg( "getOtherTeam() should not be called in Multi Team Based gametypes" );
	}
	
	if ( team == "allies" )
		return "axis";
	else if ( team == "axis" )
		return "allies";
	else
		return "none";

	assertMsg( "getOtherTeam: invalid team " + team );
}

wait_endon( waitTime, endOnString, endonString2, endonString3 )
{
	self endon( endOnString );
	if ( IsDefined( endonString2 ) )
		self endon( endonString2 );
	if ( IsDefined( endonString3 ) )
		self endon( endonString3 );

	wait( waitTime );
}

initPersStat( dataName )
{
	if ( !IsDefined( self.pers[ dataName ] ) )
		self.pers[ dataName ] = 0;
}

getPersStat( dataName )
{
	return self.pers[ dataName ];
}

incPersStat( dataName, increment, optionalDontStore )
{
	if ( IsDefined( self ) && IsDefined( self.pers ) && IsDefined( self.pers[ dataName ] ) )
	{	
		self.pers[ dataName ] += increment;
		
		if ( !IsDefined( optionalDontStore ) || optionalDontStore == false )
			self maps\mp\gametypes\_persistence::statAdd( dataName, increment );
	}
}

setPersStat( dataName, value )
{
	assertEx( IsDefined( dataName ), "Called setPersStat with no dataName defined." );
	assertEx( IsDefined( value ), "Called setPersStat for " + dataName + " with no value defined." );
	
	self.pers[ dataName ] = value;
}

initPlayerStat( ref, defaultvalue )
{
	if ( !IsDefined( self.stats["stats_" + ref ] ) )
	{
		if ( !IsDefined( defaultvalue ) )
			defaultvalue = 0;
		
		self.stats["stats_" + ref ] = spawnstruct();
		self.stats["stats_" + ref ].value = defaultvalue;
	}
}

incPlayerStat( ref, increment )
{
	if ( IsAgent(self) || IsBot( self ) )
		return;
	
	stat = self.stats["stats_" + ref ];
	stat.value += increment;
}

setPlayerStat( ref, value )
{
	stat = self.stats["stats_" + ref ];
	stat.value = value;
	stat.time = getTime();
}

getPlayerStat( ref )
{
	return self.stats["stats_" + ref ].value;
}

getPlayerStatTime( ref )
{
	return self.stats["stats_" + ref ].time;
}

setPlayerStatIfGreater( ref, newvalue )
{
	currentvalue = self getPlayerStat( ref );

	if ( newvalue > currentvalue )
		self setPlayerStat( ref, newvalue );
}

setPlayerStatIfLower( ref, newvalue )
{
	currentvalue = self getPlayerStat( ref );

	if ( newvalue < currentvalue )
		self setPlayerStat( ref, newvalue );
}

updatePersRatio( ratio, num, denom )
{
	if ( !self rankingEnabled() )
		return;

	numValue = self maps\mp\gametypes\_persistence::statGet( num );
	denomValue = self maps\mp\gametypes\_persistence::statGet( denom );
	if ( denomValue == 0 )
		denomValue = 1;

	self maps\mp\gametypes\_persistence::statSet( ratio, int( ( numValue * 1000 ) / denomValue ) );
}

updatePersRatioBuffered( ratio, num, denom )
{
	if ( !self rankingEnabled() )
		return;

	numValue = self maps\mp\gametypes\_persistence::statGetBuffered( num );
	denomValue = self maps\mp\gametypes\_persistence::statGetBuffered( denom );
	if ( denomValue == 0 )
		denomValue = 1;

	self maps\mp\gametypes\_persistence::statSetBuffered( ratio, int( ( numValue * 1000 ) / denomValue ) );
}


// to be used with things that are slow.
// unfortunately, it can only be used with things that aren't time critical.
WaitTillSlowProcessAllowed( allowLoop )
{
	// wait only a few frames if necessary
	// if we wait too long, we might get too many threads at once and run out of variables
	// i'm trying to avoid using a loop because i don't want any extra variables
	if ( level.lastSlowProcessFrame == gettime() )
	{
		if ( IsDefined( allowLoop ) && allowLoop )
		{
			while ( level.lastSlowProcessFrame == getTime() )
				wait( 0.05 );
		}
		else
		{
			wait .05;
			if ( level.lastSlowProcessFrame == gettime() )
			{
				wait .05;
				if ( level.lastSlowProcessFrame == gettime() )
				{
					wait .05;
					if ( level.lastSlowProcessFrame == gettime() )
					{
						wait .05;
					}
				}
			}
		}
	}

	level.lastSlowProcessFrame = getTime();
}


waitForTimeOrNotify( time, notifyname )
{
	self endon( notifyname );
	wait time;
}


isExcluded( entity, entityList )
{
	for ( index = 0; index < entityList.size; index++ )
	{
		if ( entity == entityList[ index ] )
			return true;
	}
	return false;
}


leaderDialog( dialog, team, group, excludeList, location )
{
	assert( isdefined( level.players ) );
	
	dialogName = game["dialog"][dialog];
	
	if ( !IsDefined( dialogName ) )
	{
		PrintLn( "Dialog " + dialog + " was not defined in game[dialog] array." );
		return;
	}
	
	alliesSoundName = game["voice"]["allies"] + dialogName;
	axisSoundName = game["voice"]["axis"] + dialogName;
	
	// Note that "team" may be undefined here, as in free-for-all matches. In those instances,
	// the dialog will be played for all players not specified in the exclude list as the documentation
	// states. Also note that the code will not directly aware of the client's "team" in non-team based
	// games (free-for-all). The dialog that plays for clients without a team will be the allies dialog.
	QueueDialog( alliesSoundName, axisSoundName, dialog, 2, team, group, excludeList, location );
}


leaderDialogOnPlayers( dialog, players, group, location )
{
	foreach ( player in players )
		player leaderDialogOnPlayer( dialog, group, undefined, location );
}


leaderDialogOnPlayer( dialog, group, groupOverride, location )
{
	if ( !IsDefined( game["dialog"][dialog] ) )
	{
		PrintLn( "Dialog " + dialog + " was not defined in game[dialog] array." );
		return;
	}
	
	team = self.pers["team"];
	if ( IsDefined( team ) && (team == "axis" || team == "allies" ) )
	{
		soundName = game["voice"][team] + game["dialog"][dialog];
		self QueueDialogForPlayer( soundName, dialog, 2, group, groupOverride, location );
	}
}


//this removes irrelevent dom dialog.  Not sure if this is needed with proper queuing. We will wait and see
getNextRelevantDialog()
{
	for( i = 0; i < self.leaderDialogQueue.size; i++ )
	{
		if ( IsSubStr( self.leaderDialogQueue[i], "losing" ) )
		{
			if ( self.team == "allies" )
			{
				if ( isSubStr( level.axisCapturing, self.leaderDialogQueue[i] ) )
					return self.leaderDialogQueue[i];
				else
					array_remove( self.leaderDialogQueue, self.leaderDialogQueue[i] );
			}
			else
			{
				if ( isSubStr( level.alliesCapturing, self.leaderDialogQueue[i] ) )
				    return self.leaderDialogQueue[i];
				else
					array_remove( self.leaderDialogQueue, self.leaderDialogQueue[i] );				
			}
		}
		else
		{
			return level.alliesCapturing[self.leaderDialogQueue];
		}
			
	}
}


OrderOnQueuedDialog()
{
	self endon( "disconnect" );
	
	tempArray = [];
	tempArray = self.leaderDialogQueue;
	
	//This re-orders arrays to move "losing" dialog higher in priority
	for( i = 0; i < self.leaderDialogQueue.size; i++ )
	{
		if ( isSubStr( self.leaderDialogQueue[i], "losing") )
		{
			for( c = i; c >= 0; c-- )
			{
				if ( !IsSubStr( self.leaderDialogQueue[ c ], "losing" ) && c != 0 )
					continue;
				
				if ( c != i )
				{
					arrayInsertion( tempArray, self.leaderDialogQueue[i], c );
					array_remove( tempArray, self.leaderDialogQueue[i] );
					break;
				}
			}
		}
	}
	
	self.leaderDialogQueue = tempArray;
}


updateMainMenu()
{
	if (self.pers[ "team" ] == "spectator" )
	{
		self setClientDvar("g_scriptMainMenu", game["menu_team"]);
	}
	else
	{
		self setClientDvar( "g_scriptMainMenu", game[ "menu_class_" + self.pers["team"] ] );
	}
}


updateObjectiveText()
{
	if ( self.pers[ "team" ] == "spectator" )
	{
		self setClientDvar( "cg_objectiveText", "" );
		return;
	}

	if ( getWatchedDvar( "scorelimit" ) > 0 && !isObjectiveBased() )
	{
		if ( IsDefined( getObjectiveScoreText( self.pers[ "team" ] ) ) )
		{
			if ( level.splitScreen )
				self setclientdvar( "cg_objectiveText", getObjectiveScoreText( self.pers[ "team" ] ) );
			else
				self setclientdvar( "cg_objectiveText", getObjectiveScoreText( self.pers[ "team" ] ), getWatchedDvar( "scorelimit" ) );
		}
	}
	else
	{
		if ( IsDefined( getObjectiveText( self.pers[ "team" ] ) ) )
			self setclientdvar( "cg_objectiveText", getObjectiveText( self.pers[ "team" ] ) );
	}
}


setObjectiveText( team, text )
{
	game[ "strings" ][ "objective_" + team ] = text;
}

setObjectiveScoreText( team, text )
{
	game[ "strings" ][ "objective_score_" + team ] = text;
}

setObjectiveHintText( team, text )
{
	game[ "strings" ][ "objective_hint_" + team ] = text;
}

getObjectiveText( team )
{
	return game[ "strings" ][ "objective_" + team ];
}

getObjectiveScoreText( team )
{
	return game[ "strings" ][ "objective_score_" + team ];
}

getObjectiveHintText( team )
{
	return game[ "strings" ][ "objective_hint_" + team ];
}

getTimePassed()
{
	if ( !IsDefined( level.startTime ) || !IsDefined( level.discardTime ) )
		return 0;
	
	if ( level.timerStopped )
		return( level.timerPauseTime - level.startTime ) - level.discardTime;
	else
		return( gettime() - level.startTime ) - level.discardTime;

}

getTimePassedPercentage()
{
	return ( getTimePassed() / (getTimeLimit() * 60 * 1000) ) * 100;
}

getSecondsPassed()
{
	return (getTimePassed() / 1000);
}

getMinutesPassed()
{
	return (getSecondsPassed() / 60);
}

ClearKillcamState()
{
	self.forcespectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.spectatekillcam = false;
}

isInKillcam()
{
	ASSERT( self.spectatekillcam == ( self.forcespectatorclient != -1 || self.killcamentity != -1 ) );
	return self.spectatekillcam;
}

isValidClass( class )
{
	return IsDefined( class ) && class != "";
}



getValueInRange( value, minValue, maxValue )
{
	if ( value > maxValue )
		return maxValue;
	else if ( value < minValue )
		return minValue;
	else
		return value;
}




waitForTimeOrNotifies( desiredDelay )
{
	startedWaiting = getTime();

	waitedTime = ( getTime() - startedWaiting ) / 1000;

	if ( waitedTime < desiredDelay )
	{
		wait desiredDelay - waitedTime;
		return desiredDelay;
	}
	else
	{
		return waitedTime;
	}
}

logXPGains()
{
	if ( !IsDefined( self.xpGains ) )
		return;

	xpTypes = getArrayKeys( self.xpGains );
	for ( index = 0; index < xpTypes.size; index++ )
	{
		gain = self.xpGains[ xpTypes[ index ] ];
		if ( !gain )
			continue;

		self logString( "xp " + xpTypes[ index ] + ": " + gain );
	}
}


registerRoundSwitchDvar( dvarString, defaultValue, minValue, maxValue )
{
	registerWatchDvarInt( "roundswitch", defaultValue );

	dvarString = ( "scr_" + dvarString + "_roundswitch" );

	level.roundswitchDvar = dvarString;
	level.roundswitchMin = minValue;
	level.roundswitchMax = maxValue;
	level.roundswitch = getDvarInt( dvarString, defaultValue );
	
	if ( level.roundswitch < minValue )
		level.roundswitch = minValue;
	else if ( level.roundswitch > maxValue )
		level.roundswitch = maxValue;
}


registerRoundLimitDvar( dvarString, defaultValue )
{
	registerWatchDvarInt( "roundlimit", defaultValue );
}

registerNumTeamsDvar( dvarString, defaultValue )
{
	registerWatchDvarInt( "numTeams", defaultValue );
}


registerWinLimitDvar( dvarString, defaultValue )
{
	registerWatchDvarInt( "winlimit", defaultValue );
}


registerScoreLimitDvar( dvarString, defaultValue )
{
	registerWatchDvarInt( "scorelimit", defaultValue );
}


registerTimeLimitDvar( dvarString, defaultValue )
{
	registerWatchDvarFloat( "timelimit", defaultValue );
	SetDvar( "ui_timelimit", getTimeLimit() );
}

registerHalfTimeDvar( dvarString, defaultValue ) 
{
	registerWatchDvarInt( "halftime", defaultValue );
	SetDvar( "ui_halftime", getHalfTime() );
}

registerNumLivesDvar( dvarString, defaultValue )
{
	registerWatchDvarInt( "numlives", defaultValue );
}

setOverTimeLimitDvar( value )
{
	SetDvar( "overtimeTimeLimit", value );
}

get_damageable_player( player, playerpos )
{
	newent = spawnstruct();
	newent.isPlayer = true;
	newent.isADestructable = false;
	newent.entity = player;
	newent.damageCenter = playerpos;
	return newent;
}

get_damageable_sentry( sentry, sentryPos )
{
	newent = spawnstruct();
	newent.isPlayer = false;
	newent.isADestructable = false;
	newent.isSentry = true;
	newent.entity = sentry;
	newent.damageCenter = sentryPos;
	return newent;
}

get_damageable_grenade( grenade, entpos )
{
	newent = spawnstruct();
	newent.isPlayer = false;
	newent.isADestructable = false;
	newent.entity = grenade;
	newent.damageCenter = entpos;
	return newent;
}

get_damageable_mine( mine, entpos )
{
	newent = spawnstruct();
	newent.isPlayer = false;
	newent.isADestructable = false;
	newent.entity = mine;
	newent.damageCenter = entpos;
	return newent;
}

get_damageable_player_pos( player )
{
	return player.origin + ( 0, 0, 32 );
}

getStanceCenter()
{
	if ( self GetStance() == "crouch" )
		center = self.origin + ( 0, 0, 24 );
	else if ( self GetStance() == "prone" )
		center = self.origin + ( 0, 0, 10 );
	else
		center = self.origin + ( 0, 0, 32 );
	
	return center;
}

get_damageable_grenade_pos( grenade )
{
	return grenade.origin;
}

// this should be a code function.
getDvarVec( dvarName )
{
	dvarString = getDvar( dvarName );

	if ( dvarString == "" )
		return( 0, 0, 0 );

	dvarTokens = strTok( dvarString, " " );

	if ( dvarTokens.size < 3 )
		return( 0, 0, 0 );

	setDvar( "tempR", dvarTokens[ 0 ] );
	setDvar( "tempG", dvarTokens[ 1 ] );
	setDvar( "tempB", dvarTokens[ 2 ] );

	return( ( getDvarFloat( "tempR" ), getDvarFloat( "tempG" ), getDvarFloat( "tempB" ) ) );
}

strip_suffix( lookupString, stripString )
{
	if ( lookupString.size <= stripString.size )
		return lookupString;

	if ( getSubStr( lookupString, lookupString.size - stripString.size, lookupString.size ) == stripString )
		return getSubStr( lookupString, 0, lookupString.size - stripString.size );

	return lookupString;
}

_takeWeaponsExcept( saveWeapon )
{
	weaponsList = self GetWeaponsListAll();
	
	foreach ( weapon in weaponsList )
	{
		if ( weapon == saveWeapon )
		{
			continue;	
		}
		else
		{
			self takeWeapon( weapon );
		}
	}
}

saveData()
{
	saveData = spawnstruct();

	saveData.offhandClass = self getOffhandSecondaryClass();
	saveData.actionSlots = self.saved_actionSlotData;

	saveData.currentWeapon = self getCurrentWeapon();

	weaponsList = self GetWeaponsListAll();
	saveData.weapons = [];
	foreach ( weapon in weaponsList )
	{
		if ( weaponInventoryType( weapon ) == "exclusive" )
			continue;
			
		if ( weaponInventoryType( weapon ) == "altmode" )
			continue;

		saveWeapon = spawnStruct();
		saveWeapon.name = weapon;
		saveWeapon.clipAmmoR = self getWeaponAmmoClip( weapon, "right" );
		saveWeapon.clipAmmoL = self getWeaponAmmoClip( weapon, "left" );
		saveWeapon.stockAmmo = self getWeaponAmmoStock( weapon );		
		/* save camo? */
		
		if ( IsDefined( self.throwingGrenade ) && self.throwingGrenade == weapon )
			saveWeapon.stockAmmo--;
		
		assert( saveWeapon.stockAmmo >= 0 );
		
		saveData.weapons[saveData.weapons.size] = saveWeapon;
	}
	
	self.script_saveData = saveData;
}


restoreData()
{
	saveData = self.script_saveData;

	self setOffhandSecondaryClass( saveData.offhandClass );

	foreach ( weapon in saveData.weapons )
	{		
		//if ( weapon.name == self.loadoutPrimary + "_mp" )
			self _giveWeapon( weapon.name, int(tableLookup( "mp/camoTable.csv", 1, self.loadoutPrimaryCamo, 0 )) );
		//else
		//self _giveWeapon( weapon.name );
			
		self setWeaponAmmoClip( weapon.name, weapon.clipAmmoR, "right" );
		if ( isSubStr( weapon.name, "akimbo" ) )
			self setWeaponAmmoClip( weapon.name, weapon.clipAmmoL, "left" );

		self setWeaponAmmoStock( weapon.name, weapon.stockAmmo );
	}

	foreach ( slotID, actionSlot in saveData.actionSlots )
		self _setActionSlot( slotID, actionSlot.type, actionSlot.item );

	if ( self getCurrentWeapon() == "none" )
	{
		weapon = saveData.currentWeapon;

		if ( weapon == "none" )
			weapon = self getLastWeapon();
		
		// Can remove this when "spawn" isn't used after final stand
		self setSpawnWeapon( weapon );
		self switchToWeapon( weapon );
	}
}


_setActionSlot( slotID, type, item )
{
	self.saved_actionSlotData[slotID].type = type;
	self.saved_actionSlotData[slotID].item = item;

	self setActionSlot( slotID, type, item );
}


isFloat( value )
{
	if ( int( value ) != value )
		return true;

	return false;
}

registerWatchDvarInt( nameString, defaultValue )
{
	dvarString = "scr_" + level.gameType + "_" + nameString;

	level.watchDvars[ dvarString ] = spawnStruct();
	level.watchDvars[ dvarString ].value = getDvarInt( dvarString, defaultValue );
	level.watchDvars[ dvarString ].type = "int";
	level.watchDvars[ dvarString ].notifyString = "update_" + nameString;
}


registerWatchDvarFloat( nameString, defaultValue )
{
	dvarString = "scr_" + level.gameType + "_" + nameString;

	level.watchDvars[ dvarString ] = spawnStruct();
	level.watchDvars[ dvarString ].value = getDvarFloat( dvarString, defaultValue );
	level.watchDvars[ dvarString ].type = "float";
	level.watchDvars[ dvarString ].notifyString = "update_" + nameString;
}


registerWatchDvar( nameString, defaultValue )
{
	dvarString = "scr_" + level.gameType + "_" + nameString;

	level.watchDvars[ dvarString ] = spawnStruct();
	level.watchDvars[ dvarString ].value = getDvar( dvarString, defaultValue );
	level.watchDvars[ dvarString ].type = "string";
	level.watchDvars[ dvarString ].notifyString = "update_" + nameString;
}


setOverrideWatchDvar( dvarString, value )
{
	dvarString = "scr_" + level.gameType + "_" + dvarString;
	level.overrideWatchDvars[dvarString] = value;
}


getWatchedDvar( dvarString )
{
	dvarString = "scr_" + level.gameType + "_" + dvarString;
	
	if ( IsDefined( level.overrideWatchDvars ) && IsDefined( level.overrideWatchDvars[dvarString] ) )
	{
		return level.overrideWatchDvars[dvarString];
	}	
	
	return( level.watchDvars[ dvarString ].value );
}


updateWatchedDvars()
{
	while ( game[ "state" ] == "playing" )
	{
		watchDvars = getArrayKeys( level.watchDvars );

		foreach ( dvarString in watchDvars )
		{
			if ( level.watchDvars[ dvarString ].type == "string" )
				dvarValue = getProperty( dvarString, level.watchDvars[ dvarString ].value );
			else if ( level.watchDvars[ dvarString ].type == "float" )
				dvarValue = getFloatProperty( dvarString, level.watchDvars[ dvarString ].value );
			else
				dvarValue = getIntProperty( dvarString, level.watchDvars[ dvarString ].value );

			if ( dvarValue != level.watchDvars[ dvarString ].value )
			{
				level.watchDvars[ dvarString ].value = dvarValue;
				level notify( level.watchDvars[ dvarString ].notifyString, dvarValue );
			}
		}

		wait( 1.0 );
	}
}


isRoundBased()
{
	if ( !level.teamBased )
		return false;

	if ( getWatchedDvar( "winlimit" ) != 1 && getWatchedDvar( "roundlimit" ) != 1 )
		return true;
	
	if ( level.gameType == "sr" || level.gameType == "sd" || level.gameType == "siege" )
		return true;

	return false;
}

isFirstRound()
{
	if ( !level.teamBased )
		return true;

	if ( getWatchedDvar( "roundlimit" ) > 1 && game[ "roundsPlayed" ] == 0 )
		return true;

	if ( getWatchedDvar( "winlimit" ) > 1 && game[ "roundsWon" ][ "allies" ] == 0 && game[ "roundsWon" ][ "axis" ] == 0 )
		return true;

	return false;
}

isLastRound()
{
	if ( !level.teamBased )
		return true;

	if ( getWatchedDvar( "roundlimit" ) > 1 && game[ "roundsPlayed" ] >= ( getWatchedDvar( "roundlimit" ) - 1 ) )
		return true;

	if ( getWatchedDvar( "winlimit" ) > 1 && game[ "roundsWon" ][ "allies" ] >= getWatchedDvar( "winlimit" ) - 1 && game[ "roundsWon" ][ "axis" ] >= getWatchedDvar( "winlimit" ) - 1 )
		return true;

	return false;
}


wasOnlyRound()
{
	if ( !level.teamBased )
		return true;
		
	if ( IsDefined( level.onlyRoundOverride ) )
		return false;

	if ( getWatchedDvar( "winlimit" ) == 1 && hitWinLimit() )
		return true;

	if ( getWatchedDvar( "roundlimit" ) == 1 )
		return true;

	return false;
}


wasLastRound()
{
	if ( level.forcedEnd )
		return true;

	if ( !level.teamBased )
		return true;

	if ( hitRoundLimit() || hitWinLimit() )
		return true;

	return false;
}

hitTimeLimit()
{
	if ( getWatchedDvar ( "timelimit" ) <= 0 )
		return false;
	
	timeleft = maps\mp\gametypes\_gamelogic::getTimeRemaining();
	
	if ( timeleft > 0 )
		return false;
	
	return true;
}

hitRoundLimit()
{
	if ( getWatchedDvar( "roundlimit" ) <= 0 )
		return false;

	return( game[ "roundsPlayed" ] >= getWatchedDvar( "roundlimit" ) );
}

hitScoreLimit()
{
	if ( isObjectiveBased()	 )
		return false;

	if ( getWatchedDvar( "scorelimit" ) <= 0 )
		return false;

	if ( level.teamBased )
	{
		if ( game[ "teamScores" ][ "allies" ] >= getWatchedDvar( "scorelimit" ) || game[ "teamScores" ][ "axis" ] >= getWatchedDvar( "scorelimit" ) )
			return true;
	}
	else
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];
			if ( IsDefined( player.score ) && player.score >= getWatchedDvar( "scorelimit" ) )
				return true;
		}
	}
	return false;
}

hitWinLimit()
{
	if ( getWatchedDvar( "winlimit" ) <= 0 )
		return false;

	if ( !level.teamBased )
		return true;

	if ( getRoundsWon( "allies" ) >= getWatchedDvar( "winlimit" ) || getRoundsWon( "axis" ) >= getWatchedDvar( "winlimit" ) )
		return true;

	return false;
}


getScoreLimit()
{
	if ( isRoundBased() )
	{
		if ( getWatchedDvar( "roundlimit" ) )
			return ( getWatchedDvar( "roundlimit" ) );			
		else
			return ( getWatchedDvar( "winlimit" ) );
	}
	else
	{
		return ( getWatchedDvar( "scorelimit" ) );
	}	
}


getRoundsWon( team )
{
	return game[ "roundsWon" ][ team ];
}


isObjectiveBased()
{
	return level.objectiveBased;
}


getTimeLimit()
{
	if ( inOvertime() && ( !IsDefined(game[ "inNukeOvertime" ]) || !game[ "inNukeOvertime" ] ) )
	{
		timeLimit = int( getDvar( "overtimeTimeLimit" ) );
		
		if ( IsDefined( timeLimit ) )
			return timeLimit;
		else
			return 1;
	}
	else if ( IsDefined(level.dd) && level.dd && IsDefined( level.bombexploded ) && level.bombexploded > 0 ) //to handle extra time added by dd bombs
	{
		return ( getWatchedDvar( "timelimit" ) + ( level.bombexploded * level.ddTimeToAdd ) );
	}
	else
	{
		return getWatchedDvar( "timelimit" );
	}
}


getHalfTime()
{
	if ( inOvertime() )
		return false;
	else if ( IsDefined( game[ "inNukeOvertime" ] ) && game[ "inNukeOvertime" ] )
		return false;
	else
		return getWatchedDvar( "halftime" );
}


inOvertime()
{
	return ( IsDefined( game["status"] ) && game["status"] == "overtime" );
}


gameHasStarted()
{
	if( IsDefined(level.gameHasStarted) )
		return level.gameHasStarted;
		
	if( level.teamBased )
		return( level.hasSpawned[ "axis" ] && level.hasSpawned[ "allies" ] );
	
	return( level.maxPlayerCount > 1 );
}


getAverageOrigin( ent_array )
{
	avg_origin = ( 0, 0, 0 );

	if ( !ent_array.size )
		return undefined;

	foreach ( ent in ent_array )
		avg_origin += ent.origin;

	avg_x = int( avg_origin[ 0 ] / ent_array.size );
	avg_y = int( avg_origin[ 1 ] / ent_array.size );
	avg_z = int( avg_origin[ 2 ] / ent_array.size );

	avg_origin = ( avg_x, avg_y, avg_z );

	return avg_origin;
}


getLivingPlayers( team )
{
	player_array = [];

	foreach ( player in level.players )
	{
		if ( !isAlive( player ) )
			continue;

		if ( level.teambased && isdefined( team ) )
		{
			if ( team == player.pers[ "team" ] )
				player_array[ player_array.size ] = player;
		}
		else
		{
			player_array[ player_array.size ] = player;
		}
	}

	return player_array;
}


setUsingRemote( remoteName )
{
	if ( IsDefined( self.carryIcon) )
		self.carryIcon.alpha = 0;
	
	assert( !self isUsingRemote() );
	self.usingRemote = remoteName;

	self _disableOffhandWeapons();
	self notify( "using_remote" );
}

getRemoteName()
{
	assert( self isUsingRemote() );
	
	return self.usingRemote;	
}

freezeControlsWrapper( frozen )
{
	if ( IsDefined( level.hostMigrationTimer ) )
	{
		println( "Migration Wrapper freezing controls for " + maps\mp\gametypes\_hostMigration::hostMigrationName( self ) + " with frozen = " + frozen );
		self.hostMigrationControlsFrozen = true;
		self freezeControls( true );
		return;
	}
	
	self freezeControls( frozen );
	self.controlsFrozen = frozen;
}


clearUsingRemote()
{
	//if ( !isWeaponEnabled() )
	//	self disableWeapons();

	if ( IsDefined( self.carryIcon) )
		self.carryIcon.alpha = 1;

	self.usingRemote = undefined;
	self _enableOffhandWeapons();
	
	curWeapon = self getCurrentWeapon();
	
	if( curWeapon == "none" || isKillstreakWeapon( curWeapon ) )
	{
		lastWeapon = self Getlastweapon();
		
		if ( isReallyAlive( self ) )
		{
			if( !self HasWeapon( lastWeapon ) )
				lastWeapon = self  maps\mp\killstreaks\_killstreaks::getFirstPrimaryWeapon();			
				
			self switchToWeapon( lastWeapon );	
		}
	}
	
	self freezeControlsWrapper( false );
	
	self notify( "stopped_using_remote" );
}


/*
============= 
///ScriptDocBegin
"Name: isUsingRemote()"
"Summary: Returns true if the player is using a remote to control something and isn't in their body."
"Module: Utility"
"CallOn: Player"
"Example: if( player isUsingRemote() )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isUsingRemote()
{
	return( IsDefined( self.usingRemote ) );
}


isRocketCorpse()
{
	return ( IsDefined( self.isRocketCorpse ) && self.isRocketCorpse );
}


queueCreate( queueName )
{
	if ( !IsDefined( level.queues ) )
		level.queues = [];

	assert( !IsDefined( level.queues[ queueName ] ) );

	level.queues[ queueName ] = [];
}


queueAdd( queueName, entity )
{
	assert( IsDefined( level.queues[ queueName ] ) );
	level.queues[ queueName ][ level.queues[ queueName ].size ] = entity;
}


queueRemoveFirst( queueName )
{
	assert( IsDefined( level.queues[ queueName ] ) );

	first = undefined;
	newQueue = [];
	foreach ( element in level.queues[ queueName ] )
	{
		if ( !IsDefined( element ) )
			continue;

		if ( !IsDefined( first ) )
			first = element;
		else
			newQueue[ newQueue.size ] = element;
	}

	level.queues[ queueName ] = newQueue;

	return first;
}


_giveWeapon( weapon, variant, dualWieldOverRide )
{
	if ( !IsDefined(variant) )
		variant = -1;
	
	if ( isSubstr( weapon, "_akimbo" ) || IsDefined(dualWieldOverRide) && dualWieldOverRide == true)
		self giveWeapon(weapon, variant, true);
	else
		self giveWeapon(weapon, variant, false);
}

/*
=============
///ScriptDocBegin
"Name: perksEnabled()"
"Summary: Checks the scr_game_perks dvar to see if perks are allowed."
"Module: Utility"
"Example: if ( perkEnabled() ) party();"
"SPMP: multiplayer
///ScriptDocEnd
=============
*/

perksEnabled()
{
	return GetDvarInt ( "scr_game_perks" ) == 1;
}

/*
============= 
///ScriptDocBegin
"Name: _hasPerk( <perkName> )"
"Summary: Does the player have this perk?"
"Module: Player"
"CallOn: A Player"
"MandatoryArg: <perkName> The of the perk from perkTable.csv."
"Example: if( self _hasPerk( "specialty_scavenger" ) )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
_hasPerk( perkName )
{
	perks = self.perks;
	
	if ( !IsDefined( perks ) )
		return false;
	
	if ( IsDefined( perks[ perkName ] ) )
		return true;
	
	return false;
}

/*
============= 
///ScriptDocBegin
"Name: givePerk( <perkName>, <useSlot> )"
"Summary: Gives the perk to the player."
"Module: Player"
"CallOn: A Player"
"MandatoryArg: <perkName> The of the perk from PerkTable.csv."
"MandatoryArg: <useSlot> Boolean, should we put this perk in a perk slot. This should be true if the perks are the CAC selected perks."
"Example: self givePerk( "specialty_pistoldeath", false );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
givePerk( perkName, useSlot )
{
	AssertEx( IsDefined( perkName ), "givePerk perkName not defined and should be" );
	AssertEx( IsDefined( useSlot ), "givePerk useSlot not defined and should be" );
	AssertEx( !IsSubStr( perkName, "specialty_null" ), "givePerk perkName shouldn't be specialty_null, use _clearPerks()s" );
	AssertEx( !IsSubStr( perkName, "none" ), "givePerk perkName shouldn't be none, use _clearPerks()s" );

	if( IsSubStr( perkName, "specialty_weapon_" ) )
	{
		self _setPerk( perkName, useSlot );
		return;
	}

	self _setPerk( perkName, useSlot );

	self _setExtraPerks( perkName );
}

/*
============= 
///ScriptDocBegin
"Name: givePerkEquipment( <perkName>, <useSlot> )"
"Summary: Gives the equipment perk to the player."
"Module: Player"
"CallOn: A Player"
"MandatoryArg: <perkName> The of the perk from PerkTable.csv."
"MandatoryArg: <useSlot> Boolean, should we put this perk in a perk slot. This should be true if the perks are the CAC selected perks."
"Example: self givePerkEquipment( "frag_grenade_mp", true );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
givePerkEquipment( perkName, useSlot )
{
	AssertEx( IsDefined( perkName ), "givePerkEquipment perkName not defined and should be" );
	AssertEx( IsDefined( useSlot ), "givePerkEquipment useSlot not defined and should be" );

	if( perkName == "none" || perkName == "specialty_null" )
	{
		self SetOffhandPrimaryClass( "none" );
		return;
	}

	self.primaryGrenade = perkName;

	if( IsSubStr( perkName, "_mp" ) )
	{
		switch( perkName )
		{
		case "frag_grenade_mp":
		case "mortar_shell_mp":
		case "mortar_shelljugg_mp":
			self SetOffhandPrimaryClass( "frag" );
			break;
		case "throwingknife_mp":
		case "throwingknifejugg_mp":
			self SetOffhandPrimaryClass( "throwingknife" );
			break;
		case "trophy_mp":
		case "flash_grenade_mp":
		case "emp_grenade_mp":
		case "motion_sensor_mp":
		case "thermobaric_grenade_mp":
			self SetOffhandPrimaryClass( "flash" );
			break;
		case "smoke_grenade_mp":
		case "smoke_grenadejugg_mp":
		case "concussion_grenade_mp":
			self SetOffhandPrimaryClass( "smoke" );
			break;
		default:
			self SetOffhandPrimaryClass( "other" );
			break;
		}

		self _giveWeapon( perkName, 0 );
		
		self GiveStartAmmo( perkName );

		self _setPerk( perkName, useSlot );
	}
	else
		self _setPerk( perkName, useSlot );
}

/*
============= 
///ScriptDocBegin
"Name: givePerkOffhand( <perkName>, <useSlot> )"
"Summary: Gives the offhand perk to the player."
"Module: Player"
"CallOn: A Player"
"MandatoryArg: <perkName> The of the perk from PerkTable.csv."
"MandatoryArg: <useSlot> Boolean, should we put this perk in a perk slot. This should be true if the perks are the CAC selected perks."
"Example: self givePerkOffhand( "flash_grenade_mp", false );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
givePerkOffhand( perkName, useSlot )
{
	AssertEx( IsDefined( perkName ), "givePerkOffhand perkName not defined and should be" );
	AssertEx( IsDefined( useSlot ), "givePerkOffhand useSlot not defined and should be" );

	if( perkName == "none" || perkName == "specialty_null" )
	{
		self SetOffhandSecondaryClass( "none" );
		return;
	}

	self.secondaryGrenade = perkName;

	if( IsSubStr( perkName, "_mp" ) )
	{
		switch( perkName )
		{
		case "frag_grenade_mp":
		case "mortar_shell_mp":
		case "mortar_shelljugg_mp":
			self SetOffhandSecondaryClass( "frag" );
			break;
		case "throwingknife_mp":
		case "throwingknifejugg_mp":
			self SetOffhandSecondaryClass( "throwingknife" );
			break;
		case "trophy_mp":
		case "flash_grenade_mp":
		case "emp_grenade_mp":
		case "motion_sensor_mp":
		case "thermobaric_grenade_mp":
			self SetOffhandSecondaryClass( "flash" );
			break;
		case "smoke_grenade_mp":
		case "smoke_grenadejugg_mp":
		case "concussion_grenade_mp":
			self SetOffhandSecondaryClass( "smoke" );
			break;
		default:
			self SetOffhandSecondaryClass( "other" );
			break;
		}

		self _giveWeapon( perkName, 0 );

		switch( perkName )
		{
		case "concussion_grenade_mp":
		case "flash_grenade_mp":
		case "smoke_grenade_mp":
		case "emp_grenade_mp":
		case "motion_sensor_mp":
		case "trophy_mp":
		case "thermobaric_grenade_mp":
			self SetWeaponAmmoClip( perkName, 1 );
			break;
		default:
			self GiveStartAmmo( perkName );
			break;
		}

		self _setPerk( perkName, useSlot );
	}
	else
		self _setPerk( perkName, useSlot );
}

// please call givePerk
_setPerk( perkName, useSlot )
{
	AssertEx( IsDefined( perkName ), "_setPerk perkName not defined and should be" );
	AssertEx( IsDefined( useSlot ), "_setPerk useSlot not defined and should be" );

	self.perks[ perkName ] = true;
	self.perksPerkName[ perkName ] = perkName;
	self.perksUseSlot[ perkName ] = useSlot;
	
	perkSetFunc = level.perkSetFuncs[ perkName ];
	
	if ( IsDefined( perkSetFunc ) )
	{
		self thread [[ perkSetFunc ]]();
	}
		
	self setPerk( perkName, !IsDefined( level.scriptPerks[perkName] ), useSlot );
}

_setExtraPerks( perkName )
{
	// 2013-05-24 wsh
	// This function is where we gave extra perks associated with a Pro perk (in prev MW's)
	// The new ability system doesn't require this
	// assassin pro gives immune to cuav and emp and no red name/crosshair when targeted
	// but, we do want to make sure that AssasinPro still blocks emp
	if( perkName == "specialty_stun_resistance" )
		self givePerk( "specialty_empimmune", false );
	
	if( perkName == "specialty_hardline" )
		self givePerk( "specialty_assists", false );
	
	if( perkName == "specialty_incog" )
	{
		self givePerk( "specialty_spygame", false );
		self givePerk( "specialty_coldblooded", false );
		self givePerk( "specialty_noscopeoutline", false);
		self givePerk( "specialty_heartbreaker", false );
	}
	
	if( perkName == "specialty_blindeye" )
		self givePerk( "specialty_noplayertarget", false );
   	
	if( perkName == "specialty_sharp_focus" )
		self givePerk( "specialty_reducedsway", false );
	
	if( perkName == "specialty_quickswap" )
		self givePerk( "specialty_fastoffhand", false );
			
	/*
	// steady aim will have accurate hip fire and accurate hip fire while moving as the base
	//if( perkName == "specialty_bulletaccuracy" )
	//	self givePerk( "specialty_steadyaimpro", false );
	// assassin will have immune to uav, thermal, and heartbeat sensors on the base
	if( perkName == "specialty_coldblooded" )
		self givePerk( "specialty_heartbreaker", false );
	// blindeye pro gives quicker lockon (perktable) and extra vehicle damage with bullets
	if( perkName == "specialty_fasterlockon" )
		self givePerk( "specialty_armorpiercing", false );
	// assassin pro gives immune to cuav and emp and no red name/crosshair when targeted
	if( perkName == "specialty_spygame" )
		self givePerk( "specialty_empimmune", false );
	// hardline pro gives every two assists count towards a killstreak kill
	if( perkName == "specialty_rollover" )
		self givePerk( "specialty_assists", false );
	*/
}

_unsetPerk( perkName )
{
	self.perks[perkName] = undefined;
	self.perksPerkName[ perkName ] = undefined;
	self.perksUseSlot[ perkName ] = undefined;

	if ( IsDefined( level.perkUnsetFuncs[perkName] ) )
		self thread [[level.perkUnsetFuncs[perkName]]]();

	self unsetPerk( perkName, !IsDefined( level.scriptPerks[perkName] ) );
}

_unsetExtraPerks( perkName )
{
	// steady aim will have accurate hip fire and accurate hip fire while moving as the base
	if( perkName == "specialty_bulletaccuracy" )
		self _unsetPerk( "specialty_steadyaimpro" );
	// assassin will have immune to uav, thermal, and heartbeat sensors on the base
	if( perkName == "specialty_coldblooded" )
		self _unsetPerk( "specialty_heartbreaker" );
	// blindeye pro gives quicker lockon (perktable) and extra vehicle damage with bullets
	if( perkName == "specialty_fasterlockon" )
		self _unsetPerk( "specialty_armorpiercing" );
	// assassin pro gives immune to cuav and emp and no red name/crosshair when targeted
	if( perkName == "specialty_heartbreaker" )
		self _unsetPerk( "specialty_empimmune" );
	// hardline pro gives every two assists count towards a killstreak kill
	if( perkName == "specialty_rollover" )
		self _unsetPerk( "specialty_assists" );
}

_clearPerks()
{
	foreach ( perkName, perkValue in self.perks )
	{
		if ( IsDefined( level.perkUnsetFuncs[perkName] ) )
			self [[level.perkUnsetFuncs[perkName]]]();
	}
	
	self.perks = [];
	self.perksPerkName = [];
	self.perksUseSlot = [];
	self clearPerks();
}

// Quick Sort - pass it an array it will come back sorted
quickSort(array) 
{
	return quickSortMid(array, 0, array.size -1 );     
}

quickSortMid(array, start, end)
{
	i = start;
	k = end;

	if (end - start >= 1)
    {
        pivot = array[start];  

        while (k > i)         
        {
	        while (array[i] <= pivot && i <= end && k > i)  
	        	i++;                                 
	        while (array[k] > pivot && k >= start && k >= i) 
	            k--;                                      
	        if (k > i)                                 
	           array = swap(array, i, k);                    
        }
        array = swap(array, start, k);                                               
        array = quickSortMid(array, start, k - 1); 
        array = quickSortMid(array, k + 1, end);   
    }
	else
    	return array;
    
    return array;
}

swap(array, index1, index2) 
{
	temp = array[index1];          
	array[index1] = array[index2];     
	array[index2] = temp;   
	return array;         
}

_suicide()
{
	if ( self isUsingRemote() && !IsDefined( self.fauxDead ) )
		self thread maps\mp\gametypes\_damage::PlayerKilled_internal( self, self, self, 10000, "MOD_SUICIDE", "frag_grenade_mp", (0,0,0), "none", 0, 1116, true );
	else if( !self isUsingRemote() && !IsDefined( self.fauxDead ) )
		self suicide();	
}

/*
=============
///ScriptDocBegin
"Name: isReallyAlive( <player> )"
"Summary: This makes sure the player is dead and also not fauxDead. This is better than just the isAlive() call."
"Module: Player"
"CallOn: player"
"MandatoryArg: <player> The player entity to check."
"Example: if( !isReallyAlive( player ) )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
isReallyAlive( player )
{
	if ( isAlive( player ) && !IsDefined( player.fauxDead ) )
		return true;
		
	return false;
}

/*
=============
///ScriptDocBegin
"Name: waittill_any_timeout_pause_on_death_and_prematch( <timeOut> , <string1> , <string2> , <string3> , <string4> , <string5> )"
"Summary: This will pause the timeout counter on death and prematch. Then start after alive or prematch is over."
"Module: Utility"
"CallOn: An entity"
"MandatoryArg: <param1> The time in seconds to wait for timeout."
"OptionalArg: <param2> The waittill strings to wait on."
"Example: self waittill_any_timeout_pause_on_death_and_prematch( 5.0, "finished" );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
waittill_any_timeout_pause_on_death_and_prematch( timeOut, string1, string2, string3, string4, string5 )
{
	ent = spawnstruct();

	if ( isdefined( string1 ) )
		self thread waittill_string_no_endon_death( string1, ent );

	if ( isdefined( string2 ) )
		self thread waittill_string_no_endon_death( string2, ent );

	if ( isdefined( string3 ) )
		self thread waittill_string_no_endon_death( string3, ent );

	if ( isdefined( string4 ) )
		self thread waittill_string_no_endon_death( string4, ent );

	if ( isdefined( string5 ) )
		self thread waittill_string_no_endon_death( string5, ent );

	ent thread _timeout_pause_on_death_and_prematch( timeOut, self );

	ent waittill( "returned", msg );
	ent notify( "die" );
	return msg;
}

_timeout_pause_on_death_and_prematch( delay, ent )
{
	self endon( "die" );

	inc = 0.05;
	while( delay > 0 )
	{
		if( IsPlayer( ent ) && !isReallyAlive( ent ) )
		{
			ent waittill( "spawned_player" );
		}
		if( GetOmnvar( "ui_prematch_period" ) )
		{
			level waittill( "prematch_over" );
		}

		wait( inc );
		delay -= inc;
	}
	self notify( "returned", "timeout" );
}

playDeathSound()
{
	rand = RandomIntRange( 1,8 );

	type = "generic";
	if ( self hasFemaleCustomizationModel() )
		type = "female";

	if ( self.team == "axis" )
		self PlaySound( type + "_death_russian_"+ rand );	
	else
		self PlaySound( type + "_death_american_"+ rand );
}


rankingEnabled()
{
	if ( !isPlayer( self ) )
		return false;
	
	return ( level.rankedMatch && !self.usingOnlineDataOffline );
}

// only true for private match
privateMatch()
{
	return ( level.onlineGame && getDvarInt( "xblive_privatematch" ) );
}

// only true for playlist based LIVE and PSN games
matchMakingGame()
{
	return ( level.onlineGame && !getDvarInt( "xblive_privatematch" ) );
}

setAltSceneObj( object, tagName, fov, forceLink )
{
	/*
	if ( !IsDefined( forceLink ) )
		forceLink = false;

	if ( !getDvarInt( "scr_pipmode" ) && !forceLink )
		return;
	
	self endon ( "disconnect" );

	if ( !isReallyAlive( self ) )
		return;

	if ( !forceLink && IsDefined( self.altSceneObject ) )
		return;

	self notify ( "altscene" );
	
	self.altSceneObject = object;

	self AlternateSceneCameraLinkTo( object, tagName, fov );
	self setClientDvar( "ui_altscene", 1 );
	
	self thread endSceneOnDeath( object );
	self thread endSceneOnDeath( self );
	
	self waittill ( "end_altScene" );
	
	self.altSceneObject = undefined;
	self AlternateSceneCameraUnlink();
	
	if ( !forceLink )
	{
		self setClientDvar( "ui_altscene", 2 );
	
		self endon ( "altscene" );
		wait ( 2.0 );
	}
	self setClientDvar( "ui_altscene", 0 );	
	*/
}


endSceneOnDeath( object )
{
	self endon ( "altscene" );
	
	object waittill ( "death" );
	self notify ( "end_altScene" );
}


getGametypeNumLives()
{
	//commented out to allow diehardhard rules to support mulitiple life gametypes
	//if ( level.dieHardMode && !getWatchedDvar( "numlives" ) )
	//	return 1;
	//else
		return getWatchedDvar( "numlives" );
}


giveCombatHigh( combatHighName )
{
	self.combatHigh = combatHighName;
}


arrayInsertion( array, item, index )
{
	if ( array.size != 0 )
	{
		for ( i = array.size; i >= index; i-- )
		{
			array[i+1] = array[i];
		}
	}
	
	array[index] = item;
}


getProperty( dvar, defValue )
{
	value = defValue;
	/#
	setDevDvarIfUninitialized( dvar, defValue );
	#/

	value = getDvar( dvar, defValue );
	return value;
}


getIntProperty( dvar, defValue )
{
	value = defValue;

	/#
	setDevDvarIfUninitialized( dvar, defValue );
	#/

	value = getDvarInt( dvar, defValue );
	return value;
}


getFloatProperty( dvar, defValue )
{
	value = defValue;
	/#
	setDevDvarIfUninitialized( dvar, defValue );
	#/

	value = getDvarFloat( dvar, defValue );
	return value;
}

isChangingWeapon()
{
	return ( IsDefined( self.changingWeapon ) );
}

killShouldAddToKillstreak( weapon )
{	
	if ( weapon == "venomxgun_mp" || weapon == "venomxproj_mp" )
		return true;
	
	if ( self _hasPerk( "specialty_explosivebullets" ) )	
		return false;	
		
	if ( IsDefined( self.isJuggernautRecon ) && self.isJuggernautRecon == true )
		return false;
	
	self_pers_killstreaks = self.pers["killstreaks"];
		
	//	allow only these killstreaks
	if( IsDefined( level.killstreakWeildWeapons[ weapon ] ) && IsDefined( self.streakType ) && self.streakType != "support" )
	{
		//	only if it came from an earn slot (1-3, 0 is gimme slot, 4 or more is stacked in the gimme slot)
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			// only if it was earned this life
			if( IsDefined( self_pers_killstreaks[i] ) && 
				IsDefined( self_pers_killstreaks[i].streakName ) &&
				self_pers_killstreaks[i].streakName == level.killstreakWeildWeapons[ weapon ] && 
				IsDefined( self_pers_killstreaks[i].lifeId ) && 
				self_pers_killstreaks[i].lifeId == self.pers["deaths"] )
			{
				return self streakShouldChain( level.killstreakWeildWeapons[ weapon ] );
			}
		}		
		return false;
	}
		
	return !isKillstreakWeapon( weapon );	
}

streakShouldChain( streakName )
{
	currentStreakCost = maps\mp\killstreaks\_killstreaks::getStreakCost( streakName );
	nextStreakName = maps\mp\killstreaks\_killstreaks::getNextStreakName();
	nextStreakCost = maps\mp\killstreaks\_killstreaks::getStreakCost( nextStreakName );
	
	return ( currentStreakCost < nextStreakCost ); 
}


/*
============= 
///ScriptDocBegin
"Name: isJuggernaut()"
"Summary: Returns if the player is a juggernaut or not."
"Module: Player"
"CallOn: player"
"Example: if( player isJuggernaut() )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isJuggernaut()
{
	if ( ( IsDefined( self.isJuggernaut ) && self.isJuggernaut == true ) )
		return true;

	if ( ( IsDefined( self.isJuggernautDef ) && self.isJuggernautDef == true ) )
		return true;
	
	if ( ( IsDefined( self.isJuggernautGL ) && self.isJuggernautGL == true ) )
		return true;
		
	if ( ( IsDefined( self.isJuggernautRecon ) && self.isJuggernautRecon == true ) )
		return true;	
	
	if ( ( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac == true ) )
		return true;	

	if ( ( IsDefined( self.isJuggernautLevelCustom ) && self.isJuggernautLevelCustom == true ) )
		return true;	

	return false;
}


/*
============= 
///ScriptDocBegin
"Name: isKillstreakWeapon( <weapon> )"
"Summary: Returns if this is a killstreak weapon or not."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapon> The name of the weapon to check."
"Example: if( isKillstreakWeapon( sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isKillstreakWeapon( weapon )
{
	if( !IsDefined( weapon ) )
	{
		AssertMsg( "isKillstreakWeapon called without a weapon name passed in" );
		return false;
	}

	if( weapon == "none" )
		return false;

	if( isDestructibleWeapon( weapon ) )
		return false;
	
	if( isBombSiteWeapon( weapon ) )
		return false;
	
	if( isSubStr( weapon, "killstreak" ) )
		return true;
	
	if( isSubStr( weapon, "cobra" ) )
		return true;
	
	if( isSubStr( weapon, "remote_tank_projectile" ) )
		return true;
	
	if( isSubStr( weapon, "artillery_mp" ) )
		return true;
	
	if( isSubStr( weapon, "harrier" ) )
		return true;
			
	// this is necessary because of weapons potentially named "_mp(something)" like the mp5
	tokens = strTok( weapon, "_" );
	foundSuffix = false;
	
	foreach(token in tokens)
	{
		if( token == "mp" )
		{
			foundSuffix = true;
			break;
		}
	}
	
	if ( !foundSuffix )
	{
		weapon += "_mp";
	}
	
	// Held killstreak weapons have _mp so check these after the suffix is added.
	
	if( IsDefined( level.killstreakWeildWeapons[ weapon ] ) )
		return true;
	
	if( maps\mp\killstreaks\_killstreaks::isAirdropMarker( weapon ) )
		return true;
	
	// killstreak weapons are exclusive
	weaponInvType = WeaponInventoryType( weapon );
	if( IsDefined( weaponInvType ) && weaponInvType == "exclusive" )
		return true;
	
	return false;
}

/*
============= 
///ScriptDocBegin
"Name: isDestructibleWeapon( <weapon> )"
"Summary: Returns if this is a destructible weapon or not, like a barrel in the map."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapon> The name of the weapon to check."
"Example: if( isDestructibleWeapon( sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isDestructibleWeapon( weapon )
{
	if( !IsDefined( weapon ) )
	{
		AssertMsg( "isDestructibleWeapon called without a weapon name passed in" );
		return false;
	}

	switch( weapon )
	{
		case "destructible":
		case "destructible_car":
		case "destructible_toy":
		case "barrel_mp":
			return true;
	}
	
	return false;
}

/*
============= 
///ScriptDocBegin
"Name: isBombSiteWeapon( <weapon> )"
"Summary: Returns if this is a bomb site weapon or not, like a briefcase bomb in the map."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapon> The name of the weapon to check."
"Example: if( isBombSiteWeapon( sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/

isBombSiteWeapon( weapon )
{
	if( !IsDefined( weapon ) )
	{
		AssertMsg( "isBombSiteWeapon called without a weapon name passed in" );
		return false;
	}

	switch( weapon )
	{
		case "briefcase_bomb_mp":
		case "bomb_site_mp":
			return true;
	}
	
	return false;
}

/*
============= 
///ScriptDocBegin
"Name: isEnvironmentWeapon( <weapon> )"
"Summary: Returns if this is an environment weapon or not, like a turret in the map."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapon> The name of the weapon to check."
"Example: if( isEnvironmentWeapon( sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isEnvironmentWeapon( weapon )
{
	if( !IsDefined( weapon ) )
	{
		AssertMsg( "isEnvironmentWeapon called without a weapon name passed in" );
		return false;
	}

	if( weapon == "turret_minigun_mp" )
		return true;

	if( isSubStr( weapon, "_bipod_" ) )
		return true;

	return false;
}

/*
============= 
///ScriptDocBegin
"Name: isJuggernautWeapon( <weapon> )"
"Summary: Returns if this is a juggernaut weapon or not."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapon> The name of the weapon to check."
"Example: if( isJuggernautWeapon( sWeapon ) )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isJuggernautWeapon( weapon )
{
	if( !IsDefined( weapon ) )
	{
		AssertMsg( "isJuggernautWeapon called without a weapon name passed in" );
		return false;
	}

	switch( weapon )
	{
		case "iw6_minigunjugg_mp":
		case "iw6_magnumjugg_mp":
		case "iw6_p226jugg_mp":
		case "iw6_knifeonlyjugg_mp":
		case "iw6_riotshieldjugg_mp":
		case "throwingknifejugg_mp":
		case "smoke_grenadejugg_mp":
		case "mortar_shelljugg_mp":
		case "iw6_axe_mp":
		case "iw6_predatorcannon_mp":
		case "iw6_mariachimagnum_mp_akimbo":
			return true;
	}

	return false;
}

/*
============= 
///ScriptDocBegin
"Name: getWeaponClass( <weapon> )"
"Summary: Returns the class of the weapon passed in."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapon> The name of the weapon to check."
"Example: weaponClass = getWeaponClass( sWeapon );"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getWeaponClass( weapon )
{
	baseName = getBaseWeaponName( weapon );
	
	if( is_aliens() )
		weaponClass = tablelookup( "mp/alien/mode_string_tables/alien_statstable.csv", 4, baseName, 2 );
	else
		weaponClass = tablelookup( "mp/statstable.csv", 4, baseName, 2 );
		
	// handle special case weapons like grenades, airdrop markers, etc...
	if ( weaponClass == "" )
	{
		weaponName = strip_suffix( weapon, "_mp" );
		if( is_aliens() )
			weaponClass = tablelookup( "mp/alien/mode_string_tables/alien_statstable.csv", 4, weaponName, 2 );
		else
			weaponClass = tablelookup( "mp/statstable.csv", 4, weaponName, 2 );
	}
	
	if ( isEnvironmentWeapon( weapon ) )
		weaponClass = "weapon_mg";
	else if ( !is_aliens() && isKillstreakWeapon( weapon ) )
		weaponClass = "killstreak"; 
	else if ( weapon == "none" ) //airdrop crates
		weaponClass = "other";
	else if ( weaponClass == "" )
		weaponClass = "other";
	
	assertEx( weaponClass != "", "ERROR: invalid weapon class for weapon " + weapon );
	
	return weaponClass;
}

/*
=============
///ScriptDocBegin
"Name: getWeaponAttachmentArrayFromStats( <weaponName> )"
"Summary: Collects all weapon attachment base names from the statstable.csv."
"Module: Utility"
"MandatoryArg: <weaponName>: Full or base name of the weapon. Base name in this case is iw5_name without the _mp."
"Example: getWeaponAttachmentArrayFromStats( "iw6_ak12_mp" )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
getWeaponAttachmentArrayFromStats( weaponName )
{
	weaponName = getBaseWeaponName( weaponName );
	
	if ( !IsDefined(level.weaponAttachments[weaponName]) )
	{
		attachments = [];
		for ( i = 0; i <= 19; i++ )
		{
			attachment = TableLookup( "mp/statsTable.csv", 4, weaponName, 10 + i );
			if ( attachment == "" )
				break;
			
			attachments[ attachments.size ] = attachment;
		}
		
		level.weaponAttachments[weaponName] = attachments;
	}
	
	return level.weaponAttachments[weaponName];
}

getWeaponAttachmentFromStats( weaponName, index )
{
	weaponName = getBaseWeaponName( weaponName );
	
	return TableLookup( "mp/statsTable.csv", 4, weaponName, 10 + index );
}

/*
=============
///ScriptDocBegin
"Name: attachmentsCompatible( <attachment1> , <attachment2> )"
"Summary: Does a table look up in attachmentcombos.csv to see if the two passed attachments are compatible with each other."
"Module: Utility"
"MandatoryArg: <attachment1>: Name of the first attachment"
"MandatoryArg: <attachment2>: Name of the second attachment"
"Example: attachmentsCompatible( "reflexsmg", "acogsmg" )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

attachmentsCompatible( attachment1, attachment2 )
{
	AssertEx( IsDefined( attachment1 ) && IsDefined( attachment1 ), "areAttachmentsCompatible() passed undefined attachment" );
	
	attachment1 = attachmentMap_toBase( attachment1 );
	attachment2 = attachmentMap_toBase( attachment2 );
	
	compatible = true;
	
	if ( attachment1 == attachment2 )
	{
		compatible = false;
	}
	else if ( attachment1 != "none" && attachment2 != "none" )
	{
		attach2RowAndCol = TableLookupRowNum( "mp/attachmentcombos.csv", 0, attachment2 );
		
		AssertEx( attach2RowAndCol >= 0, "areAttachmentsCompatible() could not find attachment: " + attachment2 + " in attachmentcombos.csv" );
		
		if ( TableLookup( "mp/attachmentcombos.csv", 0, attachment1, attach2RowAndCol ) == "no" )
		{
			compatible = false;
		}
	}
	
	return compatible;
}

getBaseWeaponName( weaponName )
{
	tokens = strTok( weaponName, "_" );
	
	if ( tokens[0] == "iw5" || tokens[0] == "iw6" )
	{
		weaponName = tokens[0] + "_" + tokens[1];
	}
	else if( tokens[0] == "alt" )
	{
		weaponName = tokens[1] + "_" + tokens[2];
	}
	
	return weaponName;
}

getBasePerkName( perkName )
{	
	if ( IsEndStr( perkName, "_ks" ) )
		perkName = GetSubStr( perkName, 0, perkName.size - 3 );
	
	return perkName;
}

/*
=============
///ScriptDocBegin
"Name: getValidExtraAmmoWeapons()"
"Summary: Gets a list of primary weapons that can be used with the Fully Loaded perk; minus killstreaks, grenade under barrels, and launchers"
"Module: Entity"
"CallOn: An entity"
"Example: array = self getValidExtraAmmoWeapons();"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
getValidExtraAmmoWeapons()
{
	// self == player 
	
	weaponList = [];
	
	primaryList = self GetWeaponsListPrimaries();
	
	foreach ( primary in primaryList )
	{
		weapClass = WeaponClass( primary );
		
		if ( !isKillstreakWeapon( primary ) && weapClass != "grenade" && weapClass != "rocketlauncher" )
			weaponList[ weaponList.size ] = primary;
	}
	
	return weaponList;
}

// Riot Shield Util Functions

riotShield_hasWeapon()
{
	result = false;
	
	weaponList = self GetWeaponsListPrimaries();
	foreach ( weapon in weaponList )
	{
		if ( maps\mp\gametypes\_weapons::isRiotShield( weapon ) )
		{
			result = true;
			break;
		}
	}
	return result;
}

riotShield_hasTwo()
{
	count = 0;
	
	weapons = self GetWeaponsListPrimaries();
	foreach ( weapon in weapons )
	{
		if ( maps\mp\gametypes\_weapons::isRiotShield( weapon ) )
		{
			count++;
		}
		
		if ( count == 2 )
		{
			break;
		}
	}
	
	return count == 2;
}

riotShield_attach( onArm, modelShield )
{
	tagAttach = undefined;
	if ( onArm )
	{
		AssertEx( !IsDefined( self.riotShieldModel ), "riotShield_attach() called on player with no riot shield model on the arm" );
		self.riotShieldModel = modelShield;
		tagAttach = "tag_weapon_right";
	}
	else
	{
		AssertEx( !IsDefined( self.riotShieldModelStowed ), "riotShield_attach() called on player with no riot shield model stowed" );
		self.riotShieldModelStowed = modelShield;
		tagAttach = "tag_shield_back";
	}
	
	self AttachShieldModel( modelShield, tagAttach );
	self.hasRiotShield = self riotShield_hasWeapon();
}

riotShield_detach( onArm )
{
	modelShield = undefined;
	tagDetach	= undefined;
	if ( onArm )
	{
		AssertEx( IsDefined( self.riotShieldModel ), "riotShield_detach() called on player with no riot shield model on arm" );
		modelShield = self.riotShieldModel;
		tagDetach = "tag_weapon_right";
	}
	else
	{
		AssertEx( IsDefined( self.riotShieldModelStowed ), "riotShield_detach() called on player with no riot shield model stowed" );
		modelShield = self.riotShieldModelStowed;
		tagDetach = "tag_shield_back";
	}
	
	self DetachShieldModel( modelShield, tagDetach );
	
	if ( onArm )
	{
		self.riotShieldModel	   = undefined;
	}
	else
	{
		self.riotShieldModelStowed = undefined;
	}
	
	self.hasRiotShield = self riotShield_hasWeapon();
}

riotShield_move( fromArm )
{
	tagStart	= undefined;
	tagEnd		= undefined;
	modelShield = undefined;
	if ( fromArm )
	{
		AssertEx( IsDefined( self.riotShieldModel ), "riotShield_move() called on player with no riot shield model on arm" );
		modelShield = self.riotShieldModel;
		tagStart	= "tag_weapon_right";
		tagEnd		= "tag_shield_back";
	}
	else
	{
		AssertEx( IsDefined( self.riotShieldModelStowed ), "riotShield_move() called on player with no riot shield model stowed" );
		modelShield = self.riotShieldModelStowed;
		tagStart	= "tag_shield_back";
		tagEnd		= "tag_weapon_right";
	}
	
	self MoveShieldModel( modelShield, tagStart, tagEnd );
	
	if ( fromArm )
	{
		self.riotShieldModelStowed = modelShield;
		self.riotShieldModel	   = undefined;
	}
	else
	{
		self.riotShieldModel	   = modelShield;
		self.riotShieldModelStowed = undefined;
	}
}

// Scrub all riotshield data for respawn.
riotShield_clear()
{
	self.hasRiotShieldEquipped = false;
	self.hasRiotShield		   = false;
	self.riotShieldModelStowed = undefined;
	self.riotShieldModel	   = undefined;
}

riotShield_getModel()
{
	return ter_op( self isJuggernaut(), "weapon_riot_shield_jug_iw6", "weapon_riot_shield_iw6" );
}

/*
=============
///ScriptDocBegin
"Name: outlineEnableForAll( <entToOutline>, <colorName>, <depthEnable>, <priorityGroup> )"
"Summary: Adds an outline to the passed entity that is visible to every player. Handles people joining and leaving after this call."
"Module: Utility"
"MandatoryArg: <entToOutline>: The entity to outline with the passed color name."
"MandatoryArg: <colorName>: Name of the color to outline with: white, red, green, cyan, orange, blue."
"MandatoryArg: <depthEnable>: Controls whether the outline respects geo. False draws through walls."
"MandatoryArg: <priorityGroup>: This is used to decide which outline draws when multiple are added to one entity. Valid groups are: equipment, perk, killstreak, killstreak_personal. More can be added to outlinePriorityGroupMap() if needed."
"Example: outlineID = outlineEnableForAll( player, "red", false, "equipment" );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

outlineEnableForAll( entToOutline, colorName, depthEnable, priorityGroup )
{
	playersVisibleTo 	= level.players;
	colorIndex 			= maps\mp\gametypes\_outline::outlineColorIndexMap( colorName );
	priority		 	= maps\mp\gametypes\_outline::outlinePriorityGroupMap( priorityGroup );

	return maps\mp\gametypes\_outline::outlineEnableInternal( entToOutline, colorIndex, playersVisibleTo, depthEnable, priority, "ALL" );
}

/*
=============
///ScriptDocBegin
"Name: outlineEnableForTeam( <entToOutline>, <colorName>, <teamVisibleTo>, <depthEnable>, <priorityGroup> )"
"Summary: Adds an outline to the passed entity that is visible to every player on the passed team. Handles people joining and leaving the team after this call."
"Module: Utility"
"MandatoryArg: <entToOutline>: The entity to outline with the passed color name."
"MandatoryArg: <colorName>: Name of the color to outline with: white, red, green, cyan, orange, blue."
"MandatoryArg: <teamVisibleTo>: Team name the outline should be visible to."
"MandatoryArg: <depthEnable>: Controls whether the outline respects geo. False draws through walls."
"MandatoryArg: <priorityGroup>: This is used to decide which outline draws when multiple are added to one entity. Valid groups are: equipment, perk, killstreak, killstreak_personal. More can be added to outlinePriorityGroupMap() if needed."
"Example: outlineID = outlineEnableForTeam( player, "red", "axis", false, "equipment" );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

outlineEnableForTeam( entToOutline, colorName, teamVisibleTo, depthEnable, priorityGroup )
{
	playersVisibleTo = getTeamArray( teamVisibleTo, false );
	colorIndex		 = maps\mp\gametypes\_outline::outlineColorIndexMap( colorName );
	priority		 = maps\mp\gametypes\_outline::outlinePriorityGroupMap( priorityGroup );
	
	return maps\mp\gametypes\_outline::outlineEnableInternal( entToOutline, colorIndex, playersVisibleTo, depthEnable, priority, "TEAM", teamVisibleTo );
}

/*
=============
///ScriptDocBegin
"Name: outlineEnableForPlayer( <entToOutline>, <colorName>, <playerVisibleTo>, <depthEnable>, <priorityGroup> )"
"Summary: The entity to outline with the passed color name."
"Module: Utility"
"MandatoryArg: <entToOutline>: The entity to outline with the passed color name."
"MandatoryArg: <colorName>: Name of the color to outline with: white, red, green, cyan, orange, blue."
"MandatoryArg: <playerVisibleTo>: Player entity the outline should be visible for."
"MandatoryArg: <depthEnable>: Controls whether the outline respects geo. False draws through walls."
"MandatoryArg: <priorityGroup>: This is used to decide which outline draws when multiple are added to one entity. Valid groups are: level_script, equipment, perk, killstreak and killstreak_personal. More can be added to outlinePriorityGroupMap() if needed."
"Example: outlineID = outlineEnableForPlayer( crate, "red", player, false, "killstreak" )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

outlineEnableForPlayer( entToOutline, colorName, playerVisibleTo, depthEnable, priorityGroup )
{
	colorIndex = maps\mp\gametypes\_outline::outlineColorIndexMap( colorName );
	priority   = maps\mp\gametypes\_outline::outlinePriorityGroupMap( priorityGroup );
	
	// HACK: to handle agent being passed in as player who can see outline. Will remove once code allows agents in outline calls.
	if ( IsAgent( playerVisibleTo ) )
	{
		return maps\mp\gametypes\_outline::outlineGenerateUniqueID();
	}
	
	return maps\mp\gametypes\_outline::outlineEnableInternal( entToOutline, colorIndex, [ playerVisibleTo ], depthEnable, priority, "ENTITY" );
}

/*
=============
///ScriptDocBegin
"Name: outlineDisable( <ID> , <entOutlined> )"
"Summary: Removes the outline from the passed entity according to the passed ID. This will clear the outline for everyone that the outline is visible to. The ID was generated and returned when the outline enable function was called."
"Module: Utility"
"MandatoryArg: <ID>: This is the ID that was returned from the above outlineEnable() functions."
"MandatoryArg: <entOutlined>: The entity to remove the outline from. If other outlines exist on the entity a new one is picked by priority and added."
"Example: outlineDisable( outlineID, player );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

outlineDisable( ID, entOutlined )
{
	AssertEx( IsDefined( ID ) && Int( ID ) == ID, "Invalid ID passed to outlineDisable()" );
	AssertEX( IsDefined( entOutlined ), "Undefined entOutlined passed to outlineDiable()" );
	maps\mp\gametypes\_outline::outlineDisableInternal( ID, entOutlined );
}

playSoundinSpace( alias, origin )
{
	playSoundAtPos( origin, alias );
}

limitDecimalPlaces( value, places )
{
	modifier = 1;
	for ( i = 0; i < places; i++ )
		modifier *= 10;
	
	newvalue = value * modifier;
	newvalue = Int( newvalue );
	newvalue = newvalue / modifier;
	
	return newvalue;
}

roundDecimalPlaces( value, places, style )
{
	if ( !isdefined( style ) )
		style = "nearest";
	
	modifier = 1;
	for ( i = 0; i < places; i++ )
		modifier *= 10;
	
	newValue = value * modifier;
	
	if ( style == "up" )
		roundedValue = ceil( newValue );
	else if ( style == "down" )
		roundedValue = floor( newValue ); 	
	else
		roundedValue = newvalue + 0.5;	
		
	newvalue = Int( roundedValue );
	newvalue = newvalue / modifier;
	
	return newvalue;
}

playerForClientId( clientId )
{
	foreach ( player in level.players )
	{
		if ( player.clientId == clientId )
			return player;
	}
	
	return undefined;
}

isRested()
{
	if ( !self rankingEnabled() )
		return false;
		
	return ( self getRankedPlayerData( "restXPGoal" ) > self getRankedPlayerData( "experience" ) );
}

stringToFloat( stringVal )
{
	floatElements = strtok( stringVal, "." );
	
	floatVal = int( floatElements[0] );
	if ( IsDefined( floatElements[1] ) )
	{
		modifier = 1;
		for ( i = 0; i < floatElements[1].size; i++ )
			modifier *= 0.1;
		
		floatVal += int ( floatElements[1] ) * modifier;
	}
	
	return floatVal;	
}

setSelfUsable(caller)
{
	self makeUsable();
	
	foreach (player in level.players)
	{
		if (player != caller )
			self disablePlayerUse( player );
		else
			self enablePlayerUse( player );
	}
}

makeTeamUsable( team )
{
	self makeUsable();
	self thread _updateTeamUsable( team );
}

_updateTeamUsable( team )
{
	self endon ( "death" );
	
	for ( ;; )
	{
		foreach (player in level.players)
		{
			if ( player.team == team )
				self enablePlayerUse( player );	
			else
				self disablePlayerUse( player );	
		}	

		level waittill ( "joined_team" );		
	}
}

// More general version of makeTeamUsable() which handles FFA
makeEnemyUsable( owner )
{
	self makeUsable();
	self thread _updateEnemyUsable( owner );
}

// Only used for Tactical Insertion for now
// If used for other things, handle owner disappearing or changing team
_updateEnemyUsable( owner )
{
	// check what happens if the owner leaves

	self endon ( "death" );

	team = owner.team;

	for ( ;; )
	{
		if ( level.teambased )
		{
			foreach (player in level.players)
			{
				if ( player.team != team )
					self enablePlayerUse( player );	
				else
					self disablePlayerUse( player );	
			}
		}
		else
		{
			foreach (player in level.players)
			{
				if ( player != owner )
					self enablePlayerUse( player );	
				else
					self disablePlayerUse( player );	
			}
		}

		level waittill ( "joined_team" );		
	}
}

initGameFlags()
{
	if ( !IsDefined( game["flags"] ) )
		game["flags"] = [];
}

gameFlagInit( flagName, isEnabled )
{
	assert( IsDefined( game["flags"] ) );
	game["flags"][flagName] = isEnabled;
}

gameFlag( flagName )
{
	assertEx( IsDefined( game["flags"][flagName] ), "gameFlag " + flagName + " referenced without being initialized; usegameFlagInit( <flagName>, <isEnabled> )" );
	return ( game["flags"][flagName] );
}

gameFlagSet( flagName )
{
	assertEx( IsDefined( game["flags"][flagName] ), "gameFlag " + flagName + " referenced without being initialized; usegameFlagInit( <flagName>, <isEnabled> )" );
	game["flags"][flagName] = true;

	level notify ( flagName );
}

gameFlagClear( flagName )
{
	assertEx( IsDefined( game["flags"][flagName] ), "gameFlag " + flagName + " referenced without being initialized; usegameFlagInit( <flagName>, <isEnabled> )" );
	game["flags"][flagName] = false;
}

gameFlagWait( flagName )
{
	assertEx( IsDefined( game["flags"][flagName] ), "gameFlag " + flagName + " referenced without being initialized; usegameFlagInit( <flagName>, <isEnabled> )" );
	while ( !gameFlag( flagName ) )
		level waittill ( flagName );
}

// NOTE: this already exists in code IsExplosiveDamageMOD()
//// including grenade launcher, grenade, RPG, C4, claymore
//isExplosiveDamage( meansofdeath )
//{
//	explosivedamage = "MOD_GRENADE MOD_GRENADE_SPLASH MOD_PROJECTILE MOD_PROJECTILE_SPLASH MOD_EXPLOSIVE mod_explosive MOD_EXPLOSIVE_BULLET";
//	if( isSubstr( explosivedamage, meansofdeath ) )
//		return true;
//	return false;
//}

// if primary weapon damage
isPrimaryDamage( meansofdeath )
{
	// including pistols as well since sometimes they share ammo
	if( meansofdeath == "MOD_RIFLE_BULLET" || meansofdeath == "MOD_PISTOL_BULLET" )
		return true;
	return false;
}

// either this or primary need to go away, or primary do an extra check???
isBulletDamage( meansofdeath )
{
	bulletDamage = "MOD_RIFLE_BULLET MOD_PISTOL_BULLET MOD_HEAD_SHOT";
	if( isSubstr( bulletDamage, meansofdeath ) )
		return true;
	return false;
}

isFMJDamage( sWeapon, sMeansOfDeath, attacker )
{
	// The Bullet Penetration perk comes from the fmj attachment in the attachmentTable.csv or from the weapon in statstable.csv
	return IsDefined( attacker ) && attacker _hasPerk( "specialty_bulletpenetration" ) && IsDefined( sMeansOfDeath ) && isBulletDamage( sMeansOfDeath );
}

initLevelFlags()
{
	if ( !IsDefined( level.levelFlags ) )
		level.levelFlags = [];
}

levelFlagInit( flagName, isEnabled )
{
	assert( IsDefined( level.levelFlags ) );
	level.levelFlags[flagName] = isEnabled;
}

levelFlag( flagName )
{
	assertEx( IsDefined( level.levelFlags[flagName] ), "levelFlag " + flagName + " referenced without being initialized; use levelFlagInit( <flagName>, <isEnabled> )" );
	return ( level.levelFlags[flagName] );
}

levelFlagSet( flagName )
{
	assertEx( IsDefined( level.levelFlags[flagName] ), "levelFlag " + flagName + " referenced without being initialized; use levelFlagInit( <flagName>, <isEnabled> )" );
	level.levelFlags[flagName] = true;

	level notify ( flagName );
}

levelFlagClear( flagName )
{
	assertEx( IsDefined( level.levelFlags[flagName] ), "levelFlag " + flagName + " referenced without being initialized; use levelFlagInit( <flagName>, <isEnabled> )" );
	level.levelFlags[flagName] = false;

	level notify ( flagName );
}

levelFlagWait( flagName )
{
	assertEx( IsDefined( level.levelFlags[flagName] ), "levelFlag " + flagName + " referenced without being initialized; use levelFlagInit( <flagName>, <isEnabled> )" );
	while ( !levelFlag( flagName ) )
		level waittill ( flagName );
}

levelFlagWaitOpen( flagName )
{
	assertEx( IsDefined( level.levelFlags[flagName] ), "levelFlag " + flagName + " referenced without being initialized; use levelFlagInit( <flagName>, <isEnabled> )" );
	while ( levelFlag( flagName ) )
		level waittill ( flagName );
}

initGlobals()
{
	if( !IsDefined( level.global_tables ))
	{
		level.global_tables[ "killstreakTable" ] = SpawnStruct();
		level.global_tables[ "killstreakTable" ].path =					"mp/killstreakTable.csv";
		level.global_tables[ "killstreakTable" ].index_col =			0;
		level.global_tables[ "killstreakTable" ].ref_col =				1;
		level.global_tables[ "killstreakTable" ].name_col =				2;
		level.global_tables[ "killstreakTable" ].desc_col =				3;
		level.global_tables[ "killstreakTable" ].kills_col =			4;
		level.global_tables[ "killstreakTable" ].earned_hint_col =		5;
		level.global_tables[ "killstreakTable" ].sound_col =			6;
		level.global_tables[ "killstreakTable" ].earned_dialog_col =	7;
		level.global_tables[ "killstreakTable" ].allies_dialog_col =	8;
		level.global_tables[ "killstreakTable" ].enemy_dialog_col =		9;
		level.global_tables[ "killstreakTable" ].enemy_use_dialog_col =	10;
		level.global_tables[ "killstreakTable" ].weapon_col =			11;
		level.global_tables[ "killstreakTable" ].score_col =			12;
		level.global_tables[ "killstreakTable" ].icon_col =				13;
		level.global_tables[ "killstreakTable" ].overhead_icon_col =	14;
		level.global_tables[ "killstreakTable" ].dpad_icon_col =		15;
		level.global_tables[ "killstreakTable" ].unearned_icon_col =	16;
		level.global_tables[ "killstreakTable" ].all_team_steak_col =	17;
		
		// TODO: put all other tables in here
	}
}

isKillStreakDenied()
{
	// 2013-08-22 wallace: isAirDenied should only be relevant if it's a flying killstreak, so we should probably remove this check
	// but leaving it in for IW6 b/c it's too late in the game; instead, just make trinity rocket a flying killstreak to explain why you can't use it.
	return (self isEMPed() || isAirDenied() );
}

isEMPed()
{
	if ( self.team == "spectator" )
		return false;
		
	if ( level.teamBased )
    {
    	return ( level.teamEMPed[self.team] || ( IsDefined( self.empGrenaded ) && self.empGrenaded ) || level.teamNukeEMPed[self.team] );
    }
    else
    {
    	return ( ( IsDefined( level.empPlayer ) && level.empPlayer != self ) || ( IsDefined( self.empGrenaded ) && self.empGrenaded ) || ( IsDefined( level.nukeInfo.player ) && self != level.nukeInfo.player && level.teamNukeEMPed[ self.team ] ) );
	}
}

isAirDenied()
{
	// old aastrike stuff
	if ( self.team == "spectator" )
		return false;
		
    if ( level.teamBased )
    	return ( level.teamAirDenied[self.team] );
    else
    	return ( IsDefined( level.airDeniedPlayer ) && level.airDeniedPlayer != self );
}

isNuked()
{
	if ( self.team == "spectator" )
		return false;
		
    return ( IsDefined( self.nuked ) );
}

getPlayerForGuid( guid )
{
	foreach ( player in level.players )
	{
		if ( player.guid == guid )
			return player;
	}
	
	return undefined;
}

/*
============= 
///ScriptDocBegin
"Name: teamPlayerCardSplash( <splash>, <owner>, <team> )"
"Summary: Shows the player card splash to the team."
"Module: Utility"
"CallOn: Level"
"MandatoryArg: <splash> The splash to show from splashtable.csv."
"MandatoryArg: <owner> The owner of the splash, or who called the killstreak."
"OptionalArg: <team> The team to show the splash to, if undefined then it shows to everyone."
"OptionalArg: <optionalNumber> An optional number that gets rolled into the splash text."
"Example: thread teamPlayerCardSplash( "used_ac130", player, player.team );"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
teamPlayerCardSplash( splash, owner, team, optionalNumber )
{

	if ( level.hardCoreMode && !is_aliens() )
		return;

	foreach ( player in level.players )
	{
		if ( IsDefined( team ) && player.team != team )
			continue;
		
		if ( !IsPlayer(player) )
			continue;
		
		player thread maps\mp\gametypes\_hud_message::playerCardSplashNotify( splash, owner, optionalNumber );
	}
}
	

/*
============= 
///ScriptDocBegin
"Name: isCACPrimaryWeapon( <weapName> )"
"Summary: Returns true if the passed in weapon name is in one of the primary weapon classes."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapName> The name of the weapon to check."
"Example: if( isCACPrimaryWeapon( sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isCACPrimaryWeapon( weapName )
{
	switch ( getWeaponClass( weapName ) )
	{
		case "weapon_smg":
		case "weapon_assault":
		case "weapon_riot":
		case "weapon_sniper":
		case "weapon_dmr":
		case "weapon_lmg":
		case "weapon_shotgun":
			return true;
		default:
			return false;
	}
}


/*
============= 
///ScriptDocBegin
"Name: isCACSecondaryWeapon( <weapName> )"
"Summary: Returns true if the passed in weapon name is in one of the secondary weapon classes."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <weapName> The name of the weapon to check."
"Example: if( isCACSecondaryWeapon( sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isCACSecondaryWeapon( weapName )
{
	switch ( getWeaponClass( weapName ) )
	{
		case "weapon_projectile":
		case "weapon_pistol":
		case "weapon_machine_pistol":
			return true;
		default:
			return false;
	}
}


getLastLivingPlayer( team )
{
	livePlayer = undefined;

	foreach ( player in level.players )
	{
		if ( IsDefined( team ) && player.team != team )
			continue;

		if ( !isReallyAlive( player ) && !player maps\mp\gametypes\_playerlogic::maySpawn() )
			continue;
		
		if ( isDefined( player.switching_teams ) && player.switching_teams )
			continue;
		
		assertEx( !IsDefined( livePlayer ), "getLastLivingPlayer() found more than one live player on team." );
		
		livePlayer = player;				
	}

	return livePlayer;
}


getPotentialLivingPlayers()
{
	livePlayers = [];

	foreach ( player in level.players )
	{
		if ( !isReallyAlive( player ) && !player maps\mp\gametypes\_playerlogic::maySpawn() )
			continue;
		
		livePlayers[livePlayers.size] = player;
	}

	return livePlayers;
}


waitTillRecoveredHealth( time, interval )
{
	self endon("death");
	self endon("disconnect");

	fullHealthTime = 0;
	
	if( !IsDefined( interval ) )
		interval = .05;

	if( !IsDefined( time ) )
		time = 0;
	
	while(1)
	{
		if ( self.health != self.maxhealth )
			fullHealthTime = 0;
		else
			fullHealthTime += interval;
		
		wait interval;
		
		if ( self.health == self.maxhealth && fullHealthTime >= time )
			break;
	}

	return;
}

enableWeaponLaser()
{
	if ( !IsDefined( self.weaponLaserCalls ) )
	{
		self.weaponLaserCalls = 0;
	}
	
	self.weaponLaserCalls++;
	self LaserOn();
}

disableWeaponLaser()
{
	AssertEx( IsDefined( self.weaponLaserCalls ), "disableWeaponLaser() called before at least one enableWeaponLaser() call." );
	
	self.weaponLaserCalls--;
	
	AssertEx( self.weaponLaserCalls >= 0, "disableWeaponLaser() called at least one more time than enableWeaponLaser() causing a negative call count." );
	
	if ( self.weaponLaserCalls == 0 )
	{
		self LaserOff();
		self.weaponLaserCalls = undefined;
	}
}

attachmentMap_toUnique( attachmentName, weaponName )
{
	nameUnique = attachmentName;
	weaponName = getBaseWeaponName( weaponName );

	AssertEx( IsDefined( level.attachmentMap_baseToUnique ), "attachmentMap() called without first calling buildAttachmentMaps()" );
	
	// Check first to see if there is a unique name for this attachment by weapon name then check by weapon class
	if ( IsDefined( level.attachmentMap_baseToUnique[ weaponName ] ) && IsDefined( level.attachmentMap_baseToUnique[ weaponName ][ attachmentName ] ) )
	{
		nameUnique = level.attachmentMap_baseToUnique[ weaponName ][ attachmentName ];
	}
	else
	{
		if ( is_aliens() )
		{
			weapClass = TableLookup( "mp/alien/mode_string_tables/alien_statstable.csv", 4, weaponName, 2 );
		}
		else
		{
			weapClass = TableLookup( "mp/statstable.csv", 4, weaponName, 2 );
		}
		if ( IsDefined( level.attachmentMap_baseToUnique[ weapClass ] ) && IsDefined( level.attachmentMap_baseToUnique[ weapClass ][ attachmentName ] ) )
		{
			nameUnique = level.attachmentMap_baseToUnique[ weapClass ][ attachmentName ];
		}
	}
	return nameUnique;
}

attachmentPerkMap( attachmentName )
{
	AssertEx( IsDefined( level.attachmentMap_attachToPerk ), "attachmentPerkMap() called without first calling buildAttachmentMaps()" );
	
	perk = undefined;
	
	if ( IsDefined( level.attachmentMap_attachToPerk[ attachmentName ] ) )
	{
		perk = level.attachmentMap_attachToPerk[ attachmentName ];
	}
	return perk;
}

weaponPerkMap( weaponName )
{
	AssertEx( IsDefined( level.weaponMap_toPerk ), "weaponPerkMap() called without first calling buildWeaponPerkMap()." );
	
	perk = undefined;

	if ( IsDefined( level.weaponMap_toPerk[ weaponName ] ) )
	{
		perk = level.weaponMap_toPerk[ weaponName ];
	}
	return perk;
}


isAttachmentSniperScopeDefault( weaponName, attachName )
{
	tokens = StrTok( weaponName, "_" );
	
	return isAttachmentSniperScopeDefaultTokenized( tokens, attachName );
}

isAttachmentSniperScopeDefaultTokenized( weaponTokens, attachName )
{
	AssertEx( IsArray( weaponTokens ), "isAttachmentSniperScopeDefaultTokenized() called with non array weapon name." );
	
	result = false;
	if ( weaponTokens.size && IsDefined( attachName ) )
	{
		idx = 0;
		if ( weaponTokens[ 0 ] == "alt" )
		{
			idx = 1;
		}
		
		if ( weaponTokens.size >= 3 + idx && ( weaponTokens[ idx ] == "iw5" || weaponTokens[ idx ] == "iw6" ) )
		{
			if ( weaponClass( weaponTokens[ idx ] + "_" + weaponTokens[ idx + 1 ] + "_" + weaponTokens[ idx + 2 ] ) == "sniper" )
			{
				result = weaponTokens[ idx + 1 ] + "scope" == attachName;
			}
		}
	}
	return result;
}

getNumDefaultAttachments( weaponName )
{
	if ( WeaponClass( weaponName ) == "sniper" )
	{
		weaponAttachments = getWeaponAttachments( weaponName );
		foreach (attachment in weaponAttachments)
		{
			if ( isAttachmentSniperScopeDefault( weaponName, attachment ) )
			{
				return 1;
			}
		}
	}
	else if ( isStrStart( weaponName, "iw6_dlcweap02" ) )
	{
		weaponAttachments = GetWeaponAttachments( weaponName );
		foreach ( attachment in weaponAttachments )
		{
			if ( attachment == "dlcweap02scope" )
			{
				return 1;
			}
		}
	}
	
	return 0;
}

getWeaponAttachmentsBaseNames( weaponName )
{
	attachmentsBase = GetWeaponAttachments( weaponName );
	foreach ( idx, attachment in attachmentsBase )
	{
		attachmentsBase[ idx ] = attachmentMap_toBase( attachment );
	}
	
	return attachmentsBase;
}

getAttachmentListBaseNames()
{
	attachmentList = [];
	
	index = 0;
	if ( is_aliens() )
		attachmentName = TableLookup( "mp/alien/alien_attachmentTable.csv", 0, index, 5 );
	else
		attachmentName = TableLookup( "mp/attachmentTable.csv", 0, index, 5 );
	
	while ( attachmentName != "" )
	{
		if ( !array_contains( attachmentList, attachmentName ) )
		{
			attachmentList[ attachmentList.size ] = attachmentName;
		}
		
		index++;
		if ( is_aliens() )
			attachmentName = TableLookup( "mp/alien/alien_attachmentTable.csv", 0, index, 5 );
		else
			attachmentName = TableLookup( "mp/attachmentTable.csv", 0, index, 5 );
	}
	
	return attachmentList;
}

getAttachmentListUniqeNames()
{
	attachmentList = [];
	
	index = 0;
	
	if ( is_aliens() )
		attachmentName = TableLookup( "mp/alien/alien_attachmentTable.csv", 0, index, 4 );
	else
		attachmentName = TableLookup( "mp/attachmentTable.csv", 0, index, 4 );
	
	while ( attachmentName != "" )
	{
		AssertEx( !IsDefined( attachmentList[ attachmentName ] ), "Duplicate unique attachment reference name found in attachmentTable.csv" );
		
		attachmentList[ attachmentList.size ] = attachmentName;
		
		index++;
		
		if ( is_aliens() )
			attachmentName = tableLookup( "mp/alien/alien_attachmentTable.csv", 0, index, 4 );
		else
			attachmentName = TableLookup( "mp/attachmentTable.csv", 0, index, 4 );
	}
	
	return attachmentList;
}

buildAttachmentMaps()
{
	// ------------- //
	// Build map of unique attachment names to base attachment names
	// ------------- //
	AssertEx( !IsDefined( level.attachmentMap_uniqueToBase ), "buildAttachmentMaps() called when map already existed." );
	
	attachmentNamesUnique = getAttachmentListUniqeNames();
	
	level.attachmentMap_uniqueToBase = [];
	
	foreach ( uniqueName in attachmentNamesUnique )
	{	
		if ( is_aliens() )
			baseName = TableLookup( "mp/alien/alien_attachmentTable.csv", 4, uniqueName, 5 );
		else
			baseName = TableLookup( "mp/attachmenttable.csv", 4, uniqueName, 5 );
		
		AssertEx( IsDefined( baseName ) && baseName != "", "No base attachment name found in attachmentTable.csv for unique name: " + uniqueName );
		
		// Only add attachments with unique names
		if ( uniqueName == baseName )
			continue;
		
		level.attachmentMap_uniqueToBase[ uniqueName ] = baseName;
	}
	
	// ------------- //
	// Builds map of base attachment name (by class or weapon name) to unique name
	// ------------- //
	AssertEx( !IsDefined( level.attachmentMap_baseToUnique ), "buildAttachmentMaps() called when map already existed." );
	
	// Collect weapon classes and weapon names from the attachment map table
	weaponClassesAndNames = [];
	idxRow = 1;
	if ( is_aliens() )
		classOrName = TableLookupByRow( ALIENS_ATTACHMAP_TABLE, idxRow, ALIENS_ATTACHMAP_COL_CLASS_OR_WEAP_NAME );
	else	
		classOrName = TableLookupByRow( ATTACHMAP_TABLE, idxRow, ATTACHMAP_COL_CLASS_OR_WEAP_NAME );
	
	while ( classOrName != "" )
	{
		weaponClassesAndNames[ weaponClassesAndNames.size ] = classOrName;
		
		idxRow++;
		if ( is_aliens() )
			classOrName = TableLookupByRow( ALIENS_ATTACHMAP_TABLE, idxRow, ALIENS_ATTACHMAP_COL_CLASS_OR_WEAP_NAME );
		else	
			classOrName = TableLookupByRow( ATTACHMAP_TABLE, idxRow, ATTACHMAP_COL_CLASS_OR_WEAP_NAME );
	}

	attachmentNameColumns = [];
	
	// Collect weapon attachment base names from the attachment map table
	idxCol = 1;
	if ( is_aliens() )
		attachTitle = TableLookupByRow( ALIENS_ATTACHMAP_TABLE, ALIENS_ATTACHMAP_ROW_ATTACH_BASE_NAME, idxCol );
	else
		attachTitle = TableLookupByRow( ATTACHMAP_TABLE, ATTACHMAP_ROW_ATTACH_BASE_NAME, idxCol );
	
	while( attachTitle != "" )
	{
		attachmentNameColumns[ attachTitle ] = idxCol;
		
		idxCol++;
		
		if ( is_aliens() )
			attachTitle = TableLookupByRow( ALIENS_ATTACHMAP_TABLE, ALIENS_ATTACHMAP_ROW_ATTACH_BASE_NAME, idxCol );
		else	
			attachTitle = TableLookupByRow( ATTACHMAP_TABLE, ATTACHMAP_ROW_ATTACH_BASE_NAME, idxCol );
	}
	
	level.attachmentMap_baseToUnique = [];
	
	foreach ( classOrName in weaponClassesAndNames )
	{
		foreach ( attachment, column in attachmentNameColumns )
		{
			if ( is_aliens() )
				attachNameUnique = TableLookup( ALIENS_ATTACHMAP_TABLE, ALIENS_ATTACHMAP_COL_CLASS_OR_WEAP_NAME, classOrName, column );
			else
				attachNameUnique = TableLookup( ATTACHMAP_TABLE, ATTACHMAP_COL_CLASS_OR_WEAP_NAME, classOrName, column );
			
			if ( attachNameUnique == "" )
				continue;
			
			if ( !IsDefined( level.attachmentMap_baseToUnique[ classOrName ]  ) )
			{
				level.attachmentMap_baseToUnique[ classOrName ] = [];
			}
			
			AssertEx( !IsDefined( level.attachmentMap_baseToUnique[ classOrName ][ attachment ] ), "Multiple entries found for uniqe attachment of base name: " + attachment );
			
			level.attachmentMap_baseToUnique[ classOrName ][ attachment ] = attachNameUnique;
		}
	}
	
	// ------------- //
	// Builds map of attachment unique name to perk name
	// ------------- //
	AssertEx( !IsDefined( level.attachmentMap_attachToPerk ), "buildAttachmentMaps() called when map already existed." );
	
	level.attachmentMap_attachToPerk = [];
		
	foreach ( attachName in attachmentNamesUnique )
	{	
		if ( is_aliens() )
			perkName = TableLookup( "mp/alien/alien_attachmenttable.csv", 4, attachName, 12 );
		else			
			perkName = TableLookup( "mp/attachmenttable.csv", 4, attachName, 12 );
		
		if ( perkName == "" )
			continue;
	
		level.attachmentMap_attachToPerk[ attachName ] = perkName;
	}
}

buildWeaponPerkMap()
{
	AssertEx( !IsDefined( level.weaponMap_toPerk ), "buildWeaponPerkMap() called when map already existed." );
	
	level.weaponMap_toPerk = [];
	
	if ( is_aliens() )
		return;
	
	weaponIdx = 0;
	while ( TableLookup( "mp/statstable.csv", 0, weaponIdx, 0 ) != "" )
	{
		perk = TableLookup( "mp/statstable.csv", 0, weaponIdx, 5 );
		
		if ( perk != "" )
		{
			weapon = TableLookup( "mp/statstable.csv", 0, weaponIdx, 4 );
		
			Assert( weapon != "", "buildWeaponPerkMap() found perk: " + perk + " entered without a weapon name." );
		
			if ( weapon != "" )
			{
				level.weaponMap_toPerk[ weapon ] = perk;
			}
		}
		weaponIdx++;
	}
}

attachmentMap_toBase( attachmentName )
{
	AssertEx( IsDefined( level.attachmentMap_uniqueToBase ), "validateAttachment() called without first calling buildAttachmentMaps()" );
	
	if ( IsDefined( level.attachmentMap_uniqueToBase[ attachmentName ] ) )
	{
		attachmentName = level.attachmentMap_uniqueToBase[ attachmentName ];
	}
	
	return attachmentName;
}

/*
=============
///ScriptDocBegin
"Name: weaponMap( <weaponName> )"
"Summary: Takes a full weapon name like: iw5_missile_mp or semtexproj_mp and maps it to a new full weapon name for stat logging."
"Module: Utility"
"MandatoryArg: <weaponName>: The full weapon name to look up."
"Example: weaponName = weaponMap( "semtexproj_mp" )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

weaponMap( weaponName )
{
	if ( IsDefined( weaponName ) )
	{
		switch ( weaponName )
		{
			case "semtexproj_mp":
				weaponName = "iw6_mk32_mp";
				break;
			case "iw6_maawschild_mp":
			case "iw6_maawshoming_mp":
				weaponName = "iw6_maaws_mp";
				break;
			case "iw6_knifeonlyfast_mp":
				weaponName = "iw6_knifeonly_mp";
				break;
			case "iw6_pdwauto_mp":
				weaponName = "iw6_pdw_mp";
			default:
				break;
		}
	}
	
	return weaponName;
}

weaponHasIntegratedSilencer( baseWeapon )
{
	return  ( baseWeapon == "iw6_vks"
	    || baseWeapon == "iw6_k7"
	    || baseWeapon == "iw6_honeybadger"
	   );
}

// need this wrapper for weapon scope attachments
weaponIsFireTypeBurst( weaponName )
{
	if ( weaponHasIntegratedFireTypeBurst( weaponName ) )
	{
		return true;
	}
	else
	{
		return weaponHasAttachment( weaponName, "firetypeburst" );
	}
}

// erg, this is different from the rest because we have to test against attachments
weaponHasIntegratedFireTypeBurst( weaponName )
{
	baseWeapon = getBaseWeaponName( weaponName );
	
	if ( baseWeapon == "iw6_pdw" )
		return true;
	else if ( baseWeapon == "iw6_msbs" )
	{
		// the MSBS can equip firetype attachments, so we need to account for that
		weaponAttachments = getWeaponAttachmentsBaseNames( weaponName );
		foreach ( attachment in weaponAttachments )
		{
			if ( attachment == "firetypeauto" || attachment == "firetypesingle" )
				return false;
		}
		
		return true;
	}
	else
		return false;
}

weaponHasIntegratedGrip( baseWeapon )
{
	return ( baseWeapon == "iw6_g28" );
}

weaponHasIntegratedFMJ( baseWeapon )
{
	return ( baseWeapon == "iw6_cbjms" );
}

weaponHasIntegratedTrackerScope( weaponName )
{
	baseWeapon = getBaseWeaponName( weaponName );
	
	if ( baseWeapon == "iw6_dlcweap03" )
	{
		weaponAttachments = GetWeaponAttachments( weaponName );
		foreach ( attachment in weaponAttachments )
		{
			if ( isStrStart( attachment, "dlcweap03" ) )	// if ( attachment == "dlcweap03scope" || attachment == "dlcweap03vzscope" )
				return true;
		}
	}
	return false;
}

weaponHasAttachment( weaponName, attachmentName )
{
	weaponAttachments = getWeaponAttachmentsBaseNames( weaponName );
	foreach ( attachment in weaponAttachments )
	{
		if ( attachment == attachmentName )
			return true;
	}
	
	return false;
}

weaponGetNumAttachments( weaponName )
{
	// Sniper rifles and DMRs may have integrated scopes that are actually attachments
	numDefaultAttachments = getNumDefaultAttachments( weaponName );
	weaponAttachments = getWeaponAttachments( weaponName );
	
	return weaponAttachments.size - numDefaultAttachments;
}

isPlayerAds()	// self == player
{
	// lots of different values are considered "ads", but we'll use .5, which is the same as the events.gsc stats
	return (self PlayerAds() > 0.5);
}

_objective_delete( objID )
{
	objective_delete( objID);
	
	if ( !IsDefined( level.reclaimedReservedObjectives ) ) 
	{
		level.reclaimedReservedObjectives = [];
		level.reclaimedReservedObjectives[0] = objID;
	}
	else
	{
		level.reclaimedReservedObjectives[ level.reclaimedReservedObjectives.size ] = objID;		
	}
}


touchingBadTrigger( optionalEnt )
{
	killTriggers = getEntArray( "trigger_hurt", "classname" );	
	foreach ( trigger in killTriggers )
	{
		if ( self isTouching( trigger )
		    // !!! HACK 2014-06-14 wallace: we don't want elevator in mine to destroy vanguard when elevator is moving up
		    // but we don't want to affect behavior in other cases. Should fix this for real in IW7
		    && ( level.mapName != "mp_mine" || trigger.dmg > 0 )	
		   )
			return true;
	}

	radTriggers = getEntArray( "radiation", "targetname" );	
	foreach ( trigger in radTriggers )
	{
		if ( self isTouching( trigger ) )
			return true;
	}
	
	if ( isDefined( optionalEnt ) && optionalEnt == "gryphon" )
	{
		gryphonTriggers = getEntArray( "gryphonDeath", "targetname" );	
		foreach ( trigger in gryphonTriggers )
		{
			if ( self isTouching( trigger ) )
				return true;
		}
	}
		
	return false;
}
	
setThirdPersonDOF( isEnabled )
{
	if ( isEnabled )
		self setDepthOfField( 0, 110, 512, 4096, 6, 1.8 );
	else
		self setDepthOfField( 0, 0, 512, 512, 4, 0 );
}



killTrigger( pos, radius, height )
{
	trig = spawn( "trigger_radius", pos, 0, radius, height );
	
	/#
	if ( getdvar( "scr_killtriggerdebug" ) == "1" )
		thread killTriggerDebug( pos, radius, height );
	#/
	
	for ( ;; )
	{
		/#
		if ( getdvar( "scr_killtriggerradius" ) != "" )
			radius = int(getdvar( "scr_killtriggerradius" ));
		#/
		
		trig waittill( "trigger", player );
		
		if ( !isPlayer( player ) )
			continue;
		
		player suicide();
	}
}

findIsFacing( ent1, ent2, tolerance )//finds if ent1 is facing ent2
{
	facingCosine = Cos( tolerance );
	//facingCosine = .90630778703664996324255265675432; //tolerance = 25;
		
	ent1ForwardVector = anglesToForward( ent1.angles );
	ent1ToTarget = ent2.origin - ent1.origin;
	ent1ForwardVector *= (1,1,0);
	ent1ToTarget *= (1,1,0 );
	
	ent1ToTarget = VectorNormalize( ent1ToTarget );
	ent1ForwardVector = VectorNormalize( ent1ForwardVector );
	
	targetCosine = VectorDot( ent1ToTarget, ent1ForwardVector );
	
	if ( targetCosine >= facingCosine )
		return true;
	else
		return false;
}

drawLine( start, end, timeSlice, color )
{
	drawTime = int(timeSlice * 20);
	for( time = 0; time < drawTime; time++ )
	{
		line( start, end, color,false, 1 );
		wait ( 0.05 );
	}
}

drawSphere( origin, radius, timeSlice, color )
{
	drawTime = int(timeSlice * 20);
	for ( time = 0; time < drawTime; time++ )
	{
		Sphere( origin, radius, color );
		wait( 0.05 );
	}
}

/*setRecoilScale sets a relative recoil scaler 
  if you pass 20 it will be a 20% reduction in recoil 
  passing it no values will reset scale override to whatever
  value already exists in self.recoilScale or no override.
*/
setRecoilScale( scaler, scaleOverride )
{	
	if ( !IsDefined( scaler ) )
		scaler = 0;
	
	if ( !IsDefined( self.recoilScale ) )
		self.recoilScale = scaler;
	else
		self.recoilScale += scaler;
	
	//for scale override
	if ( IsDefined( scaleOverride ) )
	{		
		//will not override a lower value.
		if ( IsDefined( self.recoilScale) && scaleOverride < self.recoilScale )
			scaleOverride = self.recoilScale;	
		
		scale = 100 - scaleOverride;
	}
	else
		scale = 100 - self.recoilScale;
	
	if ( scale < 0 )
		scale = 0;
	
	if ( scale > 100 )
		scale = 100;	
	
	if ( scale == 100 )
	{
		self player_recoilScaleOff();
		return;
	}
	
	self player_recoilScaleOn( scale );
}


//Remove undefined and reorders elements
//preserves index
cleanArray( array )
{
	newArray = [];
	
	foreach ( key, elem in array )
	{
		if ( !isdefined( elem ) )
			continue;
			
		newArray[ newArray.size ] = array[ key ];
	}

	return newArray;
}

/#
killTriggerDebug( pos, radius, height )
{
	for ( ;; )
	{
		for ( i = 0; i < 20; i++ )
		{
			angle = i / 20 * 360;
			nextangle = (i+1) / 20 * 360;
			
			linepos = pos + (cos(angle) * radius, sin(angle) * radius, 0);
			nextlinepos = pos + (cos(nextangle) * radius, sin(nextangle) * radius, 0);
			
			line( linepos, nextlinepos );
			line( linepos + (0,0,height), nextlinepos + (0,0,height) );
			line( linepos, linepos + (0,0,height) );
		}
		wait .05;
	}
}
#/

/*
============= 
///ScriptDocBegin
"Name: notUsableForJoiningPlayers( <player> )"
"Summary:  Makes sure newly joining players can't use already deployed equipment."
"Module: Entity"
"CallOn: An Entity"
"MandatoryArg: <player> The owner of the device."
"Example: self thread notUsableForJoiningPlayers( owner );"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
notUsableForJoiningPlayers( owner )
{
	self notify ( "notusablejoiningplayers" );

	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	owner endon ( "death" );
	self endon ( "notusablejoiningplayers" );

	// as players join they need to be set to not be able to use this
	while( true )
	{
		level waittill( "player_spawned", player );
		if( IsDefined( player ) && player != owner )
		{
			self disablePlayerUse( player );
		}
	}
}

/*
============= 
///ScriptDocBegin
"Name: isStrStart( <string>, <subStr> )"
"Summary:  Returns true or false if the strings starts with the sub string passed in."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <string> The base string to check against."
"MandatoryArg: <subStr> The sub string to check for."
"Example: if( isStrStart( sWeapon, "gl_" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isStrStart( string, subStr )
{
	return ( GetSubStr( string, 0, subStr.size ) == subStr );
}

disableAllStreaks()
{
	level.killstreaksDisabled = true;
}

enableAllStreaks()
{
	level.killstreaksDisabled = undefined;
}

/*
============= 
///ScriptDocBegin
"Name: validateUseStreak( <optional_streakname>, <disable_print_output> )"
"Summary:  Returns true or false if the killstreak is usable right now."
"Module: Utility"
"CallOn: Player"
"OptionalArg: <optional_streakname> A specific streakname to check"
"OptionalArg: <disable_print_output> If true, won't print out any warnings"
"Example: if( self validateUseStreak() )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
validateUseStreak( optional_streakname, disable_print_output ) // self == player
{
	if ( IsDefined(optional_streakname) )
	{
		streakName = optional_streakname;
	}
	else
	{
		self_pers_killstreaks = self.pers["killstreaks"];
		streakName = self_pers_killstreaks[ self.killstreakIndexWeapon ].streakName;
	}

	if ( IsDefined( level.killstreaksDisabled ) && level.killstreaksDisabled )
		return false;
	
	if( !self IsOnGround() && ( isRideKillstreak( streakName ) || isCarryKillstreak( streakName ) ) )
		return false;

	if( self isUsingRemote() )
		return false;

	if( IsDefined( self.selectingLocation ) )
		return false;

	if( shouldPreventEarlyUse( streakName ) && level.killstreakRoundDelay )
	{
		if( level.gracePeriod - level.inGracePeriod < level.killstreakRoundDelay )
		{
			if ( !(IsDefined(disable_print_output) && disable_print_output) )
				self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_FOR_N", (level.killstreakRoundDelay - (level.gracePeriod - level.inGracePeriod)) );
			return false;
		}
	}

	if( IsDefined( self.nuked ) && self.nuked && isEMPed() )
	{
		// we shouldn't stop you from using non electronic killstreaks
		if( isKillstreakAffectedByEMP( streakName ) )
		{
			if ( !(IsDefined(disable_print_output) && disable_print_output) )
				self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_FOR_N_WHEN_NUKE", level.nukeEmpTimeRemaining );
			return false;
		}
	}

	// 2013-05-13 wallace
	// since we're piggy-backing off the EMP right now (instead of using our own flag)
	// I'm removing the emp checks	
	/*
	if( self isEMPed() )
	{
		// we shouldn't stop you from using non electronic killstreaks
		if( isKillstreakAffectedByEMP( streakName ) )
		{
			//NOTE: EMP's in MT games depend on the fact that one team cannot cast an EMP while emp'd.  
			//See EMP_JamTeams( ownerTeam ) if this ever changes...
			if ( !(IsDefined(disable_print_output) && disable_print_output) )
				self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_FOR_N_WHEN_EMP", level.empTimeRemaining );
			return false;
		}
	}
	*/

	if ( self isEMPed() )
	{
		// we shouldn't stop you from using non electronic killstreaks
		if( isKillstreakAffectedByEMP( streakName ) )
		{
			//NOTE: EMP's in MT games depend on the fact that one team cannot cast an EMP while emp'd.  
			//See EMP_JamTeams( ownerTeam ) if this ever changes...
			if ( !(IsDefined(disable_print_output) && disable_print_output) )
				self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_WHEN_JAMMED" );
			return false;
		}
	}
	
	if ( self isAirDenied() )
	{
		// allow air_superiority to be called against itself
		if ( isFlyingKillstreak( streakName ) && streakName != "air_superiority" )
		{
			//NOTE: EMP's in MT games depend on the fact that one team cannot cast an EMP while emp'd.  
			//See EMP_JamTeams( ownerTeam ) if this ever changes...
			if ( !(IsDefined(disable_print_output) && disable_print_output) )
				self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_WHEN_AA"  );
			return false;
		}
	}

	if( self IsUsingTurret() && ( isRideKillstreak( streakName ) || isCarryKillstreak( streakName ) ) )
	{
		if ( !(IsDefined(disable_print_output) && disable_print_output) )
			self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_USING_TURRET" );
		return false;
	}

	if( IsDefined( self.lastStand ) && !self _hasPerk( "specialty_finalstand" ) )
	{
		if( !IsDefined(level.allowLastStandAI) || !level.allowLastStandAI || (streakName != "agent" ) )
		{
			if ( !(IsDefined(disable_print_output) && disable_print_output) )
				self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_IN_LASTSTAND" );
			
			return false;
		}
	}

	if( !self isWeaponEnabled() )
		return false;

	if( IsDefined( level.civilianJetFlyBy ) && isFlyingKillstreak( streakName ) )
	{
		if ( !(IsDefined(disable_print_output) && disable_print_output) )
			self IPrintLnBold( &"KILLSTREAKS_CIVILIAN_AIR_TRAFFIC" );
		return false;
	}

	return true;
}

/*
============= 
///ScriptDocBegin
"Name: isRideKillstreak( <streakName> )"
"Summary:  Returns true or false if the killstreak is one that you ride in."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( isRideKillstreak( "ac130" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isRideKillstreak( streakName )
{
	switch( streakName )
	{
		case "vanguard":
		case "heli_pilot":
		case "drone_hive":
		case "odin_support":
		case "odin_assault":
		case "ca_a10_strafe": 	// Level Specific
		case "ac130":			// Level Specific
			return true;
	
		default:
			return false;
	}
}

/*
============= 
///ScriptDocBegin
"Name: isCarryKillstreak( <streakName> )"
"Summary:  Returns true or false if the killstreak is one that you carry."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( isCarryKillstreak( "sentry" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isCarryKillstreak( streakName )
{
	switch( streakName )
	{
	case "sentry":
	case "sentry_gl":
	case "minigun_turret":
	case "gl_turret":		
	case "deployable_vest":
	case "deployable_ammo":
	case "deployable_grenades":
	case "deployable_exp_ammo":
	case "ims":
		return true;

	default:
		return false;
	}
}

/*
============= 
///ScriptDocBegin
"Name: shouldPreventEarlyUse( <streakName> )"
"Summary:  Returns true if the killstreak should be prvent from being used at the start of a round."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( shouldPreventEarlyUse( "predator_missile" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
shouldPreventEarlyUse( streakName )
{
	// 2014-01-08 wallace: change this from a blacklist to a whitelist so that level killstreaks are automatically blocked
	switch ( streakName )
	{
	case "uplink":
	case "ims":
	case "guard_dog":
	case "sentry":
	case "ball_drone_backup":
	case "uplink_support":
	case "deployable_ammo":
	case "deployable_vest":
	case "aa_launcher":
	case "ball_drone_radar":
	case "recon_agent":
	case "jammer":
	case "air_superiority":
	case "uav_3dping":
		return false;
	default:
		// allow airdrops
		return (!isStrStart( streakName, "airdrop_" ));
	}
}

/*
============= 
///ScriptDocBegin
"Name: isKillstreakAffectedByEMP( <streakName> )"
"Summary:  Returns true or false if the killstreak is able to be jammed by EMP."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( isKillstreakAffectedByEMP( "guard_dog" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isKillstreakAffectedByEMP( streakName )
{
	switch( streakName )
	{
	case "deployable_vest":
	case "agent":
	case "recon_agent":
	case "guard_dog":
	case "deployable_ammo":
	case "dome_seekers":
	case "zerosub_level_killstreak":
		return false;

	default:
		return true;
	}
}

isKillstreakAffectedByJammer( streakName )
{
	return (isKillstreakAffectedByEMP( streakName ) && !isFlyingKillstreak( streakName ));
}

/*
============= 
///ScriptDocBegin
"Name: isFlyingKillstreak( <streakName> )"
"Summary:  Returns true or false if the killstreak is a flying killstreak."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( isFlyingKillstreak( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isFlyingKillstreak( streakName )
{
	switch( streakName )
	{
	case "helicopter":
	case "airdrop_sentry_minigun":
	case "airdrop_juggernaut":
	case "airdrop_juggernaut_recon":
	case "heli_sniper":
	case "airdrop_assault":
	case "airdrop_juggernaut_maniac":
	case "heli_pilot":
	case "air_superiority":
	case "odin_support":
	case "odin_assault":
	case "vanguard":
	case "drone_hive":
	case "ca_a10_strafe": // level specific
	case "ac130": // level specific
		return true;

	default:
		return false;
	}
}

/*
============= 
///ScriptDocBegin
"Name: isAllTeamStreak( <streakName> )"
"Summary:  Returns true or false if the killstreak is an all team killstreak."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( isAllTeamStreak( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isAllTeamStreak( streakName )
{
	isTeamStreak = getKillstreakAllTeamStreak( streakName );
	
	if ( !IsDefined( isTeamStreak ) )
		return false;
	
	if ( Int(isTeamStreak) == 1 )
		return true;
	
	return false;
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakRowNum( <streakName> )"
"Summary:  Returns the row number of a killstreak from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakRowNum( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakRowNum( streakName )
{
	return TableLookupRowNum( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakIndex( <streakName> )"
"Summary:  Returns the index column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakIndex( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakIndex( streakName )
{
	indexString = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].index_col );
	if( indexString == "" )
		index = -1;
	else
		index = int( indexString );
	return index;
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakReference( <streakName> )"
"Summary:  Returns the reference column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakReference( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakReference( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].ref_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakReferenceByWeapon( <streakWeapon> )"
"Summary:  Returns the reference column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakWeapon> The killstreak weapon to check against."
"Example: if( getKillstreakReferenceByWeapon( "killstreak_heli_pilot_mp" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakReferenceByWeapon( streakWeapon )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].weapon_col, streakWeapon, level.global_tables[ "killstreakTable" ].ref_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakName( <streakName> )"
"Summary:  Returns the name column (as IString) from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakName( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakName( streakName )
{
	return TableLookupIString( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].name_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakDescription( <streakName> )"
"Summary:  Returns the description column (as IString) from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakDescription( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakDescription( streakName )
{
	return TableLookupIString( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].desc_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakKills( <streakName> )"
"Summary:  Returns the kills column (as IString) from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakKills( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakKills( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].kills_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakEarnedHint( <streakName> )"
"Summary:  Returns the earned hint column (as IString) from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakEarnedHint( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakEarnedHint( streakName )
{
	return TableLookupIString( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].earned_hint_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakSound( <streakName> )"
"Summary:  Returns the sound column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakSound( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakSound( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].sound_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakEarnedDialog( <streakName> )"
"Summary:  Returns the earned dialog column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakEarnedDialog( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakEarnedDialog( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].earned_dialog_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakAlliesDialog( <streakName> )"
"Summary:  Returns the allies dialog column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakAlliesDialog( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakAlliesDialog( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].allies_dialog_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakEnemyDialog( <streakName> )"
"Summary:  Returns the enemy dialog column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakEnemyDialog( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakEnemyDialog( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].enemy_dialog_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakEnemyUseDialog( <streakName> )"
"Summary:  Returns the enemy use dialog column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakEnemyUseDialog( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakEnemyUseDialog( streakName )
{
	return int( TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].enemy_use_dialog_col ) );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakWeapon( <streakName> )"
"Summary:  Returns the weapon column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakWeapon( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakWeapon( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].weapon_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakScore( <streakName> )"
"Summary:  Returns the score column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakScore( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakScore( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].score_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakIcon( <streakName> )"
"Summary:  Returns the icon column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakIcon( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakIcon( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].icon_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakOverheadIcon( <streakName> )"
"Summary:  Returns the overhead icon column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakOverheadIcon( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakOverheadIcon( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].overhead_icon_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakDpadIcon( <streakName> )"
"Summary:  Returns the dpad icon column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakDpadIcon( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakDpadIcon( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].dpad_icon_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakUnearnedIcon( <streakName> )"
"Summary:  Returns the unearned icon column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakUnearnedIcon( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakUnearnedIcon( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].unearned_icon_col );
}

/*
============= 
///ScriptDocBegin
"Name: getKillstreakAllTeamStreak( <streakName> )"
"Summary:  Returns the all team streak column from the killstreakTable."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <streakName> The killstreak name to check against."
"Example: if( getKillstreakAllTeamStreak( "helicopter" ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getKillstreakAllTeamStreak( streakName )
{
	return TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].ref_col, streakName, level.global_tables[ "killstreakTable" ].all_team_streak_col );
}

/*
============= 
///ScriptDocBegin
"Name: currentActiveVehicleCount( <extra> )"
"Summary:  Returns the count of active vehicles currently in the match."
"OptionalArg: <extra> The number of extra vehicles to add on to the count."
"Module: Utility"
"CallOn: None"
"Example: if( currentActiveVehicleCount( level.fauxVehicleCount ) > 8 )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
currentActiveVehicleCount( extra )
{
	if( !IsDefined( extra ) )
		extra = 0;

	count = extra;
	if( IsDefined( level.helis ) )
		count += level.helis.size;
	if( IsDefined( level.littleBirds ) )
		count += level.littleBirds.size;
	if( IsDefined( level.ugvs ) )
		count += level.ugvs.size;

	return count;
}

/*
============= 
///ScriptDocBegin
"Name: maxVehiclesAllowed()"
"Summary:  Returns the number of max vehicles allowed at once in a match."
"Module: Utility"
"CallOn: None"
"Example: if( currentActiveVehicleCount() > maxVehiclesAllowed() )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
maxVehiclesAllowed()
{
	return MAX_VEHICLES;
}

/*
============= 
///ScriptDocBegin
"Name: incrementFauxVehicleCount()"
"Summary:  Increments the level.fauxVehicleCount variable."
"Module: Utility"
"CallOn: None"
"Example: incrementFauxVehicleCount();"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
incrementFauxVehicleCount()
{
	level.fauxVehicleCount++;
}

/*
============= 
///ScriptDocBegin
"Name: decrementFauxVehicleCount()"
"Summary:  Decrements the level.fauxVehicleCount variable."
"Module: Utility"
"CallOn: None"
"Example: decrementFauxVehicleCount();"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
decrementFauxVehicleCount()
{
	level.fauxVehicleCount--;
	
	currentVehicleCount = currentActiveVehicleCount();
	
	if( currentVehicleCount > level.fauxVehicleCount ) 
		level.fauxVehicleCount = currentVehicleCount;
		
	if( level.fauxVehicleCount < 0 )
		level.fauxVehicleCount = 0;
}

/*
============= 
///ScriptDocBegin
"Name: lightWeightScalar()"
"Summary:  Returns the movement speed scalar value for Lightweight."
"Module: Utility"
"CallOn: None"
"Example: self.moveSpeedScaler = lightWeightScalar();"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
lightWeightScalar()
{
	return LIGHTWEIGHT_SCALAR;
}

allowTeamChoice()
{
	// For game modes that have both Teambased/FFA choices
	if( level.gameType == "cranked" )
		return level.teamBased;
	
	allowed = int( tableLookup( "mp/gametypesTable.csv", 0, level.gameType, 4 ) );
	assert( IsDefined( allowed ) );
	
	return allowed;
}

allowClassChoice()
{
	allowed = int( tableLookup( "mp/gametypesTable.csv", 0, level.gameType, 5 ) );
	assert( IsDefined( allowed ) );
	
	return allowed;	
}

showFakeLoadout()
{
	// For modes that traditionally do not have a class selection screen
	// but we need to show one to hide geo while it pops into view
	if ( level.gameType == "sotf"  		|| 
		 level.gameType == "sotf_ffa"  	|| 
		 level.gametype == "gun"		||
		 level.gameType == "infect"  	 )
		return true;
	
	// Handle the case of local split screen mode, where players are spawning in immediately due to no match countdown
	if( level.gameType == "horde" && !matchMakingGame() && IsSplitScreen())
		return false;
	
	if( level.gameType == "horde" && level.currentRoundNumber == 0 )
		return true;
	
	return false;
}

/*
============= 
///ScriptDocBegin
"Name: setFakeLoadoutWeaponSlot()"
"Summary:  Given the full name of a weapon and a slot (1 for primary, 2 for secondary), set up the the omnvars needed to display a fake loadout. Only gun game supports this for now.
"Module: Utility"
"CallOn: player"
"Example: self setFakeLoadoutWeaponSlot( "iw6_usr_mp", 1 );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
setFakeLoadoutWeaponSlot( sWeapon, omnvarSlot )	// self == player
{
	weaponName = getBaseWeaponName( sWeapon );
	attachments = [];
	if ( weaponName != "iw6_knifeonly" && weaponName != "iw6_knifeonlyfast" )
	{
		attachments = GetWeaponAttachments( sWeapon );
	}
	
	weaponOmnvar = "ui_fakeloadout_weapon" + omnvarSlot;
	
	if( IsDefined( weaponName ) )
	{
		weaponRowIdx = TableLookupRowNum( "mp/statsTable.csv", 4, weaponName );
		self SetClientOmnvar( weaponOmnvar, weaponRowIdx );
	}
	else
	{
		self SetClientOmnvar( weaponOmnvar, -1 );
	}
	
	// we only support 3 attachments in the hud
	for( i = 0; i < 3; i++ )
	{
		attachmentOmnvar = weaponOmnvar + "_attach" +  ( i + 1 );
		attachmentRowIdx = -1;		
		if( IsDefined( attachments[ i ] ) )
		{
			if ( !isAttachmentSniperScopeDefault( sWeapon, attachments[ i ] ) )
			{
				attachmentRowIdx = TableLookupRowNum( "mp/attachmentTable.csv", 4, attachments[ i ] );
			}
		}
		
		self SetClientOmnvar( attachmentOmnvar, attachmentRowIdx );
	}
	
	// We don't support camo or reticle now, but it would just require more omnvars
}

/*
============= NOT USED IW6
///ScriptDocBegin
"Name: isBuffUnlockedForWeapon( <buffRef>, <weaponRef> )"
"Summary: Returns true if the weapon buff is unlocked for this weapon."
"Module: Utility"
"CallOn: player"
"MandatoryArg: <buffRef> The name of the weapon buff to check."
"MandatoryArg: <weaponRef> The name of the weapon to check."
"Example: if( isBuffUnlockedForWeapon( "specialty_bulletpenetration", sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isBuffUnlockedForWeapon( buffRef, weaponRef )
{
	WEAPON_RANK_TABLE_LEVEL_COL	=				4;
	WEAPON_RANK_TABLE_WEAPONCLASS_COL =			0;
	WEAPON_RANK_TABLE_WEAPONCLASS_BUFF_COL =	4;

	weaponRank = self GetRankedPlayerData( "weaponRank", weaponRef );
	rankTableBuffCol = int( tableLookup( "mp/weaponRankTable.csv", WEAPON_RANK_TABLE_WEAPONCLASS_COL, getWeaponClass( weaponRef ), WEAPON_RANK_TABLE_WEAPONCLASS_BUFF_COL ) );
	rankTableBuffLevel = tableLookup( "mp/weaponRankTable.csv", rankTableBuffCol, buffRef, WEAPON_RANK_TABLE_LEVEL_COL );
	
	if( rankTableBuffLevel != "" )
	{
		if( weaponRank >= int( rankTableBuffLevel ) )
			return true;
	}

	return false;
}

/*
============= 
///ScriptDocBegin
"Name: isBuffEquippedOnWeapon( <buffRef>, <weaponRef> )"
"Summary: Returns true if the weapon buff is equipped on this weapon."
"Module: Utility"
"CallOn: player"
"MandatoryArg: <buffRef> The name of the weapon buff to check."
"MandatoryArg: <weaponRef> The name of the weapon to check."
"Example: if( isBuffEquippedOnWeapon( "specialty_bulletpenetration", sWeapon ) )"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isBuffEquippedOnWeapon( buffRef, weaponRef )
{
	if( IsDefined( self.loadoutPrimary ) && self.loadoutPrimary == weaponRef )
	{
		if( IsDefined( self.loadoutPrimaryBuff ) && self.loadoutPrimaryBuff == buffRef )
			return true;
	}
	else if( IsDefined( self.loadoutSecondary ) && self.loadoutSecondary == weaponRef )
	{
		if( IsDefined( self.loadoutSecondaryBuff ) && self.loadoutSecondaryBuff == buffRef )
			return true;
	}

	return false;
}


setCommonRulesFromMatchRulesData( skipFriendlyFire )
{
	//	game options
	timeLimit = GetMatchRulesData( "commonOption", "timeLimit" );
	SetDynamicDvar( "scr_" + level.gameType + "_timeLimit", timeLimit );
	registerTimeLimitDvar( level.gameType, timeLimit );
	
	scoreLimit = GetMatchRulesData( "commonOption", "scoreLimit" );
	SetDynamicDvar( "scr_" + level.gameType + "_scoreLimit", scoreLimit );
	registerScoreLimitDvar( level.gameType, scoreLimit );
	
	//	player options
	numLives = GetMatchRulesData( "commonOption", "numLives" );
	SetDynamicDvar( "scr_" + level.gameType + "_numLives", numLives );
	registerNumLivesDvar( level.gameType, numLives );
	
	SetDynamicDvar( "scr_player_maxhealth", GetMatchRulesData( "commonOption", "maxHealth" ) );
	SetDynamicDvar( "scr_player_healthregentime", GetMatchRulesData( "commonOption", "healthRegen" ) );
	
	//	cut for MW3
	//level.matchRules_damageMultiplier = GetMatchRulesData( "commonOption", "damageMultiplier" );
	//level.matchRules_vampirism = GetMatchRulesData( "commonOption", "vampirism" );
	level.matchRules_damageMultiplier = 0;
	level.matchRules_vampirism = 0;
	
	//	team options
	SetDynamicDvar( "scr_game_spectatetype", GetMatchRulesData( "commonOption", "spectateModeAllowed" ) );
	SetDynamicDvar( "scr_game_allowkillcam", GetMatchRulesData( "commonOption", "showKillcam" ) );
	SetDynamicDvar( "scr_game_forceuav", GetMatchRulesData( "commonOption", "radarAlwaysOn" ) );
	SetDynamicDvar( "scr_" + level.gameType + "_playerrespawndelay", GetMatchRulesData( "commonOption", "respawnDelay" ) );
	SetDynamicDvar( "scr_" + level.gameType + "_waverespawndelay", GetMatchRulesData( "commonOption", "waveRespawnDelay" ) );
	SetDynamicDvar( "scr_player_forcerespawn", GetMatchRulesData( "commonOption", "forceRespawn" ) );
	
	//	gameplay options
	level.matchRules_allowCustomClasses = GetMatchRulesData( "commonOption", "allowCustomClasses" );
	level.supportIntel = GetMatchRulesData( "commonOption", "allowIntel" );
	SetDynamicDvar( "scr_game_hardpoints", GetMatchRulesData( "commonOption", "allowKillstreaks" ) );
	SetDynamicDvar( "scr_game_perks", GetMatchRulesData( "commonOption", "allowPerks" ) );
	SetDynamicDvar( "g_hardcore", GetMatchRulesData( "commonOption", "hardcoreModeOn" ) );
	//SetDynamicDvar( "scr_thirdPerson", GetMatchRulesData( "commonOption", "forceThirdPersonView" ) );
	//SetDynamicDvar( "camera_thirdPerson", GetMatchRulesData( "commonOption", "forceThirdPersonView" ) );	// This is what the game uses, set both anyway so they're in sync.
	SetDynamicDvar( "scr_game_onlyheadshots", GetMatchRulesData( "commonOption", "headshotsOnly" ) );
	if ( !IsDefined( skipFriendlyFire ) )
		SetDynamicDvar( "scr_team_fftype", GetMatchRulesData( "commonOption", "friendlyFire" ) );		
		
	//	hardcore overrides these options
	if ( GetMatchRulesData( "commonOption", "hardcoreModeOn" ) )
	{
		SetDynamicDvar( "scr_team_fftype", 2 );
		SetDynamicDvar( "scr_player_maxhealth", 30 );
		SetDynamicDvar( "scr_player_healthregentime", 0 );
		SetDynamicDvar( "scr_player_respawndelay", 0 ); // hardcore_settings.cfg only sets this
		//SetDynamicDvar( "scr_" + level.gameType + "_playerrespawndelay", 10 );
		SetDynamicDvar( "scr_game_allowkillcam", 0 );
		SetDynamicDvar( "scr_game_forceuav", 0 );
	}

	SetDvar( "bg_compassShowEnemies", getDvar( "scr_game_forceuav" ) );
}


reInitializeMatchRulesOnMigration()
{
	assert( isUsingMatchRulesData() );
	assert( IsDefined( level.initializeMatchRules ) );
	
	while(1)
	{
		level waittill( "host_migration_begin" );
		[[level.initializeMatchRules]]();
	}
}

// this should only be called on killstreaks when the player gets in, it'll then reset to the last thermal that was set
//	if the thermal that was set is the game thermal then this is not necessary unless they can switch thermals while in
reInitializeThermal( ent ) // self == player
{
	self endon( "disconnect" );
	
	if( IsDefined( ent ) )
		ent endon( "death" );

	while( true )
	{
		level waittill( "host_migration_begin" );
		if( IsDefined( self.lastVisionSetThermal ) )
			self VisionSetThermalForPlayer( self.lastVisionSetThermal, 0 );
	}
}

/#
reInitializeDevDvarsOnMigration()
{
	level notify( "reInitializeDevDvarsOnMigration" );
	level endon( "reInitializeDevDvarsOnMigration" );

	while(1)
	{
		level waittill( "host_migration_begin" );

		// put all dev dvars that need to be reset after a host migration here
		//	right now it's mostly killstreak timeouts
		SetDevDvarIfUninitialized( "scr_emp_timeout", 15.0 );
		SetDevDvarIfUninitialized( "scr_nuke_empTimeout", 60.0 );
		SetDevDvarIfUninitialized( "scr_uav_timeout", level.radarViewTime  );
		// ball drone
		SetDevDvarIfUninitialized( "scr_balldrone_timeout", 60.0 );
		SetDevDvarIfUninitialized( "scr_balldrone_debug_position", 0 );
		SetDevDvarIfUninitialized( "scr_balldrone_debug_position_forward", 50.0 );
		SetDevDvarIfUninitialized( "scr_balldrone_debug_position_height", 35.0 );
		// intel
		SetDevDvarIfUninitialized( "scr_devIntelChallengeName", "temp" );
		// game timer
		SetDevDvarIfUninitialized( "scr_devchangetimelimit", -1 );
		// odin
		SetDevDvarIfUninitialized( "scr_odin_support_timeout", 60.0 );
		SetDevDvarIfUninitialized( "scr_odin_assault_timeout", 60.0 );
		// cranked
		SetDevDvarIfUninitialized( "scr_cranked_bomb_timer", 30 );
		// heli pilot
		SetDevDvarIfUninitialized( "scr_helipilot_timeout", 60.0 );
		// ims
		SetDevDvarIfUninitialized( "scr_ims_timeout", 90.0 );
		// vanguard (ms)
		SetDevDvarIfUninitialized( "scr_vanguard_reloadTime", 1500 );
	}
}
#/

GetMatchRulesSpecialClass( team, index )
{
	class = [];
	class["loadoutPrimaryAttachment2"] = "none";
	class["loadoutSecondaryAttachment2"] = "none";
	
	loadoutAbilities = [];
	
	AssertEx( IsDefined( team ) && team != "none", "The team value needs to be valid in order to get the correct default loadout");
	
	class["loadoutPrimary"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 0, "weapon" );
	class["loadoutPrimaryAttachment"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 0, "attachment", 0 );
	class["loadoutPrimaryAttachment2"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 0, "attachment", 1 );
	class["loadoutPrimaryBuff"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 0, "buff" );
	class["loadoutPrimaryCamo"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 0, "camo" );
	class["loadoutPrimaryReticle"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 0, "reticle" );
	
	class["loadoutSecondary"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 1, "weapon" );
	class["loadoutSecondaryAttachment"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 1, "attachment", 0 );
	class["loadoutSecondaryAttachment2"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 1, "attachment", 1 );
	class["loadoutSecondaryBuff"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 1, "buff" );
	class["loadoutSecondaryCamo"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 1, "camo" );
	class["loadoutSecondaryReticle"] = getMatchRulesData( "defaultClasses", team, index, "class", "weaponSetups", 1, "reticle" );
	
	class["loadoutEquipment"] = getMatchRulesData( "defaultClasses", team, index, "class", "perks", 0 );
	class["loadoutOffhand"] = getMatchRulesData( "defaultClasses", team, index, "class", "perks", 1 );
	//	hack, until game mode default class data can be reset
	if ( class["loadoutOffhand"] == "specialty_null" )
	{
		class["loadoutOffhand"] = "none";
	
		// If the tactical slot is left empty, always give them a tactical insertion
		if ( level.gameType == "infect" && team == "axis" )
			class["loadoutOffhand"] = "specialty_tacticalinsertion";
	}
	
	// Default Perk Loadout Support for Special Classes
	for ( abilityCategoryIndex = 0 ; abilityCategoryIndex < maps\mp\gametypes\_class::getNumAbilityCategories() ; abilityCategoryIndex++ )
	{
		for ( abilityIndex = 0 ; abilityIndex < maps\mp\gametypes\_class::getNumSubAbility() ; abilityIndex++ )
		{
			picked = false;
			picked = getMatchRulesData( "defaultClasses", team, index, "class", "abilitiesPicked", abilityCategoryIndex, abilityIndex );
			if ( isDefined( picked ) && picked )
			{
				abilityRef = TableLookup( "mp/cacAbilityTable.csv", 0, abilityCategoryIndex + 1, abilityIndex + 4 );
				loadoutAbilities[ loadoutAbilities.size ] = abilityRef;
			}
		}
	}
	
	class["loadoutPerks"] = loadoutAbilities;
		
	loadoutStreakType = getMatchRulesData( "defaultClasses", team, index, "class", "perks", 5 );
	if ( loadoutStreakType != "specialty_null" )
	{
		class["loadoutStreakType"] = loadoutStreakType;
		class["loadoutKillstreak1"] = maps\mp\gametypes\_class::recipe_getKillstreak( team, index, loadoutStreakType, 0 );
		class["loadoutKillstreak2"] = maps\mp\gametypes\_class::recipe_getKillstreak( team, index, loadoutStreakType, 1 );
		class["loadoutKillstreak3"] = maps\mp\gametypes\_class::recipe_getKillstreak( team, index, loadoutStreakType, 2 );	
	}
	
	class["loadoutJuggernaut"] = getMatchRulesData( "defaultClasses", team, index, "juggernaut" );
	
	//	no killstreaks defined for special classes
	
	return class;
}


recipeClassApplyJuggernaut( removeJuggernaut )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	
	//	wait until giveloadout() and spawnPlayer() are complete
	if ( level.inGracePeriod && !self.hasDoneCombat )
		self waittill( "giveLoadout" );
	else
		self waittill( "spawned_player" );
	
	if ( removeJuggernaut )
	{
		self notify( "lost_juggernaut" );
		wait( 0.5 );
	}		
	
	if ( !IsDefined( self.isJuiced ) )
	{
		self.moveSpeedScaler = 0.7;
		self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	}
	self.juggMoveSpeedScaler = 0.7;	// for unset juiced
	self disableWeaponPickup();
	
	if ( !getDvarInt( "camera_thirdPerson" ) )
	{
		self SetClientOmnvar( "ui_juggernaut", 1 );
	}

	self thread maps\mp\killstreaks\_juggernaut::juggernautSounds();
	
	if ( level.gameType != "jugg" || ( IsDefined( level.matchRules_showJuggRadarIcon ) && level.matchRules_showJuggRadarIcon ) )
		self setPerk( "specialty_radarjuggernaut", true, false );	
		
	//	portable radar for Team Juggernaut 
	if ( IsDefined( self.isJuggModeJuggernaut ) && self.isJuggModeJuggernaut )
	{
		self makePortableRadar( self );
	}		

	level notify( "juggernaut_equipped", self );

	self thread maps\mp\killstreaks\_juggernaut::juggRemover();	
}

/*
============= 
///ScriptDocBegin
"Name: updateSessionState( <state>, <icon> )"
"Summary: Updates the player to the state passed in."
"Module: Utility"
"CallOn: player"
"MandatoryArg: <state> The state to update to, either playing, dead, spectator, or intermission."
"MandatoryArg: <icon> The status icon to show while in this state."
"Example: self updateSessionState( "dead", "hud_status_dead" );"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
updateSessionState( sessionState, statusIcon )
{
	assert( sessionState == "playing" || sessionState == "dead" || sessionState == "spectator" || sessionState == "intermission" );
	self.sessionstate = sessionState;
	
	if( !IsDefined( statusIcon ) )
		statusIcon = "";
	self.statusicon = statusIcon;

	self SetClientOmnvar( "ui_session_state", sessionState );
}

/*
============= 
///ScriptDocBegin
"Name: getClassIndex( <className> )"
"Summary: Returns the class index number from the level.classMap array."
"Module: Utility"
"Example: index = getClassIndex( "custom1" );"
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
getClassIndex( className )
{
	assert( IsDefined( level.classMap[className] ) );

	return level.classMap[className];
}

/* 
 * LAST STAND STUFF
 * added by Carlos... should be moved into its own file if we decide to move forward with it
 */
 
isTeamInLastStand()
{
	myteam = getLivingPlayers( self.team );
	foreach ( guy in myteam )
	{
		if ( guy != self && ( !isdefined( guy.lastStand ) || !guy.lastStand ) )
		{
			return false;
		}
	}
	return true;
}

killTeamInLastStand( team )
{
	myteam = getLivingPlayers( team );
	foreach ( guy in myteam )
	{
		if ( isdefined( guy.lastStand ) && guy.lastStand )
		{
			guy thread maps\mp\gametypes\_damage::dieAfterTime( RandomIntRange( 1, 3 ) ); // delay so we don't get a bunch of guys dying at once
		}
	}
}

switch_to_last_weapon( lastWeapon )
{
	if ( !IsAI( self ) )
	{
		self SwitchToWeapon( lastWeapon );
	}
	else
	{
		// Bots/Agents handle weapon switching internally, so they just need to set their scripted weapon back to "none"
		self SwitchToWeapon( "none" );
	}
}

/* 
=============
///ScriptDocBegin
"Name: IsAITeamParticipant( <ent> )"
"Summary: Checks if the entity is an AI (bot or agent) that can participate in team player game activities"
"Summary: This would be something like checking to make sure a certain number of teammates are guarding a flag in domination, etc."
"Summary: It does not include "squadmember" type agents, who can participate in the game but shouldn't be counted as an individual member of a team"
"CallOn: Any entity"
"MandatoryArg: <ent> The entity in question."
"Example: if ( IsAITeamParticipant( ent ) )"
///ScriptDocEnd
============
 */
IsAITeamParticipant( ent )
{
	// Do not add IsDefined(ent.agent_teamParticipant here, it just masks the real issue.  Find out why ent.agent_teamParticipant is undefined (since it never should be)
	if ( IsAgent( ent ) && ent.agent_teamParticipant == true )
		return true;
	
	if ( IsBot( ent ) )
		return true;
	
	return false;
}

/* 
=============
///ScriptDocBegin
"Name: IsTeamParticipant( <ent> )"
"Summary: Checks if the entity is a player, bot, or agent that can participate in team player game activities"
"Summary: This would be something like checking to make sure a certain number of teammates are guarding a flag in domination, etc."
"Summary: It does not include "squadmember" type agents, who can participate in the game but shouldn't be counted as an individual member of a team"
"CallOn: Any entity"
"MandatoryArg: <ent> The entity in question."
"Example: if ( IsTeamParticipant( ent ) )"
///ScriptDocEnd
============
 */
IsTeamParticipant( ent )
{
	if ( IsAITeamParticipant( ent ) )
		return true;
	
	if ( IsPlayer( ent ) )
		return true;
	
	return false;
}

/* 
=============
///ScriptDocBegin
"Name: IsAIGameParticipant( <ent> )"
"Summary: Checks if the entity is a bot player or a human-type agent (any AI-controlled player that can participate in player game activities)"
"CallOn: Any entity"
"MandatoryArg: <ent> The entity in question."
"Example: if ( IsAIGameParticipant( player ) )"
///ScriptDocEnd
============
 */
IsAIGameParticipant( ent )
{
	// Do not add IsDefined(ent.agent_gameParticipant here, it just masks the real issue.  Find out why ent.agent_gameParticipant is undefined (since it never should be)
	if ( IsAgent( ent ) && IsDefined( ent.agent_gameParticipant ) && ent.agent_gameParticipant == true )
		return true;
	
	if ( IsBot( ent ) )
		return true;
	
	return false;
}

/* 
=============
///ScriptDocBegin
"Name: IsGameParticipant( <ent> )"
"Summary: Checks if the entity is a human, a bot player, or a human-type agent (any player that can participate in player game activities)"
"CallOn: Any entity"
"MandatoryArg: <ent> The entity in question."
"Example: if ( IsGameParticipant( player ) )"
///ScriptDocEnd
============
 */
IsGameParticipant( ent )
{
	if ( IsAIGameParticipant( ent ) )
	    return true;
	
	if ( IsPlayer( ent ) )
	    return true;
	
	return false;
}

/* 
=============
///ScriptDocBegin
"Name: getTeamIndex( <team name> )"
"Summary: Returns the code references team index for the team passed in."
"CallOn: none"
"MandatoryArg: <team name> The team name that you want the index for."
"Example: index = getTeamIndex( "allies" );"
///ScriptDocEnd
============
*/
getTeamIndex( team )
{
	/* in code 
		TEAM_FREE == 0
		TEAM_AXIS == 1
		TEAM_ALLIES == 2
	*/
	
	AssertEx( IsDefined( team ), "getTeamIndex: team is undefined!" );

	teamIndex = 0;
	if( level.teambased )
	{
		switch( team )
		{
		case "axis":
			teamIndex = 1;
			break;
		case "allies":
			teamIndex = 2;
			break;
		}
	}

	return teamIndex;
}

/*
=============
///ScriptDocBegin
"Name: getTeamArray( <team> )"
"Summary: Returns an array of players, bots and agents with the passed team."
"Module: Utility"
"CallOn: None"
"MandatoryArg: <team>: The string team name to grab: "axis", "allies", "spectator"."
"MandatoryArg: <includeAgents>: Optional variable to include agents. Defaults to true."
"Example: members = getTeamArray( "axis" );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

getTeamArray( team, includeAgents )
{
	teamArray = [];
	if ( !IsDefined( includeAgents ) || includeAgents )
	{
		foreach ( player in level.characters )
		{
			if ( player.team == team )
			{
				teamArray[ teamArray.size ] = player;
			}
		}
	}
	else
	{
		foreach ( player in level.players )
		{
			if ( player.team == team )
			{
				teamArray[ teamArray.size ] = player;
			}
		}
	}
	
	return teamArray;
}

/* 
=============
///ScriptDocBegin
"Name: isHeadShot( <weapon name>, <hit location>, <means of death>, <attacker> )"
"Summary: Returns true/false if the damage taken was a head shot."
"CallOn: none"
"MandatoryArg: <weapon name> The weapon that caused the damage."
"MandatoryArg: <hit location> The hit location of the damage."
"MandatoryArg: <means of death> The way the damage was taken."
"OptionalArg: <attacker> The entity that caused the damage."
"Example: if( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, attacker ) )"
///ScriptDocEnd
============
*/
isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, attacker )
{	
	if ( IsDefined( attacker ) )
	{
		if ( IsDefined( attacker.owner ) )
		{
			if ( attacker.code_classname == "script_vehicle" )
				return false;
			if ( attacker.code_classname == "misc_turret" )
				return false;
			if ( attacker.code_classname == "script_model" )
				return false;
		}
		if ( IsDefined( attacker.agent_type ) )
		{
			if ( attacker.agent_type == "dog" || attacker.agent_type == "alien" )
				return false;
		}
	}

	return( sHitLoc == "head" || sHitLoc == "helmet" ) && sMeansOfDeath != "MOD_MELEE" && sMeansOfDeath != "MOD_IMPACT" && sMeansOfDeath != "MOD_SCARAB" && sMeansOfDeath != "MOD_CRUSH" && !isEnvironmentWeapon( sWeapon );
}

attackerIsHittingTeam( victim, attacker )
{
	if ( !level.teamBased )
		return false;
	else if ( !isDefined( attacker ) || !isDefined( victim ) )
		return false;
	else if ( !isDefined( victim.team ) || !isDefined( attacker.team ) )
		return false;
	else if ( victim == attacker )
		return false;
	else if ( level.gametype == "infect" && victim.pers[ "team" ] == attacker.team && IsDefined( attacker.teamChangedThisFrame ) ) // Attacker kills self, and damage enemy
		return false;
	else if ( level.gametype == "infect" && victim.pers[ "team" ] != attacker.team && IsDefined( attacker.teamChangedThisFrame ) ) // Attacker kills self, and damage teammate
		return true;
	else if ( isDefined(attacker.scrambled) && attacker.scrambled )
		return false;
	else if ( victim.team == attacker.team  )
		return true;
	else
		return false;
}

/* 
=============
///ScriptDocBegin
"Name: set_high_priority_target_for_bot( <bot> )"
"Summary: Sets this trigger to be a high priority target for the passed-in bot"
"MandatoryArg: <bot> : A bot trigger"
"Example: trigger set_high_priority_target_for_bot( bot );"
///ScriptDocEnd
============
 */
set_high_priority_target_for_bot( bot )
{
	Assert(IsDefined(self.bot_interaction_type));
	if( !( isdefined( self.high_priority_for ) && array_contains( self.high_priority_for, bot ) ) )
	{
		self.high_priority_for = array_add( self.high_priority_for, bot );
		bot notify("calculate_new_level_targets");	
	}
}

/* 
=============
///ScriptDocBegin
"Name: add_to_bot_use_targets( <new_use_target>, <use_time> )"
"Summary: Adds a trigger to the level-specific array that bots look at to determine level-specific use actions"
"Summary: This trigger needs to have a target which consists of exactly one pathnode, which is what bots will use as a destination"
"Summary: Will do nothing if bots are not in use"
"MandatoryArg: <new_use_target> : A use trigger"
"MandatoryArg: <use_time> : The amount of time (in seconds) needed to use the trigger"
"Example: add_to_bot_use_targets( target, 0.5 );"
///ScriptDocEnd
============
 */
add_to_bot_use_targets( new_use_target, use_time )
{
	if ( IsDefined(level.bot_funcs["bots_add_to_level_targets"]) )
	{
		new_use_target.use_time = use_time;
		new_use_target.bot_interaction_type = "use";
		[[ level.bot_funcs["bots_add_to_level_targets"] ]](new_use_target);
	}
}

/* 
=============
///ScriptDocBegin
"Name: remove_from_bot_use_targets( <use_target_to_remove> )"
"Summary: Removes a trigger from the level-specific array that bots look at to determine level-specific use actions"
"Summary: Will do nothing if bots are not in use"
"MandatoryArg: <use_target_to_remove> : A use trigger"
"Example: remove_from_bot_use_targets( trigger );"
///ScriptDocEnd
============
 */
remove_from_bot_use_targets( use_target_to_remove )
{
	if ( IsDefined(level.bot_funcs["bots_remove_from_level_targets"]) )
	{
		[[ level.bot_funcs["bots_remove_from_level_targets"] ]](use_target_to_remove);
	}
}

/* 
=============
///ScriptDocBegin
"Name: add_to_bot_damage_targets( <new_damage_target> )"
"Summary: Adds a trigger to the level-specific array that bots look at to determine level-specific damage actions"
"Summary: Will do nothing if bots are not in use"
"MandatoryArg: <new_damage_target> : A trigger_damage"
"Example: add_to_bot_damage_targets( target );"
///ScriptDocEnd
============
 */
add_to_bot_damage_targets( new_damage_target )
{
	if ( IsDefined(level.bot_funcs["bots_add_to_level_targets"]) )
	{
		new_damage_target.bot_interaction_type = "damage";
		[[ level.bot_funcs["bots_add_to_level_targets"] ]](new_damage_target);
	}
}

/* 
=============
///ScriptDocBegin
"Name: remove_from_bot_damage_targets( <damage_target_to_remove> )"
"Summary: Removes a trigger from the level-specific array that bots look at to determine level-specific damage actions"
"Summary: Will do nothing if bots are not in use"
"MandatoryArg: <damage_target_to_remove> : A trigger_damage"
"Example: remove_from_bot_damage_targets( trigger );"
///ScriptDocEnd
============
 */
remove_from_bot_damage_targets( damage_target_to_remove )
{
	if ( IsDefined(level.bot_funcs["bots_remove_from_level_targets"]) )
	{
		[[ level.bot_funcs["bots_remove_from_level_targets"] ]](damage_target_to_remove);
	}
}

/* 
=============
///ScriptDocBegin
"Name: notify_enemy_bots_bomb_used( <type> )"
"Summary: Notifies all necessary bots that a bomb is being used"
"Summary: Will do nothing if bots are not in use"
"MandatoryArg: <type> : "plant" or "defuse" "
"Example: self notify_enemy_bots_bomb_used( "plant" );"
///ScriptDocEnd
============
 */
notify_enemy_bots_bomb_used( type )
{
	if ( IsDefined(level.bot_funcs["notify_enemy_bots_bomb_used"]) )
	{
		self [[ level.bot_funcs["notify_enemy_bots_bomb_used"] ]](type);
	}
}

/* 
=============
///ScriptDocBegin
"Name: get_rank_xp_for_bot()"
"Summary: Gets the rankXP value for this bot"
"Summary: Will do nothing if bots are not in use"
"Example: self.pers[ "rankxp" ] = self get_rank_xp_for_bot();"
///ScriptDocEnd
============
 */
get_rank_xp_for_bot()
{
	if ( IsDefined(level.bot_funcs["bot_get_rank_xp"]) )
	{
		return self [[ level.bot_funcs["bot_get_rank_xp"] ]]();
	}	
}

/*
=============
///ScriptDocBegin
"Name: bot_israndom()"
"Summary: Checks if a bot's loadout is random. If true you can assume the bot loadout does not follow class limitation rules."
"CallOn: A Bot"
"Example: randLoadout = self bot_israndom()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

bot_israndom()
{
	isRandom = true;

	if ( GetDvar( "squad_use_hosts_squad" ) == "1" )
	{
		botTeam = undefined;
		
		if ( isDefined( self.bot_team ) )
			botTeam = self.bot_team;
		else if( isDefined( self.pers[ "team" ] ) )
			botTeam = self.pers[ "team" ];
		
		if ( isDefined(botTeam) && level.wargame_client.team == botTeam )
			isRandom = false;
		else
			isRandom = true;
	}
	else
	{
		isRandom = self BotIsRandomized();
	}

	return isRandom;
}

/* 
=============
///ScriptDocBegin
"Name: isAssaultKillstreak( <killstreak name> )"
"Summary: Returns true/false if the killstreak is an Assault killstreak."
"CallOn: none"
"MandatoryArg: <killstreak name> The killstreak name to check out."
"Example: if( isAssaultKillstreak( "ims" ) )"
///ScriptDocEnd
============
*/
isAssaultKillstreak( refString )
{
	switch ( refString )
	{
		case "airdrop_assault":
		case "ims":
		case "airdrop_sentry_minigun":
		case "helicopter":
		case "airdrop_juggernaut":
		case "airdrop_juggernaut_maniac":
		case "sentry":
		case "ball_drone_backup":
		case "guard_dog":
		case "heli_pilot":
		case "vanguard":
		case "uplink":
		case "drone_hive":
		case "odin_assault":
			return true;
		default:
			return false;
	}
}

/* 
=============
///ScriptDocBegin
"Name: isSupportKillstreak( <killstreak name> )"
"Summary: Returns true/false if the killstreak is a Support killstreak."
"CallOn: none"
"MandatoryArg: <killstreak name> The killstreak name to check out."
"Example: if( isSupportKillstreak( "sam_turret" ) )"
///ScriptDocEnd
============
*/
isSupportKillstreak( refString )
{
	switch ( refString )
	{
		case "deployable_vest":
		case "sam_turret":
		case "jammer":
		case "air_superiority":
		case "airdrop_juggernaut_recon":
		case "ball_drone_radar":
		case "heli_sniper":
		case "uplink_support":
		case "odin_support":
		case "recon_agent":
		case "aa_launcher":
		case "uav_3dping":
		case "deployable_ammo":
			return true;
		default:
			return false;
	}
}

/* 
=============
///ScriptDocBegin
"Name: isSpecialistKillstreak( <killstreak name> )"
"Summary: Returns true/false if the killstreak is a Specialist killstreak."
"CallOn: none"
"MandatoryArg: <killstreak name> The killstreak name to check out."
"Example: if( isSpecialistKillstreak( "specialty_fastreload_ks" ) )"
///ScriptDocEnd
============
*/
isSpecialistKillstreak( refString )
{
	switch ( refString )
	{
		case "specialty_fastsprintrecovery_ks":
		case "specialty_fastreload_ks":
		case "specialty_lightweight_ks":
		case "specialty_marathon_ks":
		case "specialty_stalker_ks":
		case "specialty_reducedsway_ks":
		case "specialty_quickswap_ks":
		case "specialty_pitcher_ks":
		case "specialty_bulletaccuracy_ks":
		case "specialty_quickdraw_ks":
		case "specialty_sprintreload_ks":
		case "specialty_silentkill_ks":
		case "specialty_blindeye_ks":
		case "specialty_gpsjammer_ks":
		case "specialty_quieter_ks":
		case "specialty_incog_ks":
		case "specialty_paint_ks":
		case "specialty_scavenger_ks":
		case "specialty_detectexplosive_ks":
		case "specialty_selectivehearing_ks":
		case "specialty_comexp_ks":
		case "specialty_falldamage_ks":
		case "specialty_regenfaster_ks":
		case "specialty_sharp_focus_ks":
		case "specialty_stun_resistance_ks":
		case "_specialty_blastshield_ks":
		case "specialty_gunsmith_ks":
		case "specialty_extraammo_ks":
		case "specialty_extra_equipment_ks":
		case "specialty_extra_deadly_ks":
		case "specialty_extra_attachment_ks":
		case "specialty_explosivedamage_ks":
		case "specialty_gambler_ks":
		case "specialty_hardline_ks":
		case "specialty_twoprimaries_ks":
		case "specialty_boom_ks":
		case "specialty_deadeye_ks":
			return true;
		default:
			return false;
	}
}

/* 
=============
///ScriptDocBegin
"Name: bot_is_fireteam_mode()"
"Summary: Return true if the game is in Fireteam mode"
"Example: if ( bot_is_fireteam_mode() )"
///ScriptDocEnd
============
 */
bot_is_fireteam_mode()
{
	fireteam_bots = (BotAutoConnectEnabled() == 2);
	
	if ( fireteam_bots )
	{
		//For now, only these 2 modes are supported in Fireteam mode
		if ( !level.teamBased || (level.gametype != "war" && level.gametype != "dom") )
		{
			//FIXME: executable & menus still think we're in Fireteam mode - this logic needs to be in the .exe...
			return false;
		}
		return true;
	}
	return false;
}

/*
=============
///ScriptDocBegin
"Name: set_console_status( <set_console_status> )"
"Summary: "
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <param1>: "
"OptionalArg: <param2>: "
"Example: "
///ScriptDocEnd
=============
*/
set_console_status()
{
	if ( !isdefined( level.Console ) )
		level.Console = GetDvar( "consoleGame" ) == "true";
	else
		AssertEx( level.Console == ( GetDvar( "consoleGame" ) == "true" ), "Level.console got set incorrectly." );

	if ( !isdefined( level.xenon ) )
		level.xenon = GetDvar( "xenonGame" ) == "true";
	else
		AssertEx( level.xenon == ( GetDvar( "xenonGame" ) == "true" ), "Level.xenon got set incorrectly." );

	if ( !isdefined( level.ps3 ) )
		level.ps3 = GetDvar( "ps3Game" ) == "true";
	else
		AssertEx( level.ps3 == ( GetDvar( "ps3Game" ) == "true" ), "Level.ps3 got set incorrectly." );

	if ( !isdefined( level.xb3 ) )
		level.xb3 = GetDvar( "xb3Game" ) == "true";
	else
		AssertEx( level.xb3 == ( GetDvar( "xb3Game" ) == "true" ), "Level.xb3 got set incorrectly." );

	if ( !isdefined( level.ps4 ) )
		level.ps4 = GetDvar( "ps4Game" ) == "true";
	else
		AssertEx( level.ps4 == ( GetDvar( "ps4Game" ) == "true" ), "Level.ps4 got set incorrectly." );
}

/*
=============
///ScriptDocBegin
"Name: IsGen4Renderer( )"
"Summary: Used to determine if the game is a Gen4 renderer. Gen1 = ps1. These are games that can support more things than a Xbox360"
"Module: Utility"
"CallOn: An entity"
"Example: if ( IsGen4Renderer() )"
///ScriptDocEnd
=============
*/
is_gen4()
{
	AssertEx( isdefined( level.Console ) && isdefined( level.xb3 ) && isdefined( level.ps4 ), "is_gen4() called before set_console_status() has been run." );

	if ( level.xb3 || level.ps4 || !level.console )
		return true;
	else
		return false;
}

setdvar_cg_ng( dvar_name, current_gen_val, next_gen_val )
{
	if ( !isdefined( level.console ) || !isdefined( level.xb3 ) || !isdefined( level.ps4 ) )
		set_console_status();
	AssertEx( IsDefined( level.console ) && IsDefined( level.xb3 ) && IsDefined( level.ps4 ), "Expected platform defines to be complete." );

	if ( is_gen4() )
		setdvar( dvar_name, next_gen_val );
	else
		setdvar( dvar_name, current_gen_val );
}

isValidTeamTarget( attacker, victimTeam, target )
{
	return ( IsDefined( target.team ) && target.team == victimTeam );
}

isValidFFATarget( attacker, victimTeam, target )
{
	return ( IsDefined( target.owner )	
		    && ( !IsDefined( attacker ) || target.owner != attacker )	// attacker can be undefined if he disconnected?
		   );
}

/* 
=============
///ScriptDocBegin
"Name: getHeliPilotMeshOffset()"
"Summary: Returns the vector value of the helicopter pilot mesh offset."
"CallOn: none"
"Example: mesh_offset = getHeliPilotMeshOffset();"
///ScriptDocEnd
============
*/
getHeliPilotMeshOffset()
{
	return ( 0, 0, 5000 );
}

/* 
=============
///ScriptDocBegin
"Name: getHeliPilotTraceOffset()"
"Summary: Returns the vector value of how far above / below the heli to trace to find the heli mesh"
"CallOn: none"
"Example: trace_offset = getHeliPilotTraceOffset();"
///ScriptDocEnd
============
*/
getHeliPilotTraceOffset()
{
	return ( 0, 0, 2500 );
}

/* 
=============
///ScriptDocBegin
"Name: getLinknameNodes()"
"Summary: Returns the array of nodes connected to self with script_linkname."
"CallOn: Object with script_linkto"
"Example: self getLinknameNodes();"
///ScriptDocEnd
============
*/
getLinknameNodes()
{
	array = [];

	if ( isdefined( self.script_linkto ) )
	{
		linknames = strtok( self.script_linkto, " " );
		for ( i = 0; i < linknames.size; i++ )
		{
			ent = getnode( linknames[ i ], "script_linkname" );
			if ( isdefined( ent ) )
				array[ array.size ] = ent;
		}
	}

	return array;
}


/*
=============
///ScriptDocBegin
"Name: is_aliens()"
"Summary: returns true if the current game mode is Aliens"
"Module: Level"
"CallOn: Level"
"Example: isalienmode = is_aliens()"
"SPMP: both"
///ScriptDocEnd
=============
*/
is_aliens()
{
	return level.gameType == "aliens";
}

/*
=============
///ScriptDocBegin
"Name: get_players_watching( <just_spectators>, <just_killcam> )"
"Summary: Returns a list of the players "watching" this player - either through a killcam or by spectating"
"CallOn: A player"
"OptionalArg: <just_spectators>: If true, we will only return spectators watching."
"OptionalArg: <just_killcam>: If true, we will only return players watching the killcam."
"Example: players_watching = self get_players_watching();"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
get_players_watching( just_spectators, just_killcam )
{
	if( !IsDefined( just_spectators ) )
		just_spectators = false;
	if( !IsDefined( just_killcam ) )
		just_killcam = false;
	
	entity_num_self = self GetEntityNumber();
	players_watching = [];
	foreach( player in level.players )
	{
		if( player == self )
			continue;
		
		player_is_watching = false;
		
		if( !just_killcam )
		{
			if ( player.team == "spectator" || player.sessionstate == "spectator" )
			{
				spectatingPlayer = player GetSpectatingPlayer();
				if ( IsDefined(spectatingPlayer) && spectatingPlayer == self )
					player_is_watching = true;
			}
			
			if ( player.forcespectatorclient == entity_num_self )
				player_is_watching = true;
		}
		
		if( !just_spectators )
		{
			if ( player.killcamentity == entity_num_self )
				player_is_watching = true;
		}
		
		if ( player_is_watching )
			players_watching[players_watching.size] = player;
	}
	
	return players_watching;
}

/*
=============
///ScriptDocBegin
"Name: set_visionset_for_watching_players( <new_visionset>, <new_visionset_transition_time>, <time_in_new_visionset>, <is_missile_visionset> )"
"Summary: Sets a visionset for any players watching the current player"
"CallOn: A player"
"MandatoryArg: <new_visionset>: The visionset to apply"
"MandatoryArg: <new_visionset_transition_time>: How long to transition to the new visionset"
"MandatoryArg: <time_in_new_visionset>: Once transitioned, how long the player will stay in this vision set until he transitions back to the default"
"OptionalArg: <is_missile_visionset>: If true, will use VisionSetMissilecamForPlayer"
"OptionalArg: <just_spectators>: If true, we will only affect spectators watching."
"OptionalArg: <just_killcam>: If true, we will only affect players watching the killcam."
"Example: self set_visionset_for_watching_players( "black_bw", 0.50, 1.0 );"
"SPMP: multiplayer"
"NoteLine: <time_in_new_visionset> This doesn't automatically transition the player after this time.  It handles the case where he would be a spectator"
"NoteLine: <time_in_new_visionset> and then join a team during the new visionset.  In that case we need to make sure to reset the visionset"
///ScriptDocEnd
=============
*/
set_visionset_for_watching_players( new_visionset, new_visionset_transition_time, time_in_new_visionset, is_missile_visionset, just_spectators, just_killcam )
{
	players_watching = self get_players_watching( just_spectators, just_killcam );
	foreach( player in players_watching )
	{
		player notify("changing_watching_visionset");
		if ( IsDefined(is_missile_visionset) && is_missile_visionset )
			player VisionSetMissilecamForPlayer( new_visionset, new_visionset_transition_time );
		else
			player VisionSetNakedForPlayer( new_visionset, new_visionset_transition_time );
		if ( new_visionset != "" && IsDefined(time_in_new_visionset) )
		{
			player thread reset_visionset_on_team_change( self, new_visionset_transition_time + time_in_new_visionset );
			player thread reset_visionset_on_disconnect( self );
			
			if ( player isInKillcam() )
				player thread reset_visionset_on_spawn();
		}
	}
}

reset_visionset_on_spawn()
{
	self endon( "disconnect" );
	
	self waittill("spawned");
	self VisionSetNakedForPlayer( "", 0.0 );
}

reset_visionset_on_team_change( current_player_watching, time_till_default_visionset )
{
	self endon("changing_watching_visionset");
	
	time_started = GetTime();
	team_started = self.team;
	while( GetTime() - time_started < time_till_default_visionset * 1000 )
	{
		if ( self.team != team_started || !array_contains( current_player_watching get_players_watching(), self ) )
		{
			// Changed team before the visionset was done, so make sure to end it early otherwise it could get stuck on
			self VisionSetNakedForPlayer( "", 0.0 );
			self notify("changing_visionset");
			break;
		}
		
		wait(0.05);
	}
}

reset_visionset_on_disconnect( entity_watching )
{
	self endon("changing_watching_visionset");
	entity_watching waittill("disconnect");
	self VisionSetNakedForPlayer( "", 0.0 );
}

/*
=============
///ScriptDocBegin
"Name: _setPlayerData()"
"Summary: sets proper player data for matchmaking or private match"
"CallOn: A player"
"Example: randoPlayer _setPlayerData( <data to set>, <value>);"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
_setPlayerData(data, value)
{
	if( matchMakingGame() )
		self SetRankedPlayerData( data, value );
	else
		self setPrivatePlayerData( data, value );
}

/*
=============
///ScriptDocBegin
"Name: _getPlayerData()"
"Summary: gets proper player data for matchmaking or private match"
"CallOn: A player"
"Example: randoPlayer _getPlayerData( <string name of data>);"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
_getPlayerData(data)
{
	if( matchMakingGame() )
		return self GetRankedPlayerData( data );
	else
		return self GetPrivatePlayerData( data );
}

/*
=============
///ScriptDocBegin
"Name: _validateAttacker()"
"Summary: Returns undefined if attacker no longer exists or is invalid"
"Example: if ( isDefined( _validateAttacker( eAttacker ) )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
_validateAttacker( eAttacker )
{
	if ( IsAgent( eAttacker ) && (!IsDefined( eAttacker.isActive ) || !eAttacker.isActive) )
		return undefined;
	
	if ( IsAgent( eAttacker ) && !IsDefined( eAttacker.classname ) ) 
		return undefined;
	
	return eAttacker;
}

/*
=============
///ScriptDocBegin
"Name: waittill_grenade_fire()"
"Summary: Waits until grenade_fire happens and put important info on the grenade entity. Returns the grenade entity."
"Module: Utility"
"CallOn: Player"
"Example: grenade = self waittill_grenade_fire();"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
waittill_grenade_fire()
{
	self waittill( "grenade_fire", grenade, weapon_name );
	if( IsDefined( grenade ) )
	{
		if( !IsDefined( grenade.weapon_name ) )
			grenade.weapon_name = weapon_name;
		if( !IsDefined( grenade.owner ) )
			grenade.owner = self;
		if( !IsDefined( grenade.team ) )
			grenade.team = self.team;
	}
		
	return grenade;
}

/*
=============
///ScriptDocBegin
"Name: waittill_missile_fire()"
"Summary: Waits until missile_fire happens and put important info on the missile entity. Returns the missile entity."
"Module: Utility"
"CallOn: Player"
"Example: missile = self waittill_missile_fire();"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
waittill_missile_fire()
{
	self waittill( "missile_fire", missile, weapon_name );
	if( IsDefined( missile ) )
	{
		if( !IsDefined( missile.weapon_name ) )
			missile.weapon_name = weapon_name;
		if( !IsDefined( missile.owner ) )
			missile.owner = self;
		if( !IsDefined( missile.team ) )
			missile.team = self.team;
	}
		
	return missile;
}

/*
=============
///ScriptDocBegin
"Name: _setNameplateMaterial()"
"Summary: wrapper for built-in setnameplateMaterial so we can properly restore nameplate
"Module: Utility"
"CallOn: Player"
"Example: agent SetNameplateMaterial( "player_name_bg_green_agent", "player_name_bg_red_agent" ); 
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
_setNameplateMaterial( friendlyMat, enemyMat )
{
	if ( !IsDefined( self.nameplateMaterial ) )
	{
		self.nameplateMaterial = [];
		self.prevNameplateMaterial = [];
	}
	else
	{
		self.prevNameplateMaterial[0] = self.nameplateMaterial[0];
		self.prevNameplateMaterial[1] = self.nameplateMaterial[1];
	}
	self.nameplateMaterial[0] = friendlyMat;
	self.nameplateMaterial[1] = enemyMat;
	
	self SetNameplateMaterial( friendlyMat, enemyMat );
}

_restorePreviousNameplateMaterial()
{
	if ( IsDefined( self.prevNameplateMaterial ) )
	{
		self SetNameplateMaterial( self.prevNameplateMaterial[0], self.prevNameplateMaterial[1] );
	}
	else
	{
		self SetNameplateMaterial( "", "" );
	}
	self.nameplateMaterial = undefined;
	self.prevNameplateMaterial = undefined;
}

// can only drop weapons if we're not near a bomb size.
isPlayerOutsideOfAnyBombSite( weaponName )	// self == player
{
	if ( IsDefined( level.bombZones ) )
	{
		foreach (bombZone in level.bombZones)
		{
			if ( self IsTouching( bombZone.trigger ) )
			    return false;
		}
	}
	
	return true;
}

weaponIgnoresBlastShield( sWeapon )
{
	// The following weapons will bypass blast shield entirely
	return sWeapon == "heli_pilot_turret_mp" || sWeapon == "bomb_site_mp";
}

isWeaponAffectedByBlastShield( sWeapon )
{
	return (
		sWeapon == "ims_projectile_mp"
		|| sWeapon == "remote_tank_projectile_mp"
	);
}

restoreBaseVisionSet( fadeTime )	// self == player
{
	self VisionSetNakedForPlayer( "", fadeTime ); // go to default visionset
}

/* 
============= 
///ScriptDocBegin
"Name: playPlayerAndNpcSounds( player, firstPersonSound, thirdPersonSound )
"Summary: Play a localized sound on the player, and world sound for everyone else
"Module: Utility"
"MandatoryArg: <player> : owner player
"MandatoryArg: <firstPersonSound> : local sound to play on plyaer
"MandatoryArg: <thirdPersonSound> : world sound to play for everyone else
"Example: delayThread( 3, ::flag_set, "player_can_rappel" );
"SPMP: both"
///ScriptDocEnd
============= 
*/ 
playPlayerAndNpcSounds( player, firstPersonSound, thirdPersonSound )
{
	player PlayLocalSound( firstPersonSound );
	player PlaySoundToTeam( thirdPersonSound, "allies", player );
	player PlaySoundToTeam( thirdPersonSound, "axis", player );
}

/* 
============= 
///ScriptDocBegin
"Name: isEnemy()
"Summary: returns if the other (player / agent) is an enemy. Works for team based and FFA modes.
"Module: Utility"
"Example: foreach ( char in level.characters ) { if ( owner isEnemy( char ) ) { doStuff; } }
"SPMP: both"
///ScriptDocEnd
============= 
*/ 
isEnemy( other )	// self == player
{
	if ( level.teamBased )
	{
		return self isPlayerOnEnemyTeam( other );
	}
	else
	{
		return self isPlayerFFAEnemy( other );
	}
}

isPlayerOnEnemyTeam( other )	// self == player
{
	return ( other.team != self.team );
}

isPlayerFFAEnemy( other )	// self == player
{
	// want to be able to test against agents
	if ( IsDefined( other.owner ) )	
	{
		return ( other.owner != self );
	}
	else
	{
		return ( other != self );
	}
}

setExtraScore0( newValue ) // self == player
{
	self.extrascore0 = newValue;
	self setPersStat( "extrascore0", newValue );
}

allowLevelKillstreaks()
{
	// The following modes will not allow level killstreaks
	if ( level.gametype == "sotf" && level.gametype == "sotf_ffa" && level.gametype == "infect" && level.gametype == "horde" )
		return false;
	
	return true;
}


getUniqueId() // self == player
{
	if ( IsDefined( self.pers["guid"] ) )
		return self.pers["guid"];
	
	playerGuid = self getGuid();
	if ( playerGuid == "0000000000000000" )
	{
		if ( IsDefined( level.guidGen ) )
			level.guidGen++;
		else
			level.guidGen = 1;
		
		playerGuid = "script" + level.guidGen;
	}
	
	self.pers["guid"] = playerGuid;
	
	return self.pers["guid"];
}

getRandomPlayingPlayer()
{
	unparsedPlayers = array_removeUndefined( level.players );
	
	for ( ;; )
	{
		if( !unparsedPlayers.size )
			return;
		
		randNum = RandomIntRange( 0, unparsedPlayers.size );
		selectedPlayer = unparsedPlayers[randNum];
		
		if( !isReallyAlive( selectedPlayer ) || selectedPlayer.sessionstate != "playing" )
		{
			unparsedPlayers = array_remove( unparsedPlayers, selectedPlayer );
			continue;
		}
		
		return selectedPlayer;
	}
}

getMapName()
{
	if ( !isDefined(level.mapName) )
		level.mapName = GetDvar( "mapname" );
	
	return level.mapName;
}

//This is a list of weapons that show accuracy and do not show hits.
isSingleHitWeapon( weaponName )
{
	switch( weaponName )
	{
		case "iw6_mk32_mp":
		case "iw6_rgm_mp":
		case "iw6_panzerfaust3_mp":
		case "iw6_maaws_mp":
			return true;
		default:
			return false;
	}
}

/*
=============
///ScriptDocBegin
"Name: gameHasNeutralCrateOwner( <gameType> )"
"Summary: Find out if a certain game mode have crates that shouldn't be owned by any player"
"Module: Utility"
"MandatoryArg: <gameType>: The game type to check "
"Example: if(gameHasNeutralCrateOwner( level.gameType )"
"SPMP: Multiplayer"
///ScriptDocEnd
=============
*/

gameHasNeutralCrateOwner( gameType )
{
	switch( gameType )
	{
		case "sotf":
		case "sotf_ffa":
			return true;
		default:
			return false;
	}
}

/*
=============
///ScriptDocBegin
"Name: array_remove_keep_index( <ents> , <remover> )"
"Summary: Returns < ents > array minus < remover >.  Use this in the case where you want to keep the index if it's not a numeric value. "
"Module: Array"
"CallOn: "
"MandatoryArg: <ents> : array to remove < remover > from"
"MandatoryArg: <remover> : entity to remove from the array"
"Example: ents = array_remove_keep_index( ents, guy );"
"SPMP: MP"
///ScriptDocEnd
=============
*/
array_remove_keep_index( ents, remover )
{
	newents = [];
	foreach( index, ent in ents )
	{
		if ( ent != remover )
			newents[ index ] = ent;
	}

	return newents;
}


/*
=============
///ScriptDocBegin
"Name: isAnyMLGMatch()"
"Summary: Check to see if we are currently in any mode, with MLG rules enabled."
"Module: Utility"
"Example: if ( isMLGMatch() )"
"SPMP: MP"
///ScriptDocEnd
=============
*/
isAnyMLGMatch()
{
	if ( GetDvarInt( "xblive_competitionmatch" ) )
		return true;
	
	return false;
}

/*
=============
///ScriptDocBegin
"Name: isMLGSystemLink()"
"Summary: Check to see if we are currently in system link, with MLG rules enabled."
"Module: Utility"
"Example: if ( isMLGSystemLink() )"
"SPMP: MP"
///ScriptDocEnd
=============
*/
isMLGSystemLink()
{
	if ( ( GetDvarInt( "systemlink" ) && GetDvarInt( "xblive_competitionmatch" ) ) )
		return true;
	
	return false;
}

/*
=============
///ScriptDocBegin
"Name: isMLGPrivateMatch()"
"Summary: Check to see if we are currently in private match, with MLG rules enabled."
"Module: Utility"
"Example: if ( isMLGPrivateMatch() )"
"SPMP: MP"
///ScriptDocEnd
=============
*/
isMLGPrivateMatch()
{
	if ( ( privateMatch() && GetDvarInt( "xblive_competitionmatch" ) ) )
		return true;
	
	return false;
}

/*
=============
///ScriptDocBegin
"Name: isMLGMatch()"
"Summary: Check to see if we are currently in private match or system link, with MLG rules enabled."
"Module: Utility"
"Example: if ( isMLGMatch() )"
"SPMP: MP"
///ScriptDocEnd
=============
*/
isMLGMatch()
{
	if ( isMLGSystemLink() || isMLGPrivateMatch() )
		return true;
	
	return false;
}

/*
=============
///ScriptDocBegin
"Name: isModdedRoundGame()"
"Summary: Check to see if the mode is a round based, but based off of the teamscores instead of rounds won. 
"Module: Utility"
"Example: if ( isModdedRoundGame() )"
"SPMP: MP"
///ScriptDocEnd
=============
*/
isModdedRoundGame()
{
	if (level.gameType == "blitz" || level.gameType == "dom" )
		return true;
	
	return false;
}


/*
=============
///ScriptDocBegin
"Name: isUsingDefaultClass( <team> , <slot> )"
"Summary: See if the current game is using any active default classes"
"Module: Utility"
"MandatoryArg: <team>: The team to check (allies/axis) "
"OptionalArg: <index>: The loadout index to check; leave empty to see if any are active"
"Example: if ( isUsingDefaultClass( "allies", 0 ) )"
"SPMP: MP"
///ScriptDocEnd
=============
*/

isUsingDefaultClass( team, index )
{
	usingDefaultClass = false;
	
	if ( IsDefined( index ) )
	{
		if ( isUsingMatchRulesData() && GetMatchRulesData( "defaultClasses", team, index, "class", "inUse" ) )
			usingDefaultClass = true;
	}
	else
	{
		for ( index = 0; index < MAX_CUSTOM_DEFAULT_LOADOUTS; index++ )
		{
			if ( isUsingMatchRulesData() && GetMatchRulesData( "defaultClasses", team, index, "class", "inUse" ) )
			{
				usingDefaultClass = true;
				break;
			}
		}
	}
	
	return usingDefaultClass;
}

/*
=============
///ScriptDocBegin
"Name: canCustomJuggUseKillstreak( <streakNameWeapon> )"
"Summary: See if the custom juggernaut can use the specified killstreak."
"Module: Utility"
"MandatoryArg: <streakNameWeapon>: The killstreak weapon to check "
"Example: if ( canCustomJuggUseKillstreak( streakNameWeapon ) )"
"SPMP: MP"
///ScriptDocEnd
=============
*/

canCustomJuggUseKillstreak( streakNameWeapon )
{
	useKillstreak = true;
			
	if ( ( IsDefined( self.isJuggernautLevelCustom ) && self.isJuggernautLevelCustom ) && 
	     ( IsDefined( self.canUseKillstreakCallback ) && !self [[ self.canUseKillstreakCallback ]]( streakNameWeapon ) ) )
		useKillstreak = false;
	
	return useKillstreak;
}

/*
=============
///ScriptDocBegin
"Name: printCustomJuggKillstreakErrorMsg()"
"Summary: Print the custom error message that players will see if they can't use a killstreak while using a Custom Juggernaut."
"Module: Utility"
"Example: printCustomJuggKillstreakErrorMsg()"
"SPMP: MP"
///ScriptDocEnd
=============
*/

printCustomJuggKillstreakErrorMsg()
{
	if ( IsDefined( self.killstreakErrorMsg ) )
	    [[ self.killstreakErrorMsg ]]();
}
