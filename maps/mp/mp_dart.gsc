#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_dart_precache::main();
	maps\createart\mp_dart_art::main();
	maps\mp\mp_dart_fx::main();
	
	level thread maps\mp\mp_dart_events::breach();
	level thread maps\mp\mp_dart_events::gas_station();
	//level thread maps\mp\mp_dart_events::ceiling_rubble();
	thread maps\mp\mp_dart_scriptlights::main();
	
	level.introVisionSet = "mpIntro_dart";
	
	maps\mp\_load::main();
	thread maps\mp\_fx::func_glass_handler(); // Text on glass
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_dart" );
	
	if ( level.ps3 )
	{
		setdvar( "sm_sunShadowScale", "0.6" ); // ps3 optimization
	}
	else if ( level.xenon )
	{
		setdvar( "sm_sunShadowScale", "0.7" );
	}

	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );

	setdvar_cg_ng( "r_specularColorScale", 1.5, 10 );	
  	setdvar_cg_ng( "r_diffuseColorScale", 1.48, 1.7325 );
	SetDvar( "r_ssaofadedepth", 1089 ); 
	SetDvar( "r_ssaorejectdepth", 1200 );	
  	
  	//setdvar( "r_specularColorScale", 19.45 );  // old
	//setdvar( "r_diffuseColorScale", 1.7325 );  // old
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";

	level thread maps\mp\mp_dart_events::broken_walls();
	level thread maps\mp\mp_dart_events::player_connect_watch();
	level thread maps\mp\mp_dart_events::container_pathnode_watch();
	level thread initExtraCollision();
}


initExtraCollision()
{
	collision1 = GetEnt( "clip128x128x8", "targetname" );
	collision1Ent = spawn( "script_model", (468, -776, 212) );
	collision1Ent.angles = ( 0, 0, -90);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
}