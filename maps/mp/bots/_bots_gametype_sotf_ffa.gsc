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
	maps\mp\bots\_bots_gametype_sotf::setup_callbacks();
	maps\mp\bots\_bots_gametype_sotf::setup_bot_sotf();
}

