#include common_scripts\utility;

#using_animtree( "animated_props" );
main()
{
	if( !isdefined ( level.anim_prop_models ) )
		level.anim_prop_models = [];
		
	model = "clothes_line_sweater_iw6";
	if ( isSP() )
		level.anim_prop_models[ model ][ "wind_medium" ] = %hanging_clothes_long_sleeve_wind_medium;
	else
		level.anim_prop_models[ model ][ "wind_medium" ] = "hanging_clothes_long_sleeve_wind_medium";
}
