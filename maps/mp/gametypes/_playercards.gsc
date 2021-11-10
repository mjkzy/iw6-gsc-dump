#include common_scripts\utility;
#include maps\mp\_utility;


init()
{	
	level thread onPlayerConnect();
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		//@NOTE: Should we make sure they're really unlocked before setting them? Catch cheaters...
		//			e.g. isItemUnlocked( iconHandle )

		
		if ( !IsAI( player ) )
		{
			player.playerCardPatch = player GetCaCPlayerData( "patch" );
			player.playerCardPatchBacking = player GetCaCPlayerData( "patchbacking" );
			player.playerCardBackground = player GetCaCPlayerData( "background" );
		}
	}
}