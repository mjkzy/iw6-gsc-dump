#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;

//=======================================================
//						main
//=======================================================
main()
{
	// By default, they will use TDM callback/think

	// Limit personality types to just the active ones.
	level.bot_personality_types_desired["active"] = 1;
	level.bot_personality_types_desired["stationary"] = 0;
}