#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// -.-.-.-.-.-.-.-.-.-. //
// Outline Init
// -.-.-.-.-.-.-.-.-.-. //

init()
{
	level.outlineIDs = 0;
	level.outlineEnts = [];
	
	level thread outlineCatchPlayerDisconnect(); 
	level thread outlineOnPlayerJoinedTeam();
}

// -.-.-.-.-.-.-.-.-.-. //
// Outline Private Logic
// -.-.-.-.-.-.-.-.-.-. //

// teamVisibleTo is optional and should only be added if the type is "TEAM"
//	- this parameter is needed because an empty playersVisibleTo array could be passed to this
//		function if no team members exist at the time of the call. In that case the team
//		could not be grabbed from a playersVisibleTo entry
outlineEnableInternal( entToOutline, colorIndex, playersVisibleTo, depthEnable, priorityNum, type, teamVisibleTo )
{
	AssertEx( type != "TEAM" || IsDefined( teamVisibleTo ), "outlineEnableInternal() passed type \"TEAM\" without teamVisibleTo being defined." );
	
	if ( !IsDefined( entToOutline.outlines ) )
	{
		entToOutline.outlines = [];
	}
	
	oInfo				   = SpawnStruct();
	oInfo.priority		   = priorityNum;
	oInfo.colorIndex	   = colorIndex;
	oInfo.playersVisibleTo = playersVisibleTo;
	oInfo.depthEnable	   = depthEnable;
	oInfo.type			   = type;
	
	if ( type == "TEAM" )
	{
		oInfo.team = teamVisibleTo;
	}
	
	ID = outlineGenerateUniqueID();
	entToOutline.outlines[ ID ] = oInfo;
	
	outlineAddToGlobalList( entToOutline );
	
	playersToSeeOutline = [];
	
	foreach ( player in oInfo.playersVisibleTo )
	{
		oInfoHighest = outlineGetHighestInfoForPlayer( entToOutline, player );
		
		// If the new outline priority is the same as the highest priority
		// apply the new outline because it is the most recent
		if ( !IsDefined( oInfoHighest ) || oInfoHighest == oInfo || oInfoHighest.priority == oInfo.priority )
		{
			playersToSeeOutline[ playersToSeeOutline.size ] = player;
		}
	}
	
	if ( playersToSeeOutline.size > 0 )
	{
		entToOutline HudOutlineEnableForClients( playersToSeeOutline, oInfo.colorIndex, oInfo.depthEnable );
	}
	
	return ID;
}

outlineDisableInternal( ID, entOutlined )
{
	if ( !IsDefined( entOutlined.outlines ) )
	{
		outlineRemoveFromGlobalList( entOutlined );
		return;
	}
	else if ( !IsDefined( entOutlined.outlines[ ID ] ) )
	{
		return;
	}
	
	oInfoToDisable = entOutlined.outlines[ ID ];

	// Remove outline info from array, preserve array keys (IDs)
	outlinesUpdated = [];
	foreach ( key, oInfo in entOutlined.outlines )
	{
		if ( oInfo != oInfoToDisable )
		{
			outlinesUpdated[ key ] = oInfo;
		}
	}
	
	if ( outlinesUpdated.size == 0 )
	{
		outlineRemoveFromGlobalList( entOutlined );
	}
	
	// Make sure the entOutlined is not removed
	if ( IsDefined( entOutlined ) )
	{
		entOutlined.outlines = outlinesUpdated;
		
		foreach ( player in oInfoToDisable.playersVisibleTo )
		{
			// Make sure the player isn't removed
			if ( !IsDefined( player ) )
				continue;
			
			oInfoHighest = outlineGetHighestInfoForPlayer( entOutlined, player );
			
			if ( IsDefined( oInfoHighest ) )
			{
				// Outlined entities can have multiple outlines of the same
				// priority so unless an outline is found with a higher priority
				// a new outline call should be made to make sure an outline exists
				// for this player. Otherwise assume the highest outline is already
				// applied.
				if ( oInfoHighest.priority <= oInfoToDisable.priority )
				{
					entOutlined HudOutlineEnableForClient( player, oInfoHighest.colorIndex, oInfoHighest.depthEnable );
				}
			}
			else
			{
				entOutlined HudOutlineDisableForClient( player );
			}
		}
	}
}

outlineCatchPlayerDisconnect()
{
	while ( true )
	{
		// Assumes two players cannot connect on the same frame
		level waittill( "connected", player );
		
		level thread outlineOnPlayerDisconnect( player );
	}
}

outlineOnPlayerDisconnect( player )
{
	level endon( "game_ended" );
	
	player waittill( "disconnect" );
	
	// Intentionally call these even if the player is removed
	// at this point so arrays can be scrubbed
	outlineRemovePlayerFromVisibleToArrays( player );
	outlineDisableInternalAll( player );
}

outlineOnPlayerJoinedTeam()
{
	while ( true )
	{
		// Assumes two players cannot join a team on the same frame
		level waittill( "joined_team", player );
		
		if ( !IsDefined( player.team ) || player.team == "spectator" )
			continue;

		// After joined_team is notified the player could still be picking 
		// a class while seeing in 3rd person. Wait until spawn to actually
		// adjust team outlines
		thread outlineOnPlayerJoinedTeam_onFirstSpawn( player );
	}
}

outlineOnPlayerJoinedTeam_onFirstSpawn( player )
{
	// Players can change teams and then change team again
	// without entering the game. End this thread if another
	// change team notify happens before spawned_player
	player notify( "outlineOnPlayerJoinedTeam_onFirstSpawn" );
	player endon( "outlineOnPlayerJoinedTeam_onFirstSpawn" );
	player endon( "disconnect" );
	
	player waittill( "spawned_player" );
	
	outlineRemovePlayerFromVisibleToArrays( player );
	
	outlineDisableInternalAll( player );
	
	outlineAddPlayerToExistingTeamOutlines( player );
}

outlineRemovePlayerFromVisibleToArrays( player )
{
	level.outlineEnts = array_removeUndefined( level.outlineEnts );
	
	foreach ( entOutlined in level.outlineEnts )
	{
		outlinedForPlayer = false;
		
		foreach ( oInfo in entOutlined.outlines )
		{
			// Scrub outline array in case of undefined player references
			oInfo.playersVisibleTo = array_removeUndefined( oInfo.playersVisibleTo );
			
			if ( IsDefined( player ) && array_contains( oInfo.playersVisibleTo, player ) )
			{
				oInfo.playersVisibleTo = array_remove( oInfo.playersVisibleTo, player );
				outlinedForPlayer = true;
			}
		}
		
		if ( outlinedForPlayer && IsDefined( entOutlined ) && IsDefined( player ) )
		{
			entOutlined HudOutlineDisableForClient( player );
		}
	}
}

outlineAddPlayerToExistingTeamOutlines( player )
{
	// Traverse outlined entities and add the player to any existing team outline calls
	foreach ( entOutlined in level.outlineEnts )
	{
		// Outlined ents may be removed entities
		if ( !IsDefined( entOutlined ) )
			continue;
		
		oInfoHighest = undefined;
		
		foreach ( oInfo in entOutlined.outlines )
		{
			if ( ( oInfo.Type == "ALL" ) || ( oInfo.type == "TEAM" && oInfo.team == player.team ) )
			{
				if ( !array_contains( oInfo.playersVisibleTo, player ) )
				{
					oInfo.playersVisibleTo[ oInfo.playersVisibleTo.size ] = player;
				}
				else
				{
					AssertMsg( "Found a team outline call on a player's new team that already had a reference to him. This should never happen. Are we letting a player change teams to his own team?" );
				}
				
				if ( !IsDefined( oInfoHighest ) || oInfo.priority > oInfoHighest.priority )
				{
					oInfoHighest = oInfo;
				}
			}
		}
		
		if ( IsDefined( oInfoHighest ) )
		{
			entOutlined HudOutlineEnableForClient( player, oInfoHighest.colorIndex, oInfoHighest.depthEnable );
		}
	}
}

outlineDisableInternalAll( entOutlined )
{
	if ( !IsDefined( entOutlined ) || !IsDefined( entOutlined.outlines ) || entOutlined.outlines.size == 0 )
		return;
	
	foreach ( ID, _ in entOutlined.outlines )
	{
		outlineDisableInternal( ID, entOutlined );
	}
}

outlineAddToGlobalList( entOutlined )
{
	if ( !array_contains( level.outlineEnts, entOutlined ) )
	{
		level.outlineEnts[ level.outlineEnts.size ] = entOutlined;
	}
}

outlineRemoveFromGlobalList( entOutlined )
{
	level.outlineEnts = array_remove( level.outlineEnts, entOutlined );
}

outlineGetHighestPriorityID( entOutlined )
{
	result = -1;
	
	if ( !IsDefined( entOutlined.outlines ) || entOutlined.size == 0 )
		return result;
	
	oInfoHighest = undefined;
	
	foreach ( ID, oInfo in entOutlined.outlines )
	{
		if ( !IsDefined( oInfoHighest ) || oInfo.priority > oInfoHighest.priority )
		{
			oInfoHighest = oInfo;
			result = ID;
		}
	}
	
	return result;
}

outlineGetHighestInfoForPlayer( entOutlined, player )
{
	oInfoHighest = undefined;
	
	if ( IsDefined( entOutlined.outlines ) && entOutlined.outlines.size )
	{
		foreach ( ID, oInfo in entOutlined.outlines )
		{
			if ( array_contains( oInfo.playersVisibleTo, player ) && ( !IsDefined( oInfoHighest ) || oInfo.priority > oInfoHighest.priority ) )
			{
				oInfoHighest = oInfo;
			}
		}
	}
	
	return oInfoHighest;
}

outlineGenerateUniqueID()
{
	AssertEx( IsDefined( level.outlineIDs ), "Outline enable called on entity before _outline::init() function has been called." );
	
	level.outlineIDs++;
	
	return level.outlineIDs;
}

outlinePriorityGroupMap( priorityGroup )
{
	priorityGroup = ToLower( priorityGroup );
	
	priority = undefined;
	
	switch ( priorityGroup )
	{
		case "level_script":
			priority = 0;
			break;
		case "equipment":
			priority = 1;
			break;
		case "perk":
			priority = 2;
			break;
		case "killstreak": // Killstreaks that are shared.
			priority = 3;
			break;
		case "killstreak_personal": // Killstreaks like Odin or the Predator that should always trump things like the skylark which is a shared outline
			priority = 4;
			break;
		default:
			AssertMsg( "Invalid priority group passed to outlinePriorityGroupMap(): " + priorityGroup );
			priority = 0;
			break;
	}
	
	return priority;
}

outlineColorIndexMap( colorName )
{
	colorName = ToLower( colorName );
	
	idx = undefined;
	
	switch ( colorName )
	{
		case "white":
			idx = 0;
			break;
		case "red":
			idx = 1;
			break;
		case "green":
			idx = 2;
			break;
		case "cyan":
			idx = 3;
			break;
		case "orange":
			idx = 4;
			break;
		case "yellow":
			idx = 5;
			break;
		case "blue":
			idx = 6;
			break;
		default:
			AssertMsg( "Invalid color name passed to outlineColorIndexMap(): " + colorName );
			idx = 0;
			break;
	}
	
	return idx;
}
